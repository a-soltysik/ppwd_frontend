import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/board.dart';
import '../../core/network/connection_status_provider.dart';
import '../../core/utils/logger.dart';

class BoardService {
  final Dio _dio;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ConnectionStatusProvider _connectionProvider =
      ConnectionStatusProvider();

  BoardService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': AppConstants.apiKey,
        },
      ),
    );
  }

  Future<bool> sendSensorData(Board boardData) async {
    await _connectionProvider.checkConnectivity();

    if (!_connectionProvider.isConnected) {
      Logger.i('Internet connection not available - caching data for later');
      return _cacheRequest(boardData);
    }

    try {
      await _dio.post('/api/measurements', data: boardData.toJson());
      Logger.i('Data sent successfully');
      return true;
    } on DioException catch (e) {
      Logger.w(
        'Error sending data: ${e.response?.statusCode ?? 'No response'}',
      );
      return _cacheRequest(boardData);
    } catch (e) {
      Logger.e('Exception sending sensor data', error: e);
      return _cacheRequest(boardData);
    }
  }

  Future<bool> _cacheRequest(Board boardData) async {
    try {
      final jsonData = jsonEncode(boardData.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _databaseHelper.insertCachedRequest(
        requestBody: jsonData,
        deviceId: boardData.macAddress,
        timestamp: timestamp,
        typeId: "sensor_data",
      );

      final cachedCount = await _databaseHelper.getCachedRequestsCount();
      _connectionProvider.updateCachedRequestsCount(cachedCount);

      Logger.i('Data cached successfully. Total: $cachedCount');
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

      for (var request in cachedRequests) {
        final requestId = request['id'] as int;
        final requestBody = request['request_body'] as String;

        try {
          await _dio.post('/api/measurements', data: jsonDecode(requestBody));
          await _databaseHelper.deleteCachedRequest(requestId);
          sentCount++;
          Logger.i('Sent cached request ID: $requestId');
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode ?? 0;

          if (statusCode >= 500) {
            Logger.w('Server error, will retry remaining requests later');
            break;
          } else if (statusCode >= 400 && statusCode < 500) {
            Logger.w('Client error, removing invalid request');
            await _databaseHelper.deleteCachedRequest(requestId);
          }
        }
      }

      final remainingCount = await _databaseHelper.getCachedRequestsCount();
      _connectionProvider.updateCachedRequestsCount(remainingCount);

      Logger.i('Sent $sentCount cached requests. Remaining: $remainingCount');
      return sentCount;
    } catch (e) {
      Logger.e('Error in sendCachedData', error: e);
      return 0;
    }
  }
}
