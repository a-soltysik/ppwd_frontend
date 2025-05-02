import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/board.dart';
import '../../data/repositories/board_repository.dart';
import '../../data/services/board_service.dart';

typedef BatteryUpdateCallback = void Function(int batteryLevel);

class DataCollectionService {
  static final DataCollectionService _instance =
      DataCollectionService._internal();

  factory DataCollectionService() => _instance;

  DataCollectionService._internal();

  Timer? _dataTimer;
  bool _isCollecting = false;

  static const _collectionInterval = AppConstants.dataCollectionInterval;

  final BoardService _boardService = BoardService();

  static const String _prefCollectionStateKey =
      AppConstants.prefCollectionState;
  static const String _prefDeviceMacKey = AppConstants.prefDeviceMac;

  Future<void> startDataCollection(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    BatteryUpdateCallback onBatteryUpdated,
  ) async {
    await stopDataCollection();

    log('Starting data collection for device: $macAddress');
    _isCollecting = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCollectionStateKey, true);
    await prefs.setString(_prefDeviceMacKey, macAddress);

    _scheduleDataCollection(context, repository, macAddress, onBatteryUpdated);

    await collectAndSendData(context, repository, macAddress, onBatteryUpdated);
  }

  void _scheduleDataCollection(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    BatteryUpdateCallback onBatteryUpdated,
  ) {
    _dataTimer = Timer.periodic(_collectionInterval, (timer) {
      collectAndSendData(context, repository, macAddress, onBatteryUpdated);
    });
  }

  Future<void> stopDataCollection() async {
    _isCollecting = false;
    if (_dataTimer != null) {
      log('Stopping data collection');
      _dataTimer?.cancel();
      _dataTimer = null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCollectionStateKey, false);
  }

  Future<bool> isCollecting() async {
    if (_isCollecting) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefCollectionStateKey) ?? false;
  }

  bool isCollectingSync() => _isCollecting;

  Future<void> collectAndSendData(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    BatteryUpdateCallback onBatteryUpdated,
  ) async {
    log("Collecting data for device: $macAddress");

    try {
      final measurementsOptional = await repository.getModuleData(context);

      measurementsOptional.ifPresent((measurements) async {
        if (measurements.isNotEmpty) {
          log("Found data for sensors: ${measurements.keys.join(', ')}");

          // Send data to the backend
          final success = await _boardService.sendSensorData(
            Board(macAddress, measurements),
          );

          log(
            success
                ? 'Successfully sent data to backend'
                : 'Failed to send data to backend',
          );
        } else {
          log("No sensor data available");
        }

        await _updateBatteryLevel(context, repository, onBatteryUpdated);
      });
    } catch (e) {
      log("Error collecting data: $e");
    }
  }

  Future<void> _updateBatteryLevel(
    BuildContext? context,
    BoardRepository repository,
    BatteryUpdateCallback onBatteryUpdated,
  ) async {
    final batteryOptional = await repository.getBatteryLevel(context);
    batteryOptional.ifPresent(onBatteryUpdated);
  }
}
