import 'package:flutter/services.dart';

import '../../core/utils/logger.dart';
import '../repositories/board_repository.dart';
import 'data_collection_service.dart';

typedef BatteryUpdateCallback = void Function(int batteryLevel);
typedef DisconnectCallback = void Function();

class ForegroundServiceManager {
  static const _channel = MethodChannel('flutter.native/foreground_service');
  static final _instance = ForegroundServiceManager._();

  factory ForegroundServiceManager() => _instance;

  ForegroundServiceManager._() {
    _setupMethodCallHandler();
  }

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  BatteryUpdateCallback? _onBatteryUpdate;
  DisconnectCallback? _onDisconnect;

  void setCallbacks({
    BatteryUpdateCallback? onBatteryUpdate,
    DisconnectCallback? onDisconnect,
  }) {
    _onBatteryUpdate = onBatteryUpdate;
    _onDisconnect = onDisconnect;
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDataAvailable':
          await _handleDataAvailable(call.arguments);
          break;
        case 'onDisconnect':
          await _handleDisconnect();
          break;
      }
    });
  }

  Future<void> _handleDataAvailable(dynamic arguments) async {
    final args = arguments as Map?;
    if (args == null) return;

    final hasNewData = args['hasNewData'] as bool? ?? false;
    if (!hasNewData) return;

    final macAddress = args['macAddress'] as String? ?? '';
    if (macAddress.isEmpty) return;

    final batteryLevel = args['batteryLevel'] as int? ?? 0;

    Logger.i("Received data from foreground service, collecting...");

    if (_onBatteryUpdate != null) {
      _onBatteryUpdate!(batteryLevel);
    }

    final dataCollectionService = DataCollectionService();

    await dataCollectionService.collectAndSendData(
      null,
      BoardRepository(),
      macAddress,
      (batteryLevel) {
        if (_onBatteryUpdate != null) {
          _onBatteryUpdate!(batteryLevel);
        }
      },
    );

    if (hasNewData) {
      await dataCollectionService.sendCachedData();
    }
  }

  Future<void> _handleDisconnect() async {
    await DataCollectionService().stopDataCollection();
    _isRunning = false;

    if (_onDisconnect != null) {
      _onDisconnect!();
    }
  }

  Future<bool> startService(String macAddress) async {
    try {
      final result = await _channel.invokeMethod<bool>('startService', {
        'macAddress': macAddress,
      });
      _isRunning = result ?? false;
      return _isRunning;
    } on PlatformException catch (e) {
      Logger.e('Error starting foreground service', error: e.message);
      return false;
    }
  }

  Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      _isRunning = !(result ?? false);
      return !_isRunning;
    } on PlatformException catch (e) {
      Logger.e('Error stopping foreground service', error: e.message);
      return false;
    }
  }
}
