import 'dart:developer';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as bg;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    log('Initializing NotificationService');
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        if (resp.actionId == 'stop_service') {
          bg.FlutterBackgroundServiceAndroid().invoke('stopService');
        }
      },
    );
  }

  Future<void> showBatteryLowNotification(int level) async {
    log('Showing battery low notification: $level%');
    await _notifications.show(
      0,
      'Battery Low',
      'Battery is at $level%. Please charge.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'battery_channel',
          'Battery Notifications',
          channelDescription: 'Alerts when battery is low',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
        ),
      ),
    );
  }

  Future<void> showStopServiceNotification() async {
    log('Showing stop service notification');
    await _notifications.show(
      999,
      'Device Monitor',
      'Tap to stop background service',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'stop_channel',
          'Stop Service',
          channelDescription: 'Stop the background monitor',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: false,
          actions: [AndroidNotificationAction('stop_service', 'Stop Service')],
        ),
      ),
    );
  }
}
