import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'cry_cause_classifier.dart';

/// Stage 2 Cry Cause Classifier backed by ONNX Runtime.
///
/// Currently loads `mahd_pipeline1_int8.onnx` (DistilHuBERT) as an interim
/// classifier until the final Lightweight 2D-CNN model replaces it.
class CryClassifierService implements CryCauseClassifier {
  OrtSession? _session;
  List<String> _labels = const [];
  int _windowSamples = 32000;
  String _inputName = 'audio';

  @override
  int get windowSamples => _windowSamples;

  @override
  Future<void> init() async {
    if (_session != null) return;

    OrtEnv.instance.init();

    final metaStr = await rootBundle.loadString(
      'assets/models/mahd_pipeline1_meta.json',
    );
    final meta = jsonDecode(metaStr) as Map<String, dynamic>;
    _labels = List<String>.from(meta['labels'] as List);
    _windowSamples = (meta['window_samples'] as num?)?.toInt() ?? 32000;
    _inputName = (meta['input_name'] as String?) ?? 'audio';

    final rawModel = await rootBundle.load(
      'assets/models/mahd_pipeline1_int8.onnx',
    );
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
  }

  /// Classifies one 2.0-second (32,000-sample) mono 16 kHz audio window.
  /// Applies peak normalization safely before inference; zero-mean/unit-var
  /// normalization and Softmax are built inside the ONNX graph.
  @override
  Future<Map<String, double>> predict(Float32List audioWindow) async {
    final session = _session;
    if (session == null) {
      throw StateError('CryClassifierService is not initialized.');
    }

    double maxAbs = 0.0;
    final len = min(audioWindow.length, _windowSamples);
    for (int i = 0; i < len; i++) {
      final v = audioWindow[i].abs();
      if (v > maxAbs) maxAbs = v;
    }

    final normalized = Float32List(_windowSamples);
    if (maxAbs > 1e-6) {
      for (int i = 0; i < len; i++) {
        normalized[i] = audioWindow[i] / maxAbs;
      }
    }

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      normalized,
      [1, _windowSamples],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;

    try {
      outputs = await session.runAsync(runOptions, {
        _inputName: inputTensor,
      });

      final probs = (outputs?.first?.value as List<List<double>>).first;
      if (probs.length != _labels.length) {
        throw StateError(
          'Classifier output length (${probs.length}) does not match '
          'labels length (${_labels.length}).',
        );
      }

      return {
        for (int i = 0; i < _labels.length; i++) _labels[i]: probs[i],
      };
    } finally {
      inputTensor.release();
      runOptions.release();
      outputs?.forEach((e) => e?.release());
    }
  }

  @override
  void dispose() {
    _session?.release();
    _session = null;
    // Do NOT call OrtEnv.instance.release(): shared with CryDetectionService.
  }
}
