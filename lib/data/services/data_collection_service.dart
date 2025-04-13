import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../core/models/board.dart';
import '../../data/repositories/board_repository.dart';
import '../../data/services/board_service.dart';

class DataCollectionService {
  static final DataCollectionService _instance =
      DataCollectionService._internal();

  factory DataCollectionService() => _instance;

  DataCollectionService._internal();

  Timer? _dataTimer;
  static const _collectionInterval = Duration(seconds: 60);

  final BoardService _boardService = BoardService();

  void startDataCollection(
    BuildContext context,
    BoardRepository repository,
    String macAddress,
    Function(int) onBatteryUpdated,
  ) {
    stopDataCollection();

    log('Starting data collection for device: $macAddress');

    _dataTimer = Timer.periodic(_collectionInterval, (timer) {
      collectAndSendData(context, repository, macAddress, onBatteryUpdated);
    });

    collectAndSendData(context, repository, macAddress, onBatteryUpdated);
  }

  void stopDataCollection() {
    if (_dataTimer != null) {
      log('Stopping data collection');
      _dataTimer?.cancel();
      _dataTimer = null;
    }
  }

  Future<void> collectAndSendData(
    BuildContext context,
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
              await _boardService.sendSensorData(
                Board(macAddress, measurements),
              );

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
    }
  }
}
