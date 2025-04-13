import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../core/models/board.dart';
import '../../core/utils/utils.dart';

class BoardService {
  final String _apiUrl = getApiUrl();
  final String _apiKey = getApiKey();
  static const _requestTimeout = Duration(seconds: 10);

  Future<bool> sendSensorData(Board boardData) async {
    final Uri url = Uri.parse('$_apiUrl/api/measurements');

    try {
      log('Sending data to $_apiUrl: ${jsonEncode(boardData)}');

      final http.Response response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'X-Api-Key': _apiKey},
            body: jsonEncode(boardData),
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
