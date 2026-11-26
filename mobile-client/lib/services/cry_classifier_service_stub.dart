import 'dart:typed_data';

import 'cry_cause_classifier.dart';

/// Web stub for CryClassifierService.
/// `onnxruntime` uses `dart:ffi` which is unsupported on Web (Chrome).
/// Real ONNX inference runs on mobile/desktop via `cry_classifier_service_io.dart`.
class CryClassifierService implements CryCauseClassifier {
  @override
  int get windowSamples => 32000;

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, double>> predict(Float32List audioWindow) async {
    return const <String, double>{};
  }

  @override
  void dispose() {}
}
