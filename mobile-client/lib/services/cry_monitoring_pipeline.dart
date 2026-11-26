import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'cry_cause_classifier.dart';
import 'cry_classifier_service.dart';
import 'cry_detection_service.dart';
import 'cry_pipeline_logic.dart';
import 'monitoring_service.dart';

/// Production Two-Stage Cry Monitoring Pipeline:
///
/// [0] Continuous 16 kHz mono PCM16 capture -> 1-second raw float32 chunks in
///     an in-memory Ring Buffer (NO peak normalization before Stage 1).
/// [1-2] Stage 1: On-device CRNN Cry Detection (`mahd_cry_detection_crnn.onnx`)
///       evaluating the current second + 4 previous seconds.
/// [3] Smoothing & Episode Confirmation: requires `alertSeconds` (2)
///     consecutive cry seconds above threshold to reject transient sounds.
/// [4] Episode Audio Collection (2–6 s from RAM Ring Buffer) + Policy P0
///     (-70 dB silence trim + 1–3 windows of 2.0 s with zero-padding).
/// [5] Stage 2: Cry Cause Classification via [CryCauseClassifier]
///     (currently DistilHuBERT; swap in Lightweight 2D-CNN in one place later).
/// [6] Soft Voting + 3-Tier Confidence Gate (70% threshold).
/// [7] Single local notification + structured Firestore record (no audio) +
///     episode-aware cooldown + immediate RAM wipe of episode audio.
class CryMonitoringPipeline {
  CryMonitoringPipeline._({
    CryCauseClassifier Function()? classifierFactory,
  }) : _classifierFactory =
            classifierFactory ?? (() => CryClassifierService());

  static final CryMonitoringPipeline instance = CryMonitoringPipeline._();

  /// Swap this factory when the Lightweight 2D-CNN classifier is ready.
  final CryCauseClassifier Function() _classifierFactory;

  static const int _sampleRate = 16000;
  static const int _ringBufferSeconds = 6;
  static const int _maxEpisodeSeconds = 6;
  static const int _maxQueuedSeconds = 2;
  static const Duration _episodeCooldown = Duration(seconds: 30);

  CryDetectionService? _detector;
  CryCauseClassifier? _classifier;
  StreamSubscription<Uint8List>? _audioSubscription;

  final Float32List _currentSecondBuffer = Float32List(_sampleRate);
  int _sampleCount = 0;
  int? _pendingLowByte;

  /// RAM-only rolling buffer of recent raw 1-second windows (oldest -> newest).
  final ListQueue<Float32List> _ringBuffer = ListQueue<Float32List>();

  /// Queue of completed 1-second windows awaiting sequential Stage 1 inference.
  final ListQueue<Float32List> _pendingSeconds = ListQueue<Float32List>();
  Future<void>? _workerFuture;

  /// Episode collection state.
  bool _collectingEpisode = false;
  DateTime? _episodeDetectedAt;
  final List<Float32List> _episodeBuffers = <Float32List>[];

  /// Cooldown & same-episode suppression.
  DateTime? _cooldownUntil;
  bool _waitingForEpisodeEnd = false;

  bool _active = false;
  int _generation = 0;

  bool get isActive => _active;

  Future<void> start(Stream<Uint8List> pcm16Stream) async {
    if (_active) return;

    _active = true;
    final generation = ++_generation;

    final detector = CryDetectionService();
    if (!detector.isSupported) {
      debugPrint(
        'MAHD PIPELINE: Native ONNX inference unavailable on this platform.',
      );
      _active = false;
      return;
    }

    final classifier = _classifierFactory();

    try {
      debugPrint('MAHD PIPELINE: Initializing Stage 1 (CRNN) & Stage 2...');

      await detector.init();
      await classifier.init();

      if (!_active || generation != _generation) {
        detector.dispose();
        classifier.dispose();
        return;
      }

      _detector = detector;
      _classifier = classifier;

      _resetBuffers();

      _audioSubscription = pcm16Stream.listen(
        (chunk) => _onAudioChunk(chunk, generation),
        onError: (Object error) {
          debugPrint('MAHD PIPELINE: Microphone stream error: $error');
        },
        onDone: () {
          debugPrint('MAHD PIPELINE: Microphone stream completed.');
        },
      );

      debugPrint(
        'MAHD PIPELINE: Ready '
        '(threshold=${detector.threshold.toStringAsFixed(3)}, '
        'alertSeconds=${detector.alertSeconds}).',
      );
    } catch (error, stackTrace) {
      debugPrint('MAHD PIPELINE: Initialization failed: $error');
      debugPrint('$stackTrace');

      try {
        detector.dispose();
      } catch (_) {}
      try {
        classifier.dispose();
      } catch (_) {}

      if (generation == _generation) {
        _detector = null;
        _classifier = null;
        _active = false;
      }
    }
  }

