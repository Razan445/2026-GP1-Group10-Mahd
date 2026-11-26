import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahd_app/services/cry_pipeline_logic.dart';

void main() {
  group('Policy P0 silence trimming & windowing', () {
    test('trims leading and trailing digital silence below -70 dB', () {
      final audio = Float32List(3200); // 10 frames of 320 samples
      // Active audio only in frames 3..6 (samples 960..2240).
      for (int i = 960; i < 2240; i++) {
        audio[i] = 0.05;
      }

      final trimmed = trimSilencePolicyP0(audio);
      expect(trimmed.length, 1280);
      expect(trimmed.first, closeTo(0.05, 1e-6));
      expect(trimmed.last, closeTo(0.05, 1e-6));
    });

    test('returns empty buffer when entire audio is below -70 dB', () {
      final silent = Float32List(1600);
      final trimmed = trimSilencePolicyP0(silent);
      expect(trimmed.isEmpty, isTrue);
    });

    test('zero-pads audio shorter than 2.0 s into 1 window', () {
      final shortAudio = Float32List(16000)..fillRange(0, 16000, 0.2);
      final windows = segmentIntoWindowsP0(shortAudio);
      expect(windows.length, 1);
      expect(windows.first.length, 32000);
      expect(windows.first[0], closeTo(0.2, 1e-6));
      expect(windows.first[15999], closeTo(0.2, 1e-6));
      expect(windows.first[16000], 0.0);
    });

    test('segments 6 s into 3 full windows and caps at maxWindows=3', () {
      final audio8s = Float32List(16000 * 8)..fillRange(0, 16000 * 8, 0.1);
      final windows = segmentIntoWindowsP0(audio8s, maxWindows: 3);
      expect(windows.length, 3);
      for (final w in windows) {
        expect(w.length, 32000);
      }
    });
  });

  group('Soft Voting + 3-Tier Confidence Gate', () {
    test('Case 1 (high): Top-1 >= 70%', () {
      final decision = applySoftVotingAndConfidenceGate([
        {'Hunger': 0.80, 'Burping': 0.10, 'Tired': 0.05, 'Pain': 0.03, 'Discomfort': 0.02},
        {'Hunger': 0.84, 'Burping': 0.08, 'Tired': 0.04, 'Pain': 0.02, 'Discomfort': 0.02},
      ]);

      expect(decision.tier, CryClassificationTier.high);
      expect(decision.primaryCause, 'Hunger');
      expect(decision.primaryConfidence, closeTo(0.82, 1e-6));
      expect(decision.secondaryCause, isNull);
      expect(decision.windowCount, 2);
      expect(
        decision.formatArabicNotificationBody(),
        'الطفل يبكي — غالباً: الجوع (82٪)',
      );
    });

    test('Case 2 (medium): Top-1 < 70% and Top-1 + Top-2 >= 70%', () {
      final decision = applySoftVotingAndConfidenceGate([
        {'Hunger': 0.46, 'Burping': 0.38, 'Tired': 0.08, 'Pain': 0.04, 'Discomfort': 0.04},
      ]);

      expect(decision.tier, CryClassificationTier.medium);
      expect(decision.primaryCause, 'Hunger');
      expect(decision.primaryConfidence, closeTo(0.46, 1e-6));
      expect(decision.secondaryCause, 'Burping');
      expect(decision.secondaryConfidence, closeTo(0.38, 1e-6));
      expect(
        decision.formatArabicNotificationBody(),
        'الطفل يبكي — الأقرب احتمالاً: الجوع (46٪) أو الحاجة للتجشؤ (38٪)',
      );
    });

    test('Case 3 (unclassified): Top-1 + Top-2 < 70%', () {
      final decision = applySoftVotingAndConfidenceGate([
        {'Hunger': 0.30, 'Burping': 0.25, 'Tired': 0.20, 'Pain': 0.15, 'Discomfort': 0.10},
      ]);

      expect(decision.tier, CryClassificationTier.unclassified);
      expect(decision.primaryCause, 'Unclassified');
      expect(decision.secondaryCause, isNull);
      expect(
        decision.formatArabicNotificationBody(),
        'الطفل يبكي — السبب غير محدد',
      );
    });
  });
}
