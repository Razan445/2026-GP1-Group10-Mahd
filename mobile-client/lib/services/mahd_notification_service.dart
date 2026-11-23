import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_settings_service.dart';

/// A request to open one of HomeScreen's existing bottom-navigation tabs.
/// 1 = monitoring history, 2 = calendar. No new screen is introduced.
class MahdNotificationDestination {
  const MahdNotificationDestination(this.tabIndex, {this.eventId});

  final int tabIndex;
  final String? eventId;
}

/// GP1 notification coordinator. Both system notifications and the in-app
/// unread bell refer to the same authenticated account's events.
///
/// Local calendar alarms are scheduled by the operating system. Once a due
/// reminder is observed inside Flutter, we persist the corresponding inbox
/// entry. We never claim that Dart executed at the time of a closed-app alarm.
class MahdNotificationService with WidgetsBindingObserver {
  MahdNotificationService._();
  static final MahdNotificationService instance =
      MahdNotificationService._();

  static const String _reminderChannelId = 'mahd_calendar_reminders';
  static const String _cryChannelId = 'mahd_cry_alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// HomeScreen listens to this; a tap from the notification shade emits it.
  final ValueNotifier<MahdNotificationDestination?> navigationRequest =
      ValueNotifier<MahdNotificationDestination?>(null);

  MahdNotificationDestination? _pendingColdStartDestination;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _reminderSubscription;
  Timer? _dueReminderTimer;
  User? _user;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastReminders = const [];
  Future<void> _syncQueue = Future<void>.value();
  bool _initialized = false;
  bool _nativeReady = false;