  void _onAudioChunk(Uint8List chunk, int generation) {
    if (!_active || generation != _generation) return;

    for (final byte in chunk) {
      if (_pendingLowByte == null) {
        _pendingLowByte = byte;
        continue;
      }

      // Signed 16-bit little-endian PCM -> raw float32 in [-1, 1].
      // IMPORTANT: Do NOT peak-normalize here; CRNN uses real RMS loudness.
      var sample = _pendingLowByte! | (byte << 8);
      _pendingLowByte = null;

      if (sample >= 0x8000) {
        sample -= 0x10000;
      }

      _currentSecondBuffer[_sampleCount] = sample / 32768.0;
      _sampleCount++;

      if (_sampleCount == _sampleRate) {
        _sampleCount = 0;
        final completedSecond = Float32List.fromList(_currentSecondBuffer);

        // Keep queue bounded so inference never falls behind real time.
        while (_pendingSeconds.length >= _maxQueuedSeconds) {
          _pendingSeconds.removeFirst();
        }
        _pendingSeconds.addLast(completedSecond);

        _workerFuture ??= _drainQueue(generation).whenComplete(() {
          _workerFuture = null;
          if (_active &&
              generation == _generation &&
              _pendingSeconds.isNotEmpty) {
            _workerFuture = _drainQueue(generation);
          }
        });
      }
    }
  }

  Future<void> _drainQueue(int generation) async {
    while (_active &&
        generation == _generation &&
        _pendingSeconds.isNotEmpty) {
      final secondAudio = _pendingSeconds.removeFirst();
      await _processOneSecond(secondAudio, generation);
    }
  }

  Future<void> _processOneSecond(
    Float32List rawSecond,
    int generation,
  ) async {
    final detector = _detector;
    if (detector == null || !_active || generation != _generation) return;

    // Update RAM-only Ring Buffer.
    _ringBuffer.addLast(rawSecond);
    while (_ringBuffer.length > _ringBufferSeconds) {
      _ringBuffer.removeFirst();
    }

    CryDetectionStepResult detection;
    try {
      detection = await detector.step(rawSecond);
    } catch (error) {
      debugPrint('MAHD PIPELINE: Stage 1 inference error: $error');
      return;
    }

    if (!_active || generation != _generation) return;

    if (kDebugMode) {
      debugPrint(
        'MAHD STAGE 1: score=${detection.score.toStringAsFixed(3)} '
        '(thr=${detection.threshold.toStringAsFixed(3)}) '
        'cry=${detection.isCry} run=${detection.consecutiveCrySeconds}',
      );
    }

    // Release episode lock once the baby stops crying.
    if (_waitingForEpisodeEnd && !detection.isCry) {
      _waitingForEpisodeEnd = false;
    }

    if (_collectingEpisode) {
      if (detection.isCry) {
        _episodeBuffers.add(rawSecond);
      }

      final reachedMaxDuration =
          _episodeBuffers.length >= _maxEpisodeSeconds;
      final cryStoppedEarly = !detection.isCry;

      if (reachedMaxDuration || cryStoppedEarly) {
        final collected = List<Float32List>.from(_episodeBuffers);
        final detectedAt = _episodeDetectedAt ?? DateTime.now();

        _collectingEpisode = false;
        _episodeDetectedAt = null;
        _episodeBuffers.clear();

        // Prevent duplicate alerts while this same crying episode continues.
        _cooldownUntil = DateTime.now().add(_episodeCooldown);
        _waitingForEpisodeEnd = detection.isCry;

        await _classifyAndPersistEpisode(
          collected,
          detectedAt: detectedAt,
          generation: generation,
        );
      }
      return;
    }

    // Not currently collecting an episode: check Stage 1 confirmation.
    final now = DateTime.now();
    final inCooldown =
        _cooldownUntil != null && now.isBefore(_cooldownUntil!);

    if (detection.episodeStarted && !inCooldown && !_waitingForEpisodeEnd) {
      _collectingEpisode = true;
      _episodeDetectedAt = now;
      _episodeBuffers.clear();

      // Seed episode with the confirmed cry seconds already in the ring buffer.
      final seedCount = detector.alertSeconds.clamp(1, _ringBuffer.length);
      final ringList = _ringBuffer.toList(growable: false);
      final startIdx = ringList.length - seedCount;
      for (int i = startIdx; i < ringList.length; i++) {
        _episodeBuffers.add(ringList[i]);
      }

      if (kDebugMode) {
        debugPrint(
          'MAHD PIPELINE: Cry episode confirmed! '
          'Collecting up to $_maxEpisodeSeconds s before Stage 2...',
        );
      }
    }
  }

