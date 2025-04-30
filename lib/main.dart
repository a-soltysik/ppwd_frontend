import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppwd_frontend/data/services/background_service.dart'
    as bg_service;
import 'package:ppwd_frontend/data/services/notification_service.dart';
import 'package:ppwd_frontend/presentation/widgets/app_navigation_bar.dart';

const _fgChannelId = 'device_monitor_channel';
const _fgChannelName = 'Device Monitor';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  await requestPermissions();

  await NotificationService().setupFlutterNotifications(
    channelId: _fgChannelId,
    channelName: _fgChannelName,
  );

  await bg_service.initializeBackgroundService();

  FlutterNativeSplash.remove();

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

Future<void> requestPermissions() async {
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

  var locationStatus = await Permission.location.request();
  if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
    await openAppSettings();
  }
}
