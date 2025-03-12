import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppwd_frontend/pages/home_page.dart';

void main() {
  runApp(MyApp());
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
    _requestBluetoothConnectPermission();
  }

  Future<void> _requestBluetoothConnectPermission() async {
    final status = await Permission.bluetoothConnect.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Java',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.orange),
      home: HomePage(),
    );
  }
}
