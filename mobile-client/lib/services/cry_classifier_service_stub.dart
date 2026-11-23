import 'dart:typed_data';

/// Web stub for CryClassifierService.
/// `onnxruntime` uses `dart:ffi` which is unsupported on Web (Chrome).
/// Real ONNX inference runs on mobile/desktop via `cry_classifier_service_io.dart`.
class CryClassifierService {
  Future<void> init() async {}

  Future<Map<String, double>> predict(Float32List audio32k) async {
    return const <String, double>{};
  }

  void dispose() {}
}
