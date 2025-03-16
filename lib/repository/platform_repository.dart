import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformRepository {
  static const platform = MethodChannel('flutter.native/sensor/imperative');

  bool isLoading = false;
  showLoading(BuildContext context) {
    isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  hideLoading(BuildContext context) {
    if (!isLoading) return;

    isLoading = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> connectToDevice(BuildContext context, String mac) async {
    showLoading(context);
    try {
      final String result = await platform.invokeMethod(
        'connectToSensorService',
        {'macAddress': mac},
      );
      print(result); // "Connected to <mac>"
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected successfully to $mac')));
    } on PlatformException catch (e) {
      // @TODO handle error during connection
      print("Failed to connect: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.message}')),
      );
    }
    hideLoading(context);
  }

  Future<List<String>?> getSensorData() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getSensorData');
      print("Got sensor data {$result}");
      return List<String>.from(result);
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
      return List.empty();
    }
  }
}
