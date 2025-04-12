import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../repository/platform_repository.dart';

class SensorService {
  static const String apiKey = 'apikey';

  Future<void> sendSensorData(Board boardData) async {
    final Uri url = Uri.parse('http://156.17.41.203:55555/api/measurements');

    try {
      final http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-Api-Key': apiKey},
        body: jsonEncode(boardData),
      );
      log(jsonEncode(boardData));

      if (response.statusCode == 201) {
        print('Data sent successfully');
      } else {
        print('Error: ${response.statusCode}');
      }
      print('Response body: ${response.body}');
    } catch (e) {
      print('Exception: $e');
    }
  }
}
