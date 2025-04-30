import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';

class NotificationService {
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _batteryNotificationCooldown = 60;

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
    final hasNotificationBeenShown =
        UserSimplePreferences.getNotificationKey() ?? false;

    final lastNotificationTime =
        UserSimplePreferences.getNotificationTime() ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    log('Checking battery level for notification: $level%');

    if (level < 20 &&
        !hasNotificationBeenShown &&
        (currentTime - lastNotificationTime >
            Duration(minutes: _batteryNotificationCooldown).inMilliseconds)) {
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

      await UserSimplePreferences.setNotificationKey(true);
      await UserSimplePreferences.setNotificationTime(currentTime);
    } else if (level >= 20) {
      await UserSimplePreferences.removeNotificationKey();
    }
  }
}
