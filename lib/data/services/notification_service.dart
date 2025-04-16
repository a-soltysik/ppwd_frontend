import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'stop_service') {
          // When user taps "Stop Service", invoke a method to stop the background service.
          FlutterBackgroundService().invoke("stopService");
        }
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    bool ongoing = true,
    List<AndroidNotificationAction>? actions,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          ongoing: ongoing,
          actions: actions,
        );
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> showBatteryLowNotification(int batteryLevel) async {
    await showNotification(
      id: 0,
      title: 'Battery Low',
      body: 'Battery is at $batteryLevel%. Please charge your device.',
      channelId: 'battery_channel',
      channelName: 'Battery Notifications',
      channelDescription: 'Notifications for low battery',
    );
  }

  Future<void> showDisconnectedNotification() async {
    await showNotification(
      id: 1,
      title: 'Device Disconnected',
      body: 'The device has been disconnected.',
      channelId: 'connection_channel',
      channelName: 'Connection Notifications',
      channelDescription: 'Notifications for connection issues',
    );
  }

  Future<void> showNoInternetNotification() async {
    await showNotification(
      id: 2,
      title: 'No Internet Connection',
      body: 'Internet connection is unavailable.',
      channelId: 'internet_channel',
      channelName: 'Internet Notifications',
      channelDescription: 'Notifications for internet connectivity',
    );
  }

  /// Display a persistent foreground notification with an action to stop the service.
  Future<void> showStopNotification() async {
    await showNotification(
      id: 999,
      title: 'Device Monitor Running',
      body: 'Tap "Stop Service" to end background operation',
      channelId: 'stop_channel',
      channelName: 'Stop Service',
      channelDescription: 'Tap the button below to stop the background service',
      ongoing: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'stop_service',
          'Stop Service',
          showsUserInterface: true,
        ),
      ],
    );
  }
}
