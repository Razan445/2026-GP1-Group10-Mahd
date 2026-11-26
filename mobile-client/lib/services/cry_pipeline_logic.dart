import 'dart:math' as math;
import 'dart:typed_data';

import 'cry_events_repository.dart';

/// Confidence gate tier produced by Soft Voting over Stage 2 windows.
enum CryClassificationTier {
  /// Top-1 probability >= 70% — clear single likely cause.
  high,

  /// Top-1 < 70% and (Top-1 + Top-2) >= 70% — top two likely causes.
  medium,

  /// (Top-1 + Top-2) < 70% — cry confirmed, cause unclassified.
  unclassified,
}

/// Final Stage 2 decision after Policy P0, Soft Voting, and the 3-tier gate.
class CryCauseDecision {
  const CryCauseDecision({
    required this.tier,
    required this.primaryCause,
    required this.primaryConfidence,
    required this.averagedProbabilities,
    required this.windowCount,
    this.secondaryCause,
    this.secondaryConfidence,
  });

  final CryClassificationTier tier;

  /// Canonical English label (`Hunger`, `Pain`, `Tired`, `Discomfort`,
  /// `Burping`, or `Unclassified`).
  final String primaryCause;

  /// Normalized confidence in [0, 1].
  final double primaryConfidence;

  /// Present only when [tier] == [CryClassificationTier.medium].
  final String? secondaryCause;

  /// Normalized confidence in [0, 1] for [secondaryCause].
  final double? secondaryConfidence;

  final Map<String, double> averagedProbabilities;
  final int windowCount;

  String get tierName => tier.name;

  /// Arabic notification body matching the 3-tier confidence gate specification.
  String formatArabicNotificationBody() {
    switch (tier) {
      case CryClassificationTier.high:
        final causeAr = mahdCryLabelArabic(primaryCause);
        final pct = _formatPercent(primaryConfidence);
        return 'الطفل يبكي — غالباً: $causeAr ($pct٪)';
      case CryClassificationTier.medium:
        final primaryAr = mahdCryLabelArabic(primaryCause);
        final primaryPct = _formatPercent(primaryConfidence);
        final secondaryAr = mahdCryLabelArabic(secondaryCause ?? '');
        final secondaryPct = _formatPercent(secondaryConfidence ?? 0.0);
        return 'الطفل يبكي — الأقرب احتمالاً: $primaryAr ($primaryPct٪) '
            'أو $secondaryAr ($secondaryPct٪)';
      case CryClassificationTier.unclassified:
        return 'الطفل يبكي — السبب غير محدد';
    }
  }

  static String _formatPercent(double value) {
    return (value.clamp(0.0, 1.0) * 100).round().toString();
  }
}

/// Policy P0: Trims leading and trailing digital silence below
/// [silenceThresholdDb] (default -70 dB) using short RMS frames.
Float32List trimSilencePolicyP0(
  Float32List audio, {
  double silenceThresholdDb = -70.0,
  int frameSamples = 320, // 20 ms at 16 kHz
}) {
  if (audio.isEmpty) return Float32List(0);

  final rmsThreshold = math.pow(10.0, silenceThresholdDb / 20.0).toDouble();
  final totalFrames = (audio.length + frameSamples - 1) ~/ frameSamples;

  int? firstActiveFrame;
  int? lastActiveFrame;

  for (int frame = 0; frame < totalFrames; frame++) {
    final start = frame * frameSamples;
    final end = math.min(start + frameSamples, audio.length);
    double sumSq = 0.0;
    for (int i = start; i < end; i++) {
      final s = audio[i];
      sumSq += s * s;
    }
    final rms = math.sqrt(sumSq / (end - start));
    if (rms >= rmsThreshold) {
      firstActiveFrame ??= frame;
      lastActiveFrame = frame;
    }
  }

  if (firstActiveFrame == null || lastActiveFrame == null) {
    return Float32List(0);
  }

  final startSample = firstActiveFrame * frameSamples;
  final endSample = math.min((lastActiveFrame + 1) * frameSamples, audio.length);
  return Float32List.sublistView(audio, startSample, endSample);
}

