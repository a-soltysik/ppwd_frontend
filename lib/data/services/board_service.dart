import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/board.dart';
import '../../core/network/connection_status_provider.dart';
import '../../core/utils/logger.dart';

class BoardService {
  final String _apiUrl = AppConstants.apiBaseUrl;
  final String _apiKey = AppConstants.apiKey;
  static const _requestTimeout = AppConstants.apiTimeout;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ConnectionStatusProvider _connectionProvider =
      ConnectionStatusProvider();

  Future<bool> sendSensorData(Board boardData) async {
    await _connectionProvider.checkConnectivity();

    if (!_connectionProvider.isConnected) {
      Logger.i('Internet connection not available - caching data for later');
      return _cacheRequest(boardData);
    }

    try {
      final jsonData = jsonEncode(boardData);
      Logger.d('Sending data to $_apiUrl: $jsonData');

      final http.Response response = await http
          .post(
            Uri.parse('$_apiUrl/api/measurements'),
            headers: {'Content-Type': 'application/json', 'X-Api-Key': _apiKey},
            body: jsonData,
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 201) {
        Logger.i('Data sent successfully');
        return true;
      } else {
        Logger.w('Error sending data: HTTP ${response.statusCode}');
        Logger.w('Response body: ${response.body}');

        return _cacheRequest(boardData);
      }
    } catch (e) {
      Logger.e('Exception sending sensor data', error: e);

      return _cacheRequest(boardData);
    }
  }

  Future<bool> _cacheRequest(Board boardData) async {
    try {
      final jsonData = jsonEncode(boardData);
      var deviceId = boardData.macAddress;

      var timestamp = DateTime.now().millisecondsSinceEpoch;
      const typeId = "sensor_data";

      Logger.i('--------------------------------');
      Logger.i('CACHING DATA FOR LATER SENDING:');
      Logger.i('Device: $deviceId');
      Logger.i('Timestamp: $timestamp');
      Logger.d('Data: $jsonData');
      Logger.i('--------------------------------');

      await _databaseHelper.insertCachedRequest(
        requestBody: jsonData,
        deviceId: deviceId,
        timestamp: timestamp,
        typeId: typeId,
      );

      int cachedCount = await _databaseHelper.getCachedRequestsCount();
      _connectionProvider.updateCachedRequestsCount(cachedCount);

      Logger.i('Cached successfully. Total: $cachedCount');
      return true;
    } catch (e) {
      Logger.e('Cache error', error: e);
      return false;
    }
  }

  Future<int> sendCachedData() async {
    await _connectionProvider.checkConnectivity();

    if (!_connectionProvider.isConnected) {
      Logger.w('Cannot send cached data: No internet connection');
      return 0;
    }

    try {
      int sentCount = 0;
      final cachedRequests = await _databaseHelper.getCachedRequests(limit: 50);

      if (cachedRequests.isEmpty) {
        Logger.i('No cached requests to send');
        return 0;
      }

      Logger.i('Sending ${cachedRequests.length} cached requests');
      final url = Uri.parse('$_apiUrl/api/measurements');

      for (var request in cachedRequests) {
        try {
          final requestId = request['id'] as int;
          final requestBody = request['request_body'] as String;

          Logger.d('Sending cached request ID: $requestId');
          Logger.d('Request body: $requestBody');

          final response = await http
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'X-Api-Key': _apiKey,
                },
                body: requestBody,
              )
              .timeout(_requestTimeout);

          if (response.statusCode == 201) {
            Logger.i('Sent request with ID: $requestId');
            await _databaseHelper.deleteCachedRequest(requestId);
            sentCount++;
          } else {
            Logger.w(
              'Error sending cached request: HTTP ${response.statusCode}',
            );
            Logger.w('Response body: ${response.body}');

            if (response.statusCode >= 500) {
              Logger.w(
                'Server error detected, will retry remaining requests later',
              );
              break;
            }

            if (response.statusCode >= 400 && response.statusCode < 500) {
              Logger.w('Client error detected, removing invalid request');
              await _databaseHelper.deleteCachedRequest(requestId);
            }
          }
        } catch (e) {
          Logger.e('Exception sending cached request', error: e);
          break;
        }
      }

      int remainingCount = await _databaseHelper.getCachedRequestsCount();
      _connectionProvider.updateCachedRequestsCount(remainingCount);

      Logger.i('Sent $sentCount cached requests. Remaining: $remainingCount');
      return sentCount;
    } catch (e) {
      Logger.e('Error in sendCachedData', error: e);
      return 0;
    }
  }
}
