import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'audio_monitoring_service.dart';
import 'firestore_service.dart';
import 'mahd_notification_service.dart';

class MonitoringSessionNotActiveException implements Exception {
  const MonitoringSessionNotActiveException();
}

class MonitoringService {
  MonitoringService._();

  static final MonitoringService instance =
      MonitoringService._();

  final AudioMonitoringService _audioMonitoringService =
      AudioMonitoringService.instance;

  final FirestoreService _firestoreService =
      FirestoreService.instance;

  /// هل الميكروفون يستمع حاليًا؟
  bool get isMonitoring =>
      _audioMonitoringService.isMonitoring;

  /// الـSession الحالية التي أنشأها زر المراقبة.
  String? get activeSessionId =>
      _firestoreService.activeSessionId;

  /// هذا هو الصوت الخام القادم من الميكروفون.
  ///
  /// عند دمج الـML model لاحقًا، المودل سيستمع لهذا الـStream.
  Stream<Uint8List>? get audioStream =>
      _audioMonitoringService.audioStream;

  /// يستدعيها الـML model فقط عندما يكتشف بكاء حقيقي
  /// ويحدد السبب ونسبة الثقة.
  ///
  /// It writes one cry event to the approved cryData collection. Only
  /// real model output may call this method; never call it from mock cards.
  Future<void> saveCryData({
    required String cause,
    required double confidence,
    DateTime? detectedAt,
  }) async {
    final sessionId = activeSessionId;

    if (!isMonitoring || sessionId == null) {
      throw const MonitoringSessionNotActiveException();
    }

    // Contract: confidence is a normalized probability in the [0, 1] range.
    // If the model produces 0..100, convert it in its adapter, not in the UI.
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(confidence, 'confidence', 'Expected 0..1');
    }
    final occurrenceTime = detectedAt ?? DateTime.now();
    final eventId = _firestoreService.reserveCryDataId(sessionId: sessionId);

    // Alert first: same-device notifications must not wait for the cloud.
    try {
      await MahdNotificationService.instance.showRealCryLocal(
        eventId: eventId,
      );
    } catch (error) {
      debugPrint('Mahd local cry alert: $error');
    }

    // The cry event uses the original ID, timestamp, cause, and confidence.
    // Firestore can queue it offline and synchronize when connectivity returns.
    await _firestoreService.createCryData(
      sessionId: sessionId,
      cause: cause,
      confidence: confidence,
      detectedAt: occurrenceTime,
      cryResultId: eventId,
    );
  }

  /// جاهزة للترم القادم عند توفر بيانات الحساسات الحقيقية.
  ///
  /// لا نستخدمها الآن مع قيم وهمية.
  Future<void> saveEnvironmentData({
    required double temperature,
    required double humidity,
  }) async {
    final sessionId = activeSessionId;

    if (!isMonitoring || sessionId == null) {
      throw const MonitoringSessionNotActiveException();
    }

    await _firestoreService.createEnvironmentData(
      sessionId: sessionId,
      temperature: temperature,
      humidity: humidity,
    );
  }
}
