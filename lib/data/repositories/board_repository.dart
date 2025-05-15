import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optional/optional.dart';
import 'package:ppwd_frontend/core/utils/error_handler.dart';
import 'package:ppwd_frontend/core/utils/logger.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';

import '../../core/models/measurement.dart';

typedef ConnectionSuccessCallback =
    void Function(
      String macAddress,
      int batteryLevel,
      List<String> activeSensors,
    );
typedef DisconnectionCallback = void Function(String reason);

class BoardRepository {
  static const _channel = MethodChannel('flutter.native/board');
  static const _connectToBoardFunction = 'connectToBoard';
  static const _disconnectFromBoardFunction = 'disconnectFromBoard';
  static const _getModuleDataFunction = 'getModulesData';
  static const _getBatteryLevelFunction = 'getBatteryLevel';
  static const _handleBoardDisconnection = 'handleBoardDisconnection';
  static const _onConnectionSuccess = 'onConnectionSuccess';

  ConnectionSuccessCallback? _onConnectionSuccessCallback;
  DisconnectionCallback? _onDisconnectionCallback;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void setupConnectionHandlers(
    BuildContext? context, {
    required ConnectionSuccessCallback onConnected,
    required DisconnectionCallback onDisconnected,
  }) {
    _onConnectionSuccessCallback = onConnected;
    _onDisconnectionCallback = onDisconnected;

    _setupMethodCallHandler(context);
  }

  void _setupMethodCallHandler(BuildContext? context) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _onConnectionSuccess:
          _handleConnectionSuccess(call.arguments, context);
          break;
        case _handleBoardDisconnection:
          _handleDisconnection(call.arguments, context);
          break;
      }
      return null;
    });
  }

  void _handleConnectionSuccess(dynamic arguments, BuildContext? context) {
    if (_onConnectionSuccessCallback == null) return;

    final args = arguments as Map<dynamic, dynamic>;
    final macAddress = args['macAddress'] as String? ?? '';
    final batteryLevel = args['batteryLevel'] as int? ?? 0;
    final sensorsList = args['activeSensors'] as List<dynamic>? ?? [];
    final activeSensors = sensorsList.map((s) => s.toString()).toList();

    _saveConnectionData(macAddress, activeSensors);
    _onConnectionSuccessCallback!(macAddress, batteryLevel, activeSensors);
  }

  void _saveConnectionData(
    String macAddress,
    List<String> activeSensors,
  ) async {
    Logger.i(
      'Connection successful to $macAddress with ${activeSensors.length} active sensors',
    );

    _isConnected = true;
    await UserSimplePreferences.setMacAddress(macAddress);
  }

  void _handleDisconnection(dynamic arguments, BuildContext? context) async {
    final reason = arguments as String? ?? 'Unknown reason';
    Logger.i('Device disconnected: $reason');

    _isConnected = false;

    if (context != null && context.mounted) {
      ErrorHandler.showSuccessMessage(context, 'Device disconnected: $reason');
    }

    if (_onDisconnectionCallback != null) {
      _onDisconnectionCallback!(reason);
    }
  }

  Future<Optional<bool>> connectToDevice(
    BuildContext? context,
    String mac,
  ) async {
    return ErrorHandler.handleMethodCall(_connectToBoardFunction, () async {
      await _channel.invokeMethod(_connectToBoardFunction, {'macAddress': mac});

      ErrorHandler.showSuccessMessage(context, 'Attempting to connect to $mac');

      return true;
    }, context);
  }

  Future<Optional<Map<String, List<Measurement>>>> getModuleData(
    BuildContext? context,
  ) async {
    return ErrorHandler.handleMethodCall(_getModuleDataFunction, () async {
      final Map<Object?, Object?> rawData = await _channel.invokeMethod(
        _getModuleDataFunction,
      );

      if (rawData.isEmpty) {
        return <String, List<Measurement>>{};
      }

      return _parseModuleData(rawData);
    }, context);
  }

  Map<String, List<Measurement>> _parseModuleData(
    Map<Object?, Object?> rawData,
  ) {
    return rawData.map((key, value) {
      List<Measurement> parsedList =
          (value as List)
              .map((item) => Measurement(item[0] as String, item[1] as int))
              .toList();
      return MapEntry(key as String, parsedList);
    });
  }

  Future<Optional<int>> getBatteryLevel(BuildContext? context) async {
    return ErrorHandler.handleMethodCall(_getBatteryLevelFunction, () async {
      return await _channel.invokeMethod(_getBatteryLevelFunction);
    }, context);
  }

  Future<void> disconnectFromDevice(BuildContext? context) async {
    try {
      await _channel.invokeMethod(_disconnectFromBoardFunction);
      _isConnected = false;

      ErrorHandler.showSuccessMessage(context, 'Disconnected from device');
    } catch (e) {
      Logger.e("Error disconnecting", error: e);

      if (context != null && context.mounted) {
        ErrorHandler.showSuccessMessage(context, 'Error disconnecting: $e');
      }
    }
  }
}