/// Policy P0: Segments episode audio into 1–[maxWindows] fixed-length windows
/// of [windowSamples] (2.0 s = 32,000 samples at 16 kHz).
///
/// - If shorter than [windowSamples], produces 1 zero-padded window.
/// - Trailing partial segments >= [minPartialSamples] (0.5 s) are zero-padded
///   into an additional window up to [maxWindows].
List<Float32List> segmentIntoWindowsP0(
  Float32List audio, {
  int windowSamples = 32000,
  int maxWindows = 3,
  int minPartialSamples = 8000,
}) {
  if (audio.isEmpty || windowSamples <= 0 || maxWindows <= 0) {
    return const <Float32List>[];
  }

  final windows = <Float32List>[];

  if (audio.length <= windowSamples) {
    final padded = Float32List(windowSamples);
    padded.setRange(0, audio.length, audio);
    windows.add(padded);
    return windows;
  }

  int offset = 0;
  while (offset < audio.length && windows.length < maxWindows) {
    final remaining = audio.length - offset;
    if (remaining >= windowSamples) {
      final win = Float32List(windowSamples);
      win.setRange(0, windowSamples, audio, offset);
      windows.add(win);
      offset += windowSamples;
    } else if (remaining >= minPartialSamples) {
      final padded = Float32List(windowSamples);
      padded.setRange(0, remaining, audio, offset);
      windows.add(padded);
      break;
    } else {
      break;
    }
  }

  return windows;
}

/// Concatenates sequential raw 1-second buffers into a single contiguous array.
Float32List concatAudioBuffers(List<Float32List> chunks) {
  int totalLength = 0;
  for (final chunk in chunks) {
    totalLength += chunk.length;
  }
  final merged = Float32List(totalLength);
  int offset = 0;
  for (final chunk in chunks) {
    merged.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }
  return merged;
}

/// Applies Soft Voting (mean probabilities across windows) followed by the
/// 3-tier Confidence Gate (default threshold = 0.70):
/// - Case 1: Top-1 >= 0.70 -> high confidence single cause
/// - Case 2: Top-1 < 0.70 and (Top-1 + Top-2) >= 0.70 -> medium (top 2 causes)
/// - Case 3: (Top-1 + Top-2) < 0.70 -> unclassified
CryCauseDecision applySoftVotingAndConfidenceGate(
  List<Map<String, double>> windowProbabilities, {
  double threshold = 0.70,
}) {
  final sums = <String, double>{};
  int validWindowCount = 0;

  for (final probs in windowProbabilities) {
    if (probs.isEmpty) continue;
    bool hasValidEntry = false;
    for (final entry in probs.entries) {
      final v = entry.value;
      if (!v.isFinite || v < 0.0 || v > 1.0) continue;
      sums[entry.key] = (sums[entry.key] ?? 0.0) + v;
      hasValidEntry = true;
    }
    if (hasValidEntry) {
      validWindowCount++;
    }
  }

  if (validWindowCount == 0 || sums.isEmpty) {
    return const CryCauseDecision(
      tier: CryClassificationTier.unclassified,
      primaryCause: 'Unclassified',
      primaryConfidence: 0.0,
      averagedProbabilities: <String, double>{},
      windowCount: 0,
    );
  }

  final averaged = <String, double>{
    for (final entry in sums.entries)
      entry.key: (entry.value / validWindowCount).clamp(0.0, 1.0),
  };

  final ranked = averaged.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top1 = ranked.first;
  final top2 = ranked.length >= 2 ? ranked[1] : null;

  if (top1.value >= threshold) {
    return CryCauseDecision(
      tier: CryClassificationTier.high,
      primaryCause: top1.key,
      primaryConfidence: top1.value,
      averagedProbabilities: averaged,
      windowCount: validWindowCount,
    );
  }

  if (top2 != null && (top1.value + top2.value) >= threshold) {
    return CryCauseDecision(
      tier: CryClassificationTier.medium,
      primaryCause: top1.key,
      primaryConfidence: top1.value,
      secondaryCause: top2.key,
      secondaryConfidence: top2.value,
      averagedProbabilities: averaged,
      windowCount: validWindowCount,
    );
  }

  return CryCauseDecision(
    tier: CryClassificationTier.unclassified,
    primaryCause: 'Unclassified',
    primaryConfidence: top1.value,
    averagedProbabilities: averaged,
    windowCount: validWindowCount,
  );
}
