import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/models/board.dart';

class BoardService {
  final String _apiUrl = AppConstants.apiBaseUrl;
  final String _apiKey = AppConstants.apiKey;
  static const _requestTimeout = AppConstants.apiTimeout;

  Future<bool> sendSensorData(Board boardData) async {
    final Uri url = Uri.parse('$_apiUrl/api/measurements');

    try {
      final jsonData = jsonEncode(boardData);
      log('Sending data to $_apiUrl: $jsonData');

      final http.Response response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'X-Api-Key': _apiKey},
            body: jsonData,
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 201) {
        log('Data sent successfully');
        return true;
      } else {
        log('Error sending data: HTTP ${response.statusCode}');
        log('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      log('Exception sending sensor data: $e');
      return false;
    }
  }
}
