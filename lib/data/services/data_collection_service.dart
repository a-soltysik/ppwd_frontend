import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/board.dart';
import '../../data/repositories/board_repository.dart';
import '../../data/services/board_service.dart';

class DataCollectionService {
  static final DataCollectionService _instance =
      DataCollectionService._internal();

  factory DataCollectionService() => _instance;

  DataCollectionService._internal();

  Timer? _dataTimer;
  bool _isCollecting = false;
  static const _collectionInterval = Duration(seconds: 60);
  static const _connectionCheckInterval = Duration(seconds: 15);

  final BoardService _boardService = BoardService();
  Timer? _connectionCheckTimer;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  static const String _prefCollectionStateKey = 'data_collection_active';
  static const String _prefDeviceMacKey = 'collection_device_mac';

  Future<void> startDataCollection(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    Function(int) onBatteryUpdated,
  ) async {
    stopDataCollection();

    log('Starting data collection for device: $macAddress');
    _isCollecting = true;

    // Save collection state to preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCollectionStateKey, true);
    await prefs.setString(_prefDeviceMacKey, macAddress);

    // Periodically collect and send data
    _dataTimer = Timer.periodic(_collectionInterval, (timer) {
      collectAndSendData(context, repository, macAddress, onBatteryUpdated);
    });

    // Add a separate timer to check connection status more frequently
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (
      timer,
    ) async {
      // Check battery to verify connection is still active
      final batteryOpt = await repository.getBatteryLevel(context);
      if (!batteryOpt.isPresent) {
        _failedAttempts++;
        log(
          'Connection check failed, attempt $_failedAttempts of $_maxFailedAttempts',
        );

        if (_failedAttempts >= _maxFailedAttempts) {
          log('Connection appears to be lost. Stopping data collection.');
          stopDataCollection();

          // Try to reconnect
          Timer(const Duration(seconds: 5), () {
            repository.connectToDevice(context, macAddress);
          });
        }
      } else {
        // Reset counter on successful check
        _failedAttempts = 0;
        onBatteryUpdated(batteryOpt.value);
      }
    });

    // Immediately collect data on start
    collectAndSendData(context, repository, macAddress, onBatteryUpdated);
  }

  Future<void> stopDataCollection() async {
    _isCollecting = false;
    if (_dataTimer != null) {
      log('Stopping data collection');
      _dataTimer?.cancel();
      _dataTimer = null;
    }

    if (_connectionCheckTimer != null) {
      _connectionCheckTimer?.cancel();
      _connectionCheckTimer = null;
    }

    _failedAttempts = 0;

    // Update preferences to reflect collection state
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCollectionStateKey, false);
  }

  Future<bool> isCollecting() async {
    if (_isCollecting) {
      return true;
    }

    // Double-check with stored preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefCollectionStateKey) ?? false;
  }

  // A synchronous version that doesn't check preferences
  bool isCollectingSync() {
    return _isCollecting;
  }

  Future<void> collectAndSendData(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    Function(int) onBatteryUpdated,
  ) async {
    try {
      final data = await repository.getModuleData(context);

      data
          .filter((list) => list.isNotEmpty)
          .ifPresent(
            (measurements) async {
              final success = await _boardService.sendSensorData(
                Board(macAddress, measurements),
              );

              if (success) {
                log('Successfully sent data to backend');
              } else {
                log('Failed to send data to backend');
              }

              (await repository.getBatteryLevel(context)).ifPresent((
                batteryLevel,
              ) {
                onBatteryUpdated(batteryLevel);
              });
            },
            orElse: () {
              log("No data received from board");
            },
          );
    } catch (e) {
      log("Error collecting data: $e");
      _failedAttempts++;

      if (_failedAttempts >= _maxFailedAttempts) {
        log('Too many data collection failures. Stopping collection.');
        stopDataCollection();
      }
    }
  }
}
