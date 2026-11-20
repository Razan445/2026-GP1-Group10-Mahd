import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_settings_service.dart';

class CryNotificationService {
  CryNotificationService._();

  static final CryNotificationService instance = CryNotificationService._();

  static const String _channelId = 'mahd_cry_alerts';
  static const String _channelName = 'تنبيهات البكاء';
  static const String _channelDescription =
      'إشعارات فورية عند رصد بكاء الطفل مع السبب المحتمل';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initSettings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      debugPrint('CryNotificationService init error: $e');
    }
  }

  Future<void> showCryAlert({
    required String arabicCause,
    required double confidence,
  }) async {
    if (kIsWeb) return;

    final enabled = await LocalSettingsService.instance.getCryAlertsEnabled();
    if (!enabled) return;

    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;

    final percent = (confidence * 100).round();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: 1001,
        title: 'تم رصد بكاء طفلك',
        body: 'السبب المحتمل: $arabicCause (نسبة التأكد $percent%)',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('CryNotificationService show error: $e');
    }
  }
}