  Future<void> _classifyAndPersistEpisode(
    List<Float32List> episodeSeconds, {
    required DateTime detectedAt,
    required int generation,
  }) async {
    final classifier = _classifier;
    if (classifier == null || !_active || generation != _generation) return;

    try {
      // [4] Policy P0: Merge episode audio, trim -70 dB silence, split into
      // 1–3 windows of 2.0 s (zero-padding if < 2.0 s).
      final merged = concatAudioBuffers(episodeSeconds);
      final trimmed = trimSilencePolicyP0(merged);
      final windows = segmentIntoWindowsP0(
        trimmed.isNotEmpty ? trimmed : merged,
        windowSamples: classifier.windowSamples,
        maxWindows: 3,
      );

      // [5] Stage 2: Run Cry Cause Classification on each 2.0 s window.
      final allProbs = <Map<String, double>>[];
      for (final window in windows) {
        if (!_active || generation != _generation) return;
        final probs = await classifier.predict(window);
        if (probs.isNotEmpty) {
          allProbs.add(probs);
        }
      }

      if (!_active || generation != _generation) return;

      // [6] Soft Voting + 3-Tier Confidence Gate (70% threshold).
      final decision = applySoftVotingAndConfidenceGate(allProbs);

      debugPrint(
        'MAHD STAGE 2: tier=${decision.tierName} '
        'primary=${decision.primaryCause} '
        '(${(decision.primaryConfidence * 100).toStringAsFixed(1)}%) '
        'secondary=${decision.secondaryCause ?? '-'} '
        'windows=${decision.windowCount}',
      );

      // [7] Send single local notification + save structured Firestore record.
      await MonitoringService.instance.saveCryData(
        cause: decision.primaryCause,
        confidence: decision.primaryConfidence,
        detectedAt: detectedAt,
        secondaryCause: decision.secondaryCause,
        secondaryConfidence: decision.secondaryConfidence,
        notificationBody: decision.formatArabicNotificationBody(),
      );
    } on MonitoringSessionNotActiveException {
      debugPrint(
        'MAHD PIPELINE: Cry episode detected before Firestore session became '
        'active; skipped persistence.',
      );
    } catch (error, stackTrace) {
      debugPrint('MAHD PIPELINE: Stage 2 / persistence error: $error');
      debugPrint('$stackTrace');
    } finally {
      // Privacy: wipe episode audio from RAM immediately after processing.
      episodeSeconds.clear();
    }
  }

  void _resetBuffers() {
    _sampleCount = 0;
    _pendingLowByte = null;
    _ringBuffer.clear();
    _pendingSeconds.clear();
    _collectingEpisode = false;
    _episodeDetectedAt = null;
    _episodeBuffers.clear();
    _cooldownUntil = null;
    _waitingForEpisodeEnd = false;
  }

  Future<void> stop() async {
    _active = false;
    ++_generation;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    final worker = _workerFuture;
    if (worker != null) {
      try {
        await worker;
      } catch (error) {
        debugPrint('MAHD PIPELINE: Pending worker cleanup: $error');
      }
    }
    _workerFuture = null;

    try {
      _detector?.dispose();
    } catch (error) {
      debugPrint('MAHD PIPELINE: Detector dispose: $error');
    }
    _detector = null;

    try {
      _classifier?.dispose();
    } catch (error) {
      debugPrint('MAHD PIPELINE: Classifier dispose: $error');
    }
    _classifier = null;

    _resetBuffers();
  }
}
