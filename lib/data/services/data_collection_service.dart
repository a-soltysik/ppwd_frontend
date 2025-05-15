import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/board.dart';
import '../../core/network/connection_status_provider.dart';
import '../../core/utils/logger.dart';
import '../../data/repositories/board_repository.dart';
import '../../data/services/board_service.dart';

typedef BatteryUpdateCallback = void Function(int batteryLevel);
typedef ConnectionStatusCallback =
    void Function(bool isConnected, int cachedCount);

class DataCollectionService {
  static final DataCollectionService _instance =
      DataCollectionService._internal();

  factory DataCollectionService() => _instance;

  DataCollectionService._internal();

  Timer? _dataTimer;
  bool _isCollecting = false;
  ConnectionStatusCallback? _connectionStatusCallback;
  StreamSubscription<ConnectionStatus>? _connectionStatusSubscription;

  static const _collectionInterval = AppConstants.dataCollectionInterval;

  final BoardService _boardService = BoardService();
  final ConnectionStatusProvider _connectionProvider =
      ConnectionStatusProvider();

  void setConnectionStatusCallback(ConnectionStatusCallback callback) {
    _connectionStatusCallback = callback;

    _notifyConnectionStatus();
    _monitorConnectionStatus();
  }

  void _notifyConnectionStatus() {
    _connectionStatusCallback?.call(
      _connectionProvider.isConnected,
      _connectionProvider.cachedRequestsCount,
    );
  }

  void _monitorConnectionStatus() {
    _connectionStatusSubscription?.cancel();

    _connectionStatusSubscription = _connectionProvider.statusStream.listen(
      (status) {
        Logger.i(
          'Network: connected=${status.isConnected}, cached=${status.cachedRequestsCount}',
        );

        _connectionStatusCallback?.call(
          status.isConnected,
          status.cachedRequestsCount,
        );

        if (status.isConnected && status.cachedRequestsCount > 0) {
          Logger.i('Connection restored - sending cached data');
          sendCachedData();
        }
      },
      onError: (error) {
        Logger.e('Connection status error', error: error);
      },
    );
  }

  Future<void> startDataCollection(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    BatteryUpdateCallback onBatteryUpdated,
  ) async {
    await stopDataCollection();

    Logger.i('Starting data collection for device: $macAddress');
    _isCollecting = true;

    _scheduleDataCollection(context, repository, macAddress, onBatteryUpdated);

    await collectAndSendData(context, repository, macAddress, onBatteryUpdated);

    if (_connectionProvider.isConnected &&
        _connectionProvider.cachedRequestsCount > 0) {
      await sendCachedData();
    }
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
      Logger.i('Stopping data collection');
      _dataTimer?.cancel();
      _dataTimer = null;
    }

    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = null;
  }

  bool isCollecting() => _isCollecting;

  Future<void> collectAndSendData(
    BuildContext? context,
    BoardRepository repository,
    String macAddress,
    BatteryUpdateCallback onBatteryUpdated,
  ) async {
    Logger.d("Collecting data for device: $macAddress");

    try {
      final measurementsOptional = await repository.getModuleData(context);

      measurementsOptional.ifPresent((measurements) async {
        if (measurements.isNotEmpty) {
          Logger.d("Found data for sensors: ${measurements.keys.join(', ')}");

          final success = await _boardService.sendSensorData(
            Board(macAddress, measurements),
          );

          Logger.i(
            success
                ? 'Successfully processed sensor data'
                : 'Failed to process sensor data',
          );

          if (_connectionProvider.isConnected &&
              _connectionProvider.cachedRequestsCount > 0) {
            sendCachedData();
          }
        } else {
          Logger.d("No sensor data available");
        }

        await _updateBatteryLevel(context, repository, onBatteryUpdated);
      });
    } catch (e) {
      Logger.e("Error collecting data", error: e);
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

  Future<int> sendCachedData() async {
    if (!_connectionProvider.isConnected) {
      Logger.w('Cannot send cached data: No internet connection');
      return 0;
    }

    Logger.i('Attempting to send cached data...');
    return await _boardService.sendCachedData();
  }
}
