import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// One real cry event. Environmental values intentionally remain nullable in
/// GP1: there are no connected temperature or humidity sensors yet.
class MahdCryEvent {
  const MahdCryEvent({
    required this.id,
    required this.sessionId,
    required this.cause,
    required this.detectedAt,
    this.confidence,
    this.temperature,
    this.humidity,
  });

  final String id;
  final String sessionId;
  final String cause;
  final DateTime detectedAt;
  final double? confidence;
  final double? temperature;
  final double? humidity;
}

/// Aggregates the existing nested collection paths without needing a new
/// Firestore collectionGroup index or a change to Firestore security rules.
class CryEventsRepository {
  CryEventsRepository._();
  static final CryEventsRepository instance = CryEventsRepository._();

  Stream<List<MahdCryEvent>> watchEvents() {
    late StreamController<List<MahdCryEvent>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sessionSub;
    final crySubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final eventMap = <String, List<MahdCryEvent>>{};

    void emit() {
      if (controller.isClosed) return;
      final all = eventMap.values.expand((items) => items).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      controller.add(all);
    }

    controller = StreamController<List<MahdCryEvent>>(
      onListen: () {
        sessionSub = FirestoreService.instance.watchSessions().listen(
          (sessions) {
            final ids = sessions.docs.map((doc) => doc.id).toSet();
            for (final removed in crySubs.keys.toList()) {
              if (ids.contains(removed)) continue;
              crySubs.remove(removed)?.cancel();
              eventMap.remove(removed);
            }
            for (final sessionId in ids) {
              if (crySubs.containsKey(sessionId)) continue;
              crySubs[sessionId] = FirestoreService.instance
                  .watchCryData(sessionId: sessionId)
                  .listen((snapshot) {
                eventMap[sessionId] = snapshot.docs
                    .map((doc) {
                      final row = doc.data();
                      final stamp = row['timestamp'];
                      if (stamp is! Timestamp) return null;
                      final cause = (row['cause'] as String? ?? '').trim();
                      if (cause.isEmpty) return null;
                      return MahdCryEvent(
                        id: doc.id,
                        sessionId: sessionId,
                        cause: cause,
                        detectedAt: stamp.toDate(),
                        confidence: (row['confidence'] as num?)?.toDouble(),
                        temperature: (row['temperature'] as num?)?.toDouble(),
                        humidity: (row['humidity'] as num?)?.toDouble(),
                      );
                    })
                    .whereType<MahdCryEvent>()
                    .toList(growable: false);
                emit();
              }, onError: controller.addError);
            }
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await sessionSub?.cancel();
        for (final sub in crySubs.values) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }
}

/// Display mapping for the *actual* five-class model outputs, not an
/// additional medical diagnosis. Unknown labels are left unchanged.
String mahdCryLabelArabic(String label) {
  switch (label.trim().toLowerCase()) {
    case 'hunger':
      return 'الجوع';
    case 'pain':
      return 'الألم';
    case 'tired':
      return 'التعب';
    case 'discomfort':
      return 'عدم الراحة';
    case 'burping':
      return 'الحاجة للتجشؤ';
    default:
      return label;
  }
}
