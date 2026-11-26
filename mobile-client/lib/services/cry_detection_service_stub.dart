import 'dart:typed_data';

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

/// Web stub for CryDetectionService.
/// `onnxruntime` uses `dart:ffi` which is unsupported on Web (Chrome).
class CryDetectionService {
  int get windowSamples => 16000;
  int get alertSeconds => 2;
  double get threshold => 2.900390625;
  bool get isSupported => false;

  Future<void> init() async {}

  void reset() {}

  Future<CryDetectionStepResult> step(Float32List audio1sRaw) async {
    return const CryDetectionStepResult(
      score: 0.0,
      threshold: 2.900390625,
      isCry: false,
      episodeStarted: false,
      consecutiveCrySeconds: 0,
    );
  }

  void dispose() {}
}
