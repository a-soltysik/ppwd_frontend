import 'package:flutter/services.dart';

class PlatformRepository {
  static const platform = MethodChannel('flutter.native/sensor/imperative');

  Future<void> connectToDevice(String mac) async {
    try {
      final String result = await platform.invokeMethod('connectToSensorService', {'macAddress': mac});
      print(result); // "Connected to <mac>"
    } on PlatformException catch (e) {
      // @TODO handle error during connection
      print("Failed to connect: ${e.message}");
    }
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
