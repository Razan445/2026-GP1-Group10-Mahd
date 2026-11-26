import 'dart:typed_data';

/// Abstract contract for Stage 2 Cry Cause Classification models.
///
/// Currently backed by DistilHuBERT (`CryClassifierService`). When the final
/// Lightweight 2D-CNN model is ready, implement this interface and swap the
/// classifier instance in `CryMonitoringPipeline` without changing any pipeline,
/// notification, or Firestore code.
abstract class CryCauseClassifier {
  /// Expected mono 16 kHz audio window length in samples (2.0 s = 32,000).
  int get windowSamples;

  /// Loads model weights and metadata into memory.
  Future<void> init();

  /// Predicts class probabilities (Softmax in [0, 1]) for one audio window.
  Future<Map<String, double>> predict(Float32List audioWindow);

  /// Releases model session resources.
  void dispose();
}
