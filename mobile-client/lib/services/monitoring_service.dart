import 'dart:typed_data';

import 'audio_monitoring_service.dart';
import 'firestore_service.dart';

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
  Future<void> saveCryResult({
    required String cause,
    required double confidence,
  }) async {
    final sessionId = activeSessionId;

    if (!isMonitoring || sessionId == null) {
      throw const MonitoringSessionNotActiveException();
    }

    await _firestoreService.createCryResult(
      sessionId: sessionId,
      cause: cause,
      confidence: confidence,
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