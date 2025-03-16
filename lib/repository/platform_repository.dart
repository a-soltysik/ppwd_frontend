import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
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

  bool isLoading = false;
  showLoading(BuildContext context) {
    isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  hideLoading(BuildContext context) {
    if (!isLoading) return;

    isLoading = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<Optional<T>> onSuccess<T>(
    String methodName,
    Future<T?> Function() operation,
    BuildContext context,
  ) async {
    try {
      return Optional.ofNullable(await operation());
    } on PlatformException catch (e) {
      log("Error: ${e.code}, ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.message}')),
      );
    } on MissingPluginException {
      log("Method $methodName is not implemented!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Method $methodName is not implemented!')),
      );
    }

    return Optional.empty();
  }

  Future<Optional<bool>> connectToDevice(
    BuildContext context,
    String mac,
  ) async {
    showLoading(context);
    var result = onSuccess(_connectToBoardFunction, () async {
      await _channel.invokeMethod(_connectToBoardFunction, {
        'macAddress': _macAddress,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected successfully to $mac')));

      return true;
    }, context);
    hideLoading(context);
    return result;
  }

  Future<Optional<Map<String, List<Measurement>>>> getModuleData(
    BuildContext context,
  ) async {
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
    }, context);
  }

  Future<Optional<int>> getBatteryLevel(BuildContext context) async {
    return onSuccess(_getBatteryLevelFunction, () async {
      return await _channel.invokeMethod(_getBatteryLevelFunction);
    }, context);
  }
}
