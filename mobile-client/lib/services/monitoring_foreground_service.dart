
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void mahdMonitoringForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(
    MahdMonitoringTaskHandler(),
  );
}

class MahdMonitoringTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    debugPrint('MAHD FOREGROUND: Service started.');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // The microphone stream is managed by AudioMonitoringService.
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    debugPrint('MAHD FOREGROUND: Service stopped.');
  }
}

class MonitoringForegroundService {
  MonitoringForegroundService._();

  static final MonitoringForegroundService instance =
      MonitoringForegroundService._();

  bool _initialized = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void initialize() {
    if (!isSupported || _initialized) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'mahd_microphone_monitoring',
        channelName: 'Mahd Microphone Monitoring',
        channelDescription:
            'Shows when Mahd is monitoring audio using the microphone.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: false,
        stopWithTask: false,
      ),
    );

    _initialized = true;
  }

  Future<bool> isRunning() async {
    if (!isSupported) {
      return false;
    }

    return FlutterForegroundTask.isRunningService;
  }

  Future<void> start() async {
    if (!isSupported) {
      return;
    }

    initialize();

    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('MAHD FOREGROUND: Service already running.');
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      serviceTypes: [
        ForegroundServiceTypes.microphone,
      ],
      notificationTitle: 'مَهد - المراقبة الصوتية',
      notificationText:
          'المراقبة الصوتية قيد التشغيل. اضغطي للعودة إلى مَهد.',
      callback: mahdMonitoringForegroundCallback,
    );

    if (result is! ServiceRequestSuccess) {
      throw StateError(
        'Could not start microphone foreground service: $result',
      );
    }

    debugPrint(
      'MAHD FOREGROUND: Microphone foreground service requested.',
    );
  }

  Future<void> stop() async {
    if (!isSupported) {
      return;
    }

    if (!await FlutterForegroundTask.isRunningService) {
      return;
    }

    final result = await FlutterForegroundTask.stopService();

    if (result is! ServiceRequestSuccess) {
      throw StateError(
        'Could not stop microphone foreground service: $result',
      );
    }

    debugPrint('MAHD FOREGROUND: Stop completed.');
  }
}
