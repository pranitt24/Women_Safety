import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init({void Function(String?)? onSelectNotification}) async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Sakhi');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          onSelectNotification?.call(response.payload);
        },
      );
      _initialized = true;
      debugPrint('[NotificationService] Local notifications initialized.');
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  static Future<void> showCheckInNotification({
    String title = 'Reached safely?',
    String body = 'Your Safe Journey ETA has arrived. Tap to confirm you are safe.',
    String payload = 'check_in',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sakhi_checkin_channel',
      'Safe Journey Check-in',
      channelDescription: 'Prompts users to confirm safety at planned ETA',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Safety check-in',
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(101, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  static Future<void> showDistressNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sakhi_distress_channel',
      'Distress Alerts',
      channelDescription: 'Active emergency distress alerts',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFFC8202F),
      ongoing: true,
      autoCancel: false,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(999, title, body, details);
    } catch (e) {
      debugPrint('[NotificationService] Error showing distress notification: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
