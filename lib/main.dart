import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppwd_frontend/core/utils/app_lifecycle_observer.dart';
import 'package:ppwd_frontend/data/services/background_service.dart';
import 'package:ppwd_frontend/presentation/widgets/app_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  // Add lifecycle observer (optional: used for conditional notification logic)
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  // Start the background service.
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

    // Request notification permission (needed for Android 13+)
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
