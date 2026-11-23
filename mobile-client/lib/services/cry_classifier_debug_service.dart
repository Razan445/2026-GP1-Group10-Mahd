
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'cry_classifier_service.dart';
import 'mahd_notification_service.dart';

/// Debug-only integration test using real microphone audio and the real ONNX
/// classifier. This is NOT Cry Detection and must not create confirmed cry
/// events in Firestore.
class CryClassifierDebugService {
  CryClassifierDebugService._();

  static final CryClassifierDebugService instance =
      CryClassifierDebugService._();

  static const int _windowSamples = 32000;

  // Debug-only threshold. Do not treat this as Cry Detection.
  static const double _minimumRms = 0.005;

  static const Duration _notificationCooldown =
      Duration(seconds: 10);

  CryClassifierService? _classifier;
  StreamSubscription<Uint8List>? _audioSubscription;
  Future<void>? _pendingInference;

  final Float32List _sampleBuffer = Float32List(_windowSamples);

  bool _active = false;
  bool _processing = false;
  int _generation = 0;
  int _sampleCount = 0;
  int? _pendingLowByte;
  DateTime? _lastNotificationAt;

  Future<void> start(Stream<Uint8List> stream) async {
    if (!kDebugMode || _active) return;

    _active = true;
    final generation = ++_generation;
    final classifier = CryClassifierService();

    try {
      debugPrint('MAHD DEBUG: Loading ONNX cry classifier...');

      await classifier.init();

      if (!_active || generation != _generation) {
        classifier.dispose();
        return;
      }

      _classifier = classifier;

      _audioSubscription = stream.listen(
        (chunk) => _processAudioChunk(chunk, generation),
        onError: (Object error) {
          debugPrint('MAHD DEBUG: Microphone stream error: $error');
        },
        onDone: () {
          debugPrint('MAHD DEBUG: Microphone stream completed');
        },
      );

      debugPrint(
        'MAHD DEBUG: Classifier ready. Play a baby audio recording.',
      );
    } catch (error) {
      debugPrint('MAHD DEBUG: Classifier initialization failed: $error');

      try {
        classifier.dispose();
      } catch (disposeError) {
        debugPrint('MAHD DEBUG: Classifier cleanup: $disposeError');
      }

      if (generation == _generation) {
        _active = false;
        _classifier = null;
      }
    }
  }

  void _processAudioChunk(Uint8List chunk, int generation) {
    if (!_active || generation != _generation) return;

    for (final byte in chunk) {
      if (_pendingLowByte == null) {
        _pendingLowByte = byte;
        continue;
      }

      // PCM16 little-endian, signed integer samples.
      var sample = _pendingLowByte! | (byte << 8);
      _pendingLowByte = null;

      if (sample >= 0x8000) {
        sample -= 0x10000;
      }

      _sampleBuffer[_sampleCount] = sample / 32768.0;
      _sampleCount++;

      if (_sampleCount == _windowSamples) {
        _sampleCount = 0;

        // Skip this window only while a previous inference is running.
        if (_processing) continue;

        // Always classify eligible windows. Notification cooldown must
        // not prevent the ONNX model from processing new audio.
        final window = Float32List.fromList(_sampleBuffer);

        _processing = true;

        _pendingInference = _classifyWindow(
          window,
          generation,
        ).whenComplete(() {
          _processing = false;
          _pendingInference = null;
        });
      }
    }
  }

  Future<void> _classifyWindow(
    Float32List window,
    int generation,
  ) async {
    try {
      double sumSquares = 0;

      for (final sample in window) {
        sumSquares += sample * sample;
      }

      final rms = math.sqrt(sumSquares / window.length);

      debugPrint(
        'MAHD DEBUG: Audio window RMS=${rms.toStringAsFixed(6)}',
      );

      // Ignore near-silent audio during this notification test.
      // This is not a real cry/non-cry detector.
      if (rms < _minimumRms) {
        debugPrint(
          'MAHD DEBUG: Skipped quiet audio (RMS=$rms)',
        );
        return;
      }

      final classifier = _classifier;

      if (classifier == null) return;

      final probabilities = await classifier.predict(window);

      if (!_active || generation != _generation) return;

      if (probabilities.isEmpty) {
        debugPrint('MAHD DEBUG: Empty classifier output');
        return;
      }

      MapEntry<String, double>? best;

      for (final entry in probabilities.entries) {
        if (!entry.value.isFinite ||
            entry.value < 0 ||
            entry.value > 1) {
          continue;
        }

        if (best == null || entry.value > best.value) {
          best = entry;
        }
      }

      if (best == null) {
        debugPrint('MAHD DEBUG: Invalid classifier probabilities');
        return;
      }

      final cause = best.key;
      final confidence = best.value;

      debugPrint(
        'MAHD DEBUG: Classification=$cause '
        'Confidence=${(confidence * 100).toStringAsFixed(1)}%',
      );

      // The cooldown applies only to notifications, not classification.
      final now = DateTime.now();

      if (_lastNotificationAt != null &&
          now.difference(_lastNotificationAt!) <
              _notificationCooldown) {
        debugPrint(
          'MAHD DEBUG: Classification completed; '
          'notification skipped (cooldown).',
        );
        return;
      }

      _lastNotificationAt = now;

      // Test the existing Mahd notification coordinator.
      // This does not call MonitoringService.saveCryData(), because
      // Cry Detection has not confirmed that the sound is crying.
      await MahdNotificationService.instance
          .showClassifierDebugTestLocal(
        cause: cause,
        confidence: confidence,
      );
    } catch (error) {
      debugPrint('MAHD DEBUG: Classifier inference failed: $error');
    }
  }

  Future<void> stop() async {
    _active = false;
    ++_generation;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    final pending = _pendingInference;

    if (pending != null) {
      try {
        await pending;
      } catch (error) {
        debugPrint('MAHD DEBUG: Pending inference: $error');
      }
    }

    _pendingInference = null;

    try {
      _classifier?.dispose();
    } catch (error) {
      debugPrint('MAHD DEBUG: Classifier dispose: $error');
    }

    _classifier = null;
    _processing = false;
    _sampleCount = 0;
    _pendingLowByte = null;
    _lastNotificationAt = null;
  }
}