  bool get _supportedDevice =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      FirebaseFirestore.instance.collection('accounts').doc(uid).collection(
            'notifications',
          );

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _inbox(uid).where('isRead', isEqualTo: false).snapshots();
  }

  /// Initialize before runApp to capture cold-start notification taps.
  /// No alert permission prompt is shown until the user schedules a reminder.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    if (_supportedDevice) {
      try {
        tz_data.initializeTimeZones();
        final locationName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(locationName));

        final launch = await _plugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true) {
          _pendingColdStartDestination =
              _destinationForPayload(launch?.notificationResponse?.payload);
        }

        const settings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        );
        await _plugin.initialize(
          settings,
          onDidReceiveNotificationResponse: (response) {
            final destination = _destinationForPayload(response.payload);
            if (destination != null) {
              navigationRequest.value = destination;
            }
          },
        );
        _nativeReady = true;

        // Existing pending alarms must not survive an upgrade when calendar
        // reminders are disabled, even before an account snapshot arrives.
        if (!await LocalSettingsService.instance.getReminderAlertsEnabled()) {
          await _cancelAllManagedReminderAlarms();
        }
      } catch (error) {
        debugPrint('Mahd notifications initialization: $error');
        _nativeReady = false;
      }
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _bindAccount,
      onError: (Object error) {
        debugPrint('Mahd notification auth listener: $error');
      },
    );
  }

  MahdNotificationDestination? takeInitialDestination() {
    final result = _pendingColdStartDestination;
    _pendingColdStartDestination = null;
    return result;
  }

  MahdNotificationDestination? _destinationForPayload(String? payload) {
    if (payload == null) return null;
    if (payload.startsWith('cry|')) {
      return MahdNotificationDestination(1, eventId: payload.substring(4));
    }
    if (payload.startsWith('reminder|')) {
      return MahdNotificationDestination(2, eventId: payload.substring(9));
    }
    return null;
  }

  Future<bool> requestNotificationPermission() async {
    if (!_supportedDevice) return false;
    if (!_nativeReady) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } catch (error) {
      debugPrint('Mahd notification permission: $error');
      return false;
    }
  }

  /// Calendar notifications are opt-in. Turning them off cancels only
  /// scheduled Android/iOS reminders; Firestore reminders remain untouched.
  Future<void> setReminderAlertsEnabled(bool value) async {
    await LocalSettingsService.instance.setReminderAlertsEnabled(value);
    if (!value) {
      // Cancel immediately, then run a serialized reconcile so no queued
      // Firestore update can leave reminders scheduled while disabled.
      await _cancelAllManagedReminderAlarms();
    }
    _queueReconcile();
    await _syncQueue;
  }

  /// Android's special exact-alarm access is optional. Without it we still
  /// schedule an inexact alarm instead of claiming an exact delivery time.
  Future<bool> requestExactAlarmPermission() async {
    if (!_nativeReady || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      if (await android?.canScheduleExactNotifications() == true) return true;
      return await android?.requestExactAlarmsPermission() ?? false;
    } catch (error) {
      debugPrint('Mahd exact alarm permission: $error');
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _user != null) {
      _queueReconcile();
    }
  }

  Future<void> _bindAccount(User? user) async {
    await _reminderSubscription?.cancel();
    _reminderSubscription = null;
    _dueReminderTimer?.cancel();
    _dueReminderTimer = null;
    _user = user;
    _lastReminders = const [];
    if (user == null) {
      await _cancelAllManagedReminderAlarms();
      return;
    }

    _reminderSubscription = FirebaseFirestore.instance
        .collection('accounts')
        .doc(user.uid)
        .collection('reminders')
        .snapshots()
        .listen((snapshot) {
      if (_user?.uid != user.uid) return;
      _lastReminders = snapshot.docs;
      _queueReconcile();
    }, onError: (Object error) {
      debugPrint('Mahd reminder listener: $error');
    });
    _dueReminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _queueReconcile();
    });
  }

  void _queueReconcile() {
    final uid = _user?.uid;
    if (uid == null) return;
    final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      _lastReminders,
    );
    _syncQueue = _syncQueue.then((_) async {
      if (_user?.uid != uid) return;
      await _reconcile(uid, docs);
    }).catchError((Object error) {
      debugPrint('Mahd reminder reconcile: $error');
    });
  }

  static int _notificationId(String value) {
    // Stable FNV-1a hash; do not use String.hashCode across app launches.
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  bool _isActive(Map<String, dynamic> row) {
    final status = (row['status'] as String? ?? '').trim().toLowerCase();
    return status != 'completed' && status != 'مكتمل';
  }

  Future<void> _reconcile(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    // Preferences are independent of OS permissions and must be checked
    // when rescheduling after app launches, edits, and Firestore updates.
    final remindersEnabled =
        await LocalSettingsService.instance.getReminderAlertsEnabled();
    if (!remindersEnabled) {
      await _cancelAllManagedReminderAlarms();
      return;
    }
    final enabledSince = await LocalSettingsService.instance
        .getReminderAlertsEnabledSince();
    final now = DateTime.now();
    final upcoming = <({int id, String reminderId, String title, DateTime date})>[];
    final due = <({String reminderId, String title, DateTime date})>[];

    for (final doc in docs) {
      final row = doc.data();
      final timestamp = row['dateTime'];
      if (timestamp is! Timestamp || !_isActive(row)) continue;
      final date = timestamp.toDate();
      final title = (row['title'] as String?)?.trim() ?? '';
      if (date.isAfter(now)) {
        upcoming.add((
          id: _notificationId('reminder:$uid:${doc.id}'),
          reminderId: doc.id,
          title: title,
          date: date,
        ));
      } else if (date.isAfter(now.subtract(const Duration(days: 30))) &&
          enabledSince != null &&
          !date.isBefore(enabledSince)) {
        due.add((reminderId: doc.id, title: title, date: date));
      }
    }

    // Reconcile native pending alarms. Removes canceled/edited/completed items
    // even after an app restart. A device may schedule only a limited number.
    if (_nativeReady) {
      try {
        final pending = await _plugin.pendingNotificationRequests();
        final desiredIds = upcoming.map((a) => a.id).toSet();
        for (final item in pending) {
          if ((item.payload ?? '').startsWith('reminder|')) {
            if (!desiredIds.contains(item.id)) await _plugin.cancel(item.id);
          }
        }

        upcoming.sort((a, b) => a.date.compareTo(b.date));
        // iOS supports at most 64 pending notifications; keep a safe margin.
        final selected = upcoming.take(60);
        for (final entry in selected) {
          await _scheduleReminder(entry.id, entry.reminderId,
              entry.title, entry.date);
        }
      } catch (error) {
        debugPrint('Mahd native reminder scheduling: $error');
      }
    }

    // A scheduled local notification can fire with Dart fully suspended.
    // After opening the app, reconstruct the bell entry from Firestore's
    // original due time, never using the later app-opening time as dueAt.
    for (final entry in due) {
      if (_user?.uid != uid) break;
      final eventId =
          'reminder_${entry.reminderId}_${entry.date.millisecondsSinceEpoch}';
      final doc = _inbox(uid).doc(eventId);
      try {
        final existing = await doc.get();
        if (!existing.exists) {
          await doc.set({
            'eventId': eventId,
            'type': 'reminder',
            'reminderId': entry.reminderId,
            'title': entry.title,
            'dueAt': Timestamp.fromDate(entry.date),
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
        debugPrint('Mahd reminder inbox sync: $error');
      }
    }
  }

  Future<void> _scheduleReminder(
    int notificationId,
    String reminderId,
    String title,
    DateTime dateTime,
  ) async {
    if (!_nativeReady || !dateTime.isAfter(DateTime.now())) return;

    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final canExact = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      if (canExact == true) mode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    await _plugin.zonedSchedule(
      notificationId,
      'مهد — تذكير موعد',
      title.isEmpty ? 'حان وقت الموعد الذي أضفته في التقويم' : title,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'تذكيرات التقويم',
          channelDescription: 'تنبيهات المواعيد المجدولة في تقويم مهد',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                 UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'reminder|$reminderId',
    );
  }

  Future<void> _cancelAllManagedReminderAlarms() async {
    if (!_nativeReady) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final item in pending) {
        if ((item.payload ?? '').startsWith('reminder|')) {
          await _plugin.cancel(item.id);
        }
      }
    } catch (error) {
      debugPrint('Mahd cancel reminders: $error');
    }
  }

  /// Show a system alert immediately after a *real* inference result, without
  /// waiting for Firestore networking. This is why GP1 does not need FCM.
  Future<void> showRealCryLocal({required String eventId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !_nativeReady ||
        !await LocalSettingsService.instance.getCryAlertsEnabled()) {
      return;
    }
    await _plugin.show(
      _notificationId('cry:$uid:$eventId'),
      'مهد — تم رصد بكاء الطفل',
      'اضغطي للاطلاع على تفاصيل الحالة في سجل المراقبة',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _cryChannelId,
          'تنبيهات البكاء',
          channelDescription: 'تنبيهات بكاء الطفل المكتشف فعليًا',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'cry|$eventId',
    );
  }

  /// Persist the same event ID for the in-app red bell dot. This write may
  /// synchronize after the system alert if the phone was temporarily offline.
  Future<void> publishRealCry({
    required String eventId,
    required String sessionId,
    required String cause,
    required double confidence,
    required DateTime detectedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null ||
        !await LocalSettingsService.instance.getCryAlertsEnabled()) {
      return;
    }
    await _inbox(uid).doc('cry_$eventId').set({
      'eventId': eventId,
      'type': 'cry',
      'cryResultId': eventId,
      'sessionId': sessionId,
      'cause': cause,
      'confidence': confidence,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// The Home bell has only a red dot and a short dialog, not an inbox screen.
  /// Cry alerts open history; when there are only calendar alerts, open calendar.
  Future<int?> markUnreadAndGetTargetTab() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final unread = await _inbox(uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return null;
    final hasCry = unread.docs.any((doc) => doc.data()['type'] == 'cry');
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    return hasCry ? 1 : 2;
  }
}
