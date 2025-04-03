import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:optional/optional.dart';

class Measurement {
  final String data;
  final int timestamp;

  Measurement(this.data, this.timestamp);

  @override
  String toString() {
    return '{data: ${json.decode(data)}, timestamp: $timestamp}';
  }

  Map<String, dynamic> toJson() {
    return {'data': json.decode(data), 'timestamp': timestamp};
  }
}

class Board {
  final String macAddress;
  final Map<String, List<Measurement>> measurements;

  Board(this.macAddress, this.measurements);

  @override
  String toString() {
    return '{macAddress: $macAddress, measurements: ${jsonEncode(_serializeMeasurements())}}';
  }

  Map<String, dynamic> toJson() {
    return {'macAddress': macAddress, 'measurements': _serializeMeasurements()};
  }

  List<Map<String, dynamic>> _serializeMeasurements() {
    return measurements.entries.map((entry) {
      return {
        'type': entry.key,
        'payload': entry.value.map((m) => m.toJson()).toList(),
      };
    }).toList();
  }
}

class PlatformRepository {
  static const _channel = MethodChannel('flutter.native/board');
  static const _connectToBoardFunction = 'connectToBoard';
  static const _getModuleDataFunction = 'getModulesData';
  static const _getBatteryLevelFunction = 'getBatteryLevel';
  static const _handleBoardDisconnection = 'handleBoardDisconnection';
  final String _macAddress;

  PlatformRepository(this._macAddress) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == _handleBoardDisconnection) {
        //@TODO reconnect to the board without infinite loop
        log("Board is disconnected");
        connectToDevice();
      }
    });
  }

  Future<Optional<T>> onSuccess<T>(
    String methodName,
    Future<T?> Function() operation,
  ) async {
    try {
      return Optional.ofNullable(await operation());
    } on PlatformException catch (e) {
      log("Error: ${e.code}, ${e.message}");
    } on MissingPluginException {
      log("Method $methodName is not implemented!");
    }
    return Optional.empty();
  }

  Future<Optional<bool>> connectToDevice() async {
    return onSuccess(_connectToBoardFunction, () async {
      await _channel.invokeMethod(_connectToBoardFunction, {
        'macAddress': _macAddress,
      });
      return true;
    });
  }

  Future<Optional<Map<String, List<Measurement>>>> getModuleData() async {
    return onSuccess(_getModuleDataFunction, () async {
      final Map<Object?, Object?> rawData = await _channel.invokeMethod(
        _getModuleDataFunction,
      );

      return rawData.map((key, value) {
        List<Measurement> parsedList =
            (value as List)
                .map((item) => Measurement(item[0] as String, item[1] as int))
                .toList();
        return MapEntry(key as String, parsedList);
      });
    });
  }

  Future<Optional<int>> getBatteryLevel() async {
    return onSuccess(_getBatteryLevelFunction, () async {
      return await _channel.invokeMethod(_getBatteryLevelFunction);
    });
  }
}
