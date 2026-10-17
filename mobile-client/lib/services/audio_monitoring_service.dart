import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioMonitoringPermissionException implements Exception {
  const AudioMonitoringPermissionException();
}

class AudioMonitoringService {
  AudioMonitoringService._();

  static final AudioMonitoringService instance =
      AudioMonitoringService._();

  final AudioRecorder _recorder = AudioRecorder();

  StreamController<Uint8List>? _audioController;
  StreamSubscription<Uint8List>? _recorderSubscription;

  bool _isMonitoring = false;

  bool get isMonitoring => _isMonitoring;

  /// Audio stream that will be connected to the ML model later.
  Stream<Uint8List>? get audioStream => _audioController?.stream;

  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw const AudioMonitoringPermissionException();
    }

    final controller = StreamController<Uint8List>.broadcast();

    try {
      final recorderStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioController = controller;

      _recorderSubscription = recorderStream.listen(
        controller.add,
        onError: controller.addError,
      );

      _isMonitoring = true;
    } catch (_) {
      await controller.close();
      rethrow;
    }
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) {
      return;
    }

    await _recorder.stop();

    await _recorderSubscription?.cancel();
    _recorderSubscription = null;

    final controller = _audioController;
    _audioController = null;

    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    _isMonitoring = false;
  }

  Future<void> dispose() async {
    if (_isMonitoring) {
      await stopMonitoring();
    }

    await _recorder.dispose();
  }
}