import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';
import 'package:ppwd_frontend/presentation/navigation/app_navigation_bar.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await UserSimplePreferences.init();
  await requestPermissions();

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

    Future.delayed(const Duration(milliseconds: 300), () {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppNavigationBar(),
    );
  }
}

Future<void> requestPermissions() async {
  Map<Permission, String> permissionsToRequest = {
    Permission.bluetoothConnect: 'Bluetooth Connect',
    Permission.bluetoothScan: 'Bluetooth Scan',
    Permission.notification: 'Notifications',
    Permission.location: 'Location',
  };

  bool needOpenSettings = false;

  for (var entry in permissionsToRequest.entries) {
    final permission = entry.key;
    final permissionName = entry.value;

    final status = await permission.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      Logger.e('$permissionName permission denied');
      needOpenSettings = true;
    }
  }

  if (needOpenSettings) {
    await openAppSettings();
  }
}
