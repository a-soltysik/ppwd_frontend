import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<FlutterLocalNotificationsPlugin> setupFlutterNotifications({
    required String channelId,
    required String channelName,
    Importance importance = Importance.high,
  }) async {
    final fln = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    await fln.initialize(const InitializationSettings(android: androidInit));

    await fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            importance: importance,
          ),
        );

    return fln;
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
}
