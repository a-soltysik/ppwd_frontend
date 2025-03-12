import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ppwd_frontend/utils.dart';

class SensorService {
  Future<void> sendSensorData(List<String> sensorData) async {
    final Uri url = Uri.parse('$apiUrl/send/data');

    try {
      final http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sensorData),
      );

      if (response.statusCode == 200) {
        print('Data sent successfully');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }
}
