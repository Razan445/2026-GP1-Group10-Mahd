import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class CryDetectionStepResult {
  const CryDetectionStepResult({
    required this.score,
    required this.threshold,
    required this.isCry,
    required this.episodeStarted,
    required this.consecutiveCrySeconds,
  });

  final double score;
  final double threshold;
  final bool isCry;
  final bool episodeStarted;
  final int consecutiveCrySeconds;
}

/// Stage 1: On-device CRNN Cry Detection via ONNX Runtime.
///
/// Expects raw 1-second 16 kHz mono float32 PCM audio in [-1, 1] WITHOUT peak
/// normalization. Log-Mel extraction, RMS loudness normalization (-50 dB floor),
/// and standardization are embedded inside `mahd_cry_detection_crnn.onnx`.
class CryDetectionService {
  OrtSession? _session;

  int _windowSamples = 16000;
  int _totalSeconds = 5;
  int _alertSeconds = 2;
  double _threshold = 2.900390625;
  String _inputAudioName = 'audio';
  String _inputOkName = 'ok';

  /// Rolling context of raw 1-second windows, newest at index 0.
  final List<Float32List> _context = <Float32List>[];
  int _cryRun = 0;

  int get windowSamples => _windowSamples;
  int get alertSeconds => _alertSeconds;
  double get threshold => _threshold;
  bool get isSupported => true;

  Future<void> init() async {
    if (_session != null) return;

    OrtEnv.instance.init();

    final metaStr = await rootBundle.loadString(
      'assets/models/mahd_cry_detection_meta.json',
    );
    final meta = jsonDecode(metaStr) as Map<String, dynamic>;

    _windowSamples = (meta['window_samples'] as num?)?.toInt() ?? 16000;
    _totalSeconds = (meta['total_seconds'] as num?)?.toInt() ?? 5;
    _alertSeconds = (meta['alert_seconds'] as num?)?.toInt() ?? 2;
    _threshold = (meta['threshold'] as num?)?.toDouble() ?? 2.900390625;
    _inputAudioName = (meta['input_audio_name'] as String?) ?? 'audio';
    _inputOkName = (meta['input_ok_name'] as String?) ?? 'ok';

    final modelFile =
        (meta['model'] as String?) ?? 'mahd_cry_detection_crnn.onnx';
    final rawModel = await rootBundle.load('assets/models/$modelFile');
    final bytes = rawModel.buffer.asUint8List(
      rawModel.offsetInBytes,
      rawModel.lengthInBytes,
    );

    final sessionOptions = OrtSessionOptions();
    try {
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
    } finally {
      sessionOptions.release();
    }

    reset();
  }

  /// Clears temporal context and consecutive-cry counter when a new stream starts.
  void reset() {
    _context.clear();
    _cryRun = 0;
  }

  /// Evaluates one raw 1-second (16,000-sample) audio window with up to 4
  /// previous seconds of temporal context.
  Future<CryDetectionStepResult> step(Float32List audio1sRaw) async {
    final session = _session;
    if (session == null) {
      throw StateError('CryDetectionService is not initialized.');
    }
    if (audio1sRaw.length != _windowSamples) {
      throw ArgumentError.value(
        audio1sRaw.length,
        'audio1sRaw.length',
        'Expected exactly $_windowSamples samples (1 second at 16 kHz).',
      );
    }

    // Store a copy so callers can safely reuse their source buffer.
    _context.insert(0, Float32List.fromList(audio1sRaw));
    if (_context.length > _totalSeconds) {
      _context.removeLast();
    }

    final audioFlat = Float32List(_totalSeconds * _windowSamples);
    final okFlat = Float32List(_totalSeconds);
    for (int i = 0; i < _context.length; i++) {
      audioFlat.setRange(
        i * _windowSamples,
        (i + 1) * _windowSamples,
        _context[i],
      );
      okFlat[i] = 1.0;
    }

    final audioTensor = OrtValueTensor.createTensorWithDataList(
      audioFlat,
      [1, _totalSeconds, _windowSamples],
    );
    final okTensor = OrtValueTensor.createTensorWithDataList(
      okFlat,
      [1, _totalSeconds],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;

    try {
      outputs = await session.runAsync(runOptions, {
        _inputAudioName: audioTensor,
        _inputOkName: okTensor,
      });

      final rawValue = outputs?.first?.value;
      final score = _extractScore(rawValue);
      final isCry = score.isFinite && score >= _threshold;
      _cryRun = isCry ? (_cryRun + 1) : 0;

      return CryDetectionStepResult(
        score: score,
        threshold: _threshold,
        isCry: isCry,
        episodeStarted: _cryRun == _alertSeconds,
        consecutiveCrySeconds: _cryRun,
      );
    } finally {
      audioTensor.release();
      okTensor.release();
      runOptions.release();
      outputs?.forEach((e) => e?.release());
    }
  }

  static double _extractScore(Object? rawValue) {
    if (rawValue is List && rawValue.isNotEmpty) {
      final first = rawValue.first;
      if (first is List && first.isNotEmpty && first.first is num) {
        return (first.first as num).toDouble();
      }
      if (first is num) {
        return first.toDouble();
      }
    }
    throw StateError('Unexpected CRNN ONNX output format: $rawValue');
  }

  void dispose() {
    _session?.release();
    _session = null;
    _context.clear();
    _cryRun = 0;
    // Do NOT call OrtEnv.instance.release(): the global ONNX Runtime
    // environment is shared across models and monitoring sessions.
  }
}
