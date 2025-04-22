import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppwd_frontend/data/services/background_service.dart';
import 'package:ppwd_frontend/data/services/notification_service.dart';
import 'package:ppwd_frontend/presentation/widgets/app_navigation_bar.dart';

const _fgChannelId = 'device_monitor_channel';
const _fgChannelName = 'Device Monitor';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  final fln = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await fln.initialize(const InitializationSettings(android: androidInit));

  await fln
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _fgChannelId,
          _fgChannelName,
          importance: Importance.high,
        ),
      );

  await NotificationService().init();

  await Permission.location.request();
  if (!await Permission.location.isGranted) {
    await openAppSettings();
  }

  await initializeBackgroundService();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.bluetoothConnect.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      await openAppSettings();
    }

    final bluetoothStatus = await Permission.bluetoothScan.request();
    if (bluetoothStatus.isDenied || bluetoothStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    var notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Java',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.orange),
      home: const AppNavigationBar(),
    );
  }
}

void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  print("Our background job ran!");
}
