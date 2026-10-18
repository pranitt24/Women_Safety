import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Top-level task callback required by flutter_foreground_task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SakhiTaskHandler());
}

class SakhiTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundService] Background monitoring started.');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Keeps background thread alive for sensor and BLE mesh relay
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[ForegroundService] Background monitoring stopped.');
  }
}

class ForegroundServiceManager {
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_initialized) return;

    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'sakhi_foreground_service',
          channelName: 'Sakhi Safety Active Protection',
          channelDescription: 'Keeps SOS, BLE relay and sensor monitoring active with screen off.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
      _initialized = true;
      debugPrint('[ForegroundServiceManager] Foreground task initialized.');
    } catch (e) {
      debugPrint('[ForegroundServiceManager] Init error: $e');
    }
  }

  static Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        return;
      }
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Sakhi Safety is Active',
        notificationText: 'SOS, offline BLE relay & fall detection running.',
        callback: startCallback,
      );
    } catch (e) {
      debugPrint('[ForegroundServiceManager] Start error: $e');
    }
  }

  static Future<void> stop() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}
