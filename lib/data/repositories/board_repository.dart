import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ppwd_frontend/bg_service.dart';
import 'package:optional/optional.dart';

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

  static const _loadingTimeout = Duration(seconds: 30);

  bool isLoading = false;
  Timer? _loadingTimer;
  ConnectionSuccessCallback? _onConnectionSuccessCallback;
  DisconnectionCallback? _onDisconnectionCallback;

  void setupConnectionHandlers(
    BuildContext context, {
    required ConnectionSuccessCallback onConnected,
    required DisconnectionCallback onDisconnected,
  }) {
    _onConnectionSuccessCallback = onConnected;
    _onDisconnectionCallback = onDisconnected;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _onConnectionSuccess:
          if (_onConnectionSuccessCallback != null) {
            final Map<dynamic, dynamic> args =
                call.arguments as Map<dynamic, dynamic>;
            final String macAddress = args['macAddress'] as String? ?? '';
            final int batteryLevel = args['batteryLevel'] as int? ?? 0;
            final List<dynamic> sensorsList =
                args['activeSensors'] as List<dynamic>? ?? [];
            final List<String> activeSensors =
                sensorsList.map((s) => s.toString()).toList();

            log(
              'Connection successful to $macAddress with ${activeSensors.length} active sensors',
            );

            // Update mac for background purpose
            final service = FlutterBackgroundService();
            service.invoke('updateMac', {"mac": macAddress});

            _onConnectionSuccessCallback!(
              macAddress,
              batteryLevel,
              activeSensors,
            );
          }
          break;
        case _handleBoardDisconnection:
          final reason = call.arguments as String? ?? 'Unknown reason';
          log('Device disconnected: $reason');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Device disconnected: $reason'),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (_onDisconnectionCallback != null) {
            _onDisconnectionCallback!(reason);
          }
          break;
      }
      return null;
    });
  }

  void showLoading(BuildContext context, [String message = 'Loading...']) {
    if (isLoading) return;

    isLoading = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );

    _loadingTimer = Timer(_loadingTimeout, () {
      hideLoading(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void hideLoading(BuildContext context) {
    if (!isLoading) return;

    _loadingTimer?.cancel();
    _loadingTimer = null;
    isLoading = false;

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<Optional<T>> onSuccess<T>(
    String methodName,
    Future<T?> Function() operation,
    BuildContext? context,
  ) async {
    try {
      return Optional.ofNullable(await operation());
    } on PlatformException catch (e) {
      log("PlatformException: ${e.code}, ${e.message}");

      String errorMessage = e.message ?? 'Unknown error';
      if (e.code == 'ALREADY_CONNECTING') {
        errorMessage =
            'Already attempting to connect to a device. Please wait.';
      } else if (e.code == 'INVALID_MAC') {
        errorMessage = 'Invalid MAC address format.';
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return Optional.empty();
    } on MissingPluginException {
      log("Method $methodName is not implemented!");

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Method $methodName is not implemented!'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return Optional.empty();
    } catch (e) {
      log("Unexpected error: $e");

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return Optional.empty();
    }
  }

  Future<Optional<bool>> connectToDevice(
    BuildContext context,
    String mac,
  ) async {
    showLoading(context, 'Connecting to device...');
    var result = await onSuccess(_connectToBoardFunction, () async {
      await _channel.invokeMethod(_connectToBoardFunction, {'macAddress': mac});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attempting to connect to $mac'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      return true;
    }, context);

    hideLoading(context);
    return result;
  }

  Future<Optional<Map<String, List<Measurement>>>> getModuleData(
    BuildContext? context,
  ) async {
    return onSuccess(_getModuleDataFunction, () async {
      final Map<Object?, Object?> rawData = await _channel.invokeMethod(
        _getModuleDataFunction,
      );

      if (rawData.isEmpty) {
        return <String, List<Measurement>>{};
      }

      return rawData.map((key, value) {
        List<Measurement> parsedList =
            (value as List)
                .map((item) => Measurement(item[0] as String, item[1] as int))
                .toList();
        return MapEntry(key as String, parsedList);
      });
    }, context);
  }

  Future<Optional<int>> getBatteryLevel(BuildContext? context) async {
    return onSuccess(_getBatteryLevelFunction, () async {
      return await _channel.invokeMethod(_getBatteryLevelFunction);
    }, context);
  }

  Future<void> disconnectFromDevice(BuildContext context) async {
    try {
      await _channel.invokeMethod(_disconnectFromBoardFunction);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from device'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      log("Error disconnecting: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
