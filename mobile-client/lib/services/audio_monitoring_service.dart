
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

import 'cry_monitoring_pipeline.dart';
import 'monitoring_foreground_service.dart';

class AudioMonitoringPermissionException implements Exception {
  const AudioMonitoringPermissionException();
}

enum AudioMonitoringStatus {
  stopped,
  starting,
  active,
  recovering,
  interrupted,
}

class AudioMonitoringService {
  AudioMonitoringService._();

  static final AudioMonitoringService instance =
      AudioMonitoringService._();

  final AudioRecorder _recorder = AudioRecorder();

  StreamController<Uint8List>? _audioController;
  StreamSubscription<Uint8List>? _recorderSubscription;

  Timer? _healthCheckTimer;

  Future<void>? _startFuture;
  Future<void>? _recoveryFuture;

  bool _isMonitoring = false;
  bool _isStopping = false;
  bool _isRecovering = false;

  DateTime? _lastChunkAt;
  DateTime? _allZeroSince;

  int _recoveryAttempts = 0;

  static const Duration _healthCheckInterval = Duration(seconds: 2);
  static const Duration _noChunkTimeout = Duration(seconds: 6);
  static const Duration _allZeroTimeout = Duration(seconds: 8);
  static const int _maxRecoveryAttempts = 3;

  final ValueNotifier<AudioMonitoringStatus> status =
      ValueNotifier(AudioMonitoringStatus.stopped);

  bool get isMonitoring => _isMonitoring;

  /// Audio stream that will be connected to the ML model later.
  Stream<Uint8List>? get audioStream => _audioController?.stream;

  Future<void> startMonitoring() {
    if (_isMonitoring || _isStopping) {
      return Future<void>.value();
    }

    return _startFuture ??= _startMonitoringInternal().whenComplete(() {
      _startFuture = null;
    });
  }

  Future<void> _startMonitoringInternal() async {
    status.value = AudioMonitoringStatus.starting;

    try {
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        throw const AudioMonitoringPermissionException();
      }

      // Start the microphone foreground service while the app is visible.
      // Android requires this before background microphone monitoring.
      await MonitoringForegroundService.instance.start();

      final controller = StreamController<Uint8List>.broadcast();
      _audioController = controller;

      _recoveryAttempts = 0;

      await _startRecorderStream(controller);

      _isMonitoring = true;

      _healthCheckTimer?.cancel();
      _healthCheckTimer = Timer.periodic(
        _healthCheckInterval,
        (_) => _checkAudioHealth(),
      );

      // Start the two-stage on-device Cry Detection (CRNN) -> Cry Cause
      // Classification pipeline in both debug and release builds.
      unawaited(
        CryMonitoringPipeline.instance.start(controller.stream),
      );
    } catch (_) {
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      await _recorderSubscription?.cancel();
      _recorderSubscription = null;

      try {
        await _recorder.stop();
      } catch (_) {
        // The recorder may not have started successfully.
      }

      final controller = _audioController;
      _audioController = null;

      if (controller != null && !controller.isClosed) {
        await controller.close();
      }

      _isMonitoring = false;
      status.value = AudioMonitoringStatus.stopped;

      try {
        await MonitoringForegroundService.instance.stop();
      } catch (error) {
        debugPrint(
          'MAHD FOREGROUND: Cleanup after start failure: $error',
        );
      }

      rethrow;
    }
  }

  Future<void> _startRecorderStream(
    StreamController<Uint8List> controller,
  ) async {
    final recorderStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.mic,
        ),
      ),
    );

    _lastChunkAt = DateTime.now();
    _allZeroSince = null;

    int chunkCount = 0;

    _recorderSubscription = recorderStream.listen(
      (Uint8List chunk) {
        if (_isStopping || controller.isClosed || chunk.isEmpty) {
          return;
        }

        chunkCount++;

        final now = DateTime.now();
        _lastChunkAt = now;

        final containsNonZeroAudio =
            chunk.any((byte) => byte != 0);

        if (containsNonZeroAudio) {
          _allZeroSince = null;
          _recoveryAttempts = 0;

          if (status.value != AudioMonitoringStatus.active) {
            status.value = AudioMonitoringStatus.active;

            if (kDebugMode) {
              debugPrint('MAHD AUDIO: Audio data received.');
            }
          }
        } else {
          _allZeroSince ??= now;
        }

        if (kDebugMode && chunkCount % 20 == 0) {
          final nonZeroBytes =
              chunk.where((byte) => byte != 0).length;

          debugPrint(
            'MAHD MIC RAW: '
            'bytes=${chunk.length}, '
            'nonZero=$nonZeroBytes, '
            'firstBytes=${chunk.take(12).toList()}',
          );
        }

        controller.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('MAHD AUDIO: Recorder stream error: $error');

        if (_isMonitoring && !_isStopping && !_isRecovering) {
          _requestRecovery('Recorder stream error');
        }
      },
      onDone: () {
        if (_isMonitoring && !_isStopping && !_isRecovering) {
          debugPrint('MAHD AUDIO: Recorder stream ended.');
          _requestRecovery('Recorder stream ended');
        }
      },
    );
  }

  void _checkAudioHealth() {
    if (!_isMonitoring || _isStopping || _isRecovering) {
      return;
    }

    final now = DateTime.now();

    final lastChunkAt = _lastChunkAt;

    if (lastChunkAt != null &&
        now.difference(lastChunkAt) >= _noChunkTimeout) {
      _requestRecovery('No audio chunks received');
      return;
    }

    final allZeroSince = _allZeroSince;

    if (allZeroSince != null &&
        now.difference(allZeroSince) >= _allZeroTimeout) {
      _requestRecovery('Continuous zero audio data');
    }
  }

  void _requestRecovery(String reason) {
    if (!_isMonitoring || _isStopping || _isRecovering) {
      return;
    }

    status.value = AudioMonitoringStatus.interrupted;

    if (_recoveryAttempts >= _maxRecoveryAttempts) {
      debugPrint(
        'MAHD AUDIO: Recovery limit reached. '
        'Manual monitoring restart required.',
      );
      return;
    }

    final lifecycleState =
        WidgetsBinding.instance.lifecycleState;

    // On platforms without the Android microphone foreground service,
    // keep the original restriction on restarting from background.
    if (!MonitoringForegroundService.instance.isSupported &&
        lifecycleState != null &&
        lifecycleState != AppLifecycleState.resumed) {
      debugPrint(
        'MAHD AUDIO: Audio interrupted while app is not resumed. '
        'Waiting for foreground before attempting recovery.',
      );
      return;
    }

    _recoveryAttempts++;

    debugPrint(
      'MAHD AUDIO: $reason. '
      'Recovery attempt $_recoveryAttempts/$_maxRecoveryAttempts.',
    );

    _recoveryFuture = _recoverRecorder();
  }

  Future<void> _recoverRecorder() async {
    _isRecovering = true;
    status.value = AudioMonitoringStatus.recovering;

    try {
      // Never attempt background microphone recovery if the
      // required Android foreground service is no longer running.
      if (MonitoringForegroundService.instance.isSupported &&
          !await FlutterForegroundTaskBridge.isServiceRunning()) {
        debugPrint(
          'MAHD AUDIO: Foreground service unavailable. '
          'Microphone recovery cancelled.',
        );
        status.value = AudioMonitoringStatus.interrupted;
        return;
      }

      await _recorderSubscription?.cancel();
      _recorderSubscription = null;

      await _recorder.stop();

      if (_isStopping || !_isMonitoring) {
        return;
      }

      final controller = _audioController;

      if (controller == null || controller.isClosed) {
        status.value = AudioMonitoringStatus.interrupted;
        return;
      }

      await _startRecorderStream(controller);

      debugPrint(
        'MAHD AUDIO: Recorder restarted. '
        'Waiting for valid audio data.',
      );
    } catch (error) {
      debugPrint('MAHD AUDIO: Recovery failed: $error');
      status.value = AudioMonitoringStatus.interrupted;
    } finally {
      _isRecovering = false;
      _recoveryFuture = null;
    }
  }

  Future<void> stopMonitoring() async {
    if (_isStopping) {
      return;
    }

    _isStopping = true;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    try {
      if (_startFuture != null) {
        try {
          await _startFuture;
        } catch (_) {
          // Start failure has already been handled.
        }
      }

      if (_recoveryFuture != null) {
        await _recoveryFuture;
      }

      if (_isMonitoring || _audioController != null) {
        // Stop the two-stage pipeline before closing its microphone stream.
        await CryMonitoringPipeline.instance.stop();

        await _recorderSubscription?.cancel();
        _recorderSubscription = null;

        await _recorder.stop();
      }
    } finally {
      final controller = _audioController;
      _audioController = null;

      if (controller != null && !controller.isClosed) {
        await controller.close();
      }

      _lastChunkAt = null;
      _allZeroSince = null;
      _recoveryAttempts = 0;

      _isMonitoring = false;
      status.value = AudioMonitoringStatus.stopped;

      try {
        await MonitoringForegroundService.instance.stop();
      } finally {
        _isStopping = false;
      }
    }
  }

  Future<void> dispose() async {
    if (_isMonitoring || _startFuture != null) {
      await stopMonitoring();
    }

    await _recorder.dispose();
    status.dispose();
  }
}

// Provides a small bridge for checking the Android foreground-service state.
class FlutterForegroundTaskBridge {
  FlutterForegroundTaskBridge._();

  static Future<bool> isServiceRunning() async {
    return MonitoringForegroundService.instance.isRunning();
  }
}
