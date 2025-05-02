import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ppwd_frontend/core/utils/format_utils.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/data_collection_service.dart';
import '../../../data/services/foreground_service_manager.dart';
import '../state/connection_state_manager.dart';
import '../widgets/active_sensor_widget.dart';
import '../widgets/app_info_card.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_status_card.dart';

class BoardConnectionPage extends StatefulWidget {
  const BoardConnectionPage({super.key});

  @override
  _BoardConnectionPageState createState() => _BoardConnectionPageState();
}

class _BoardConnectionPageState extends State<BoardConnectionPage>
    with AutomaticKeepAliveClientMixin {
  final _repository = BoardRepository();
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _connectionManager = ConnectionStateManager();
  final _serviceManager = ForegroundServiceManager();

  int _currentBatteryLevel = 0;

  @override
  void initState() {
    super.initState();

    _connectionManager.addListener(_updateUI);

    _setupServiceCallbacks();
    _initializeRepository();
  }

  void _setupServiceCallbacks() {
    _serviceManager.setCallbacks(
      onBatteryUpdate: _handleBatteryUpdate,
      onDisconnect: _handleServiceDisconnect,
    );
  }

  void _initializeRepository() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _repository.setupConnectionHandlers(
        context,
        onConnected: _handleConnectionSuccess,
        onDisconnected: _handleDisconnection,
      );

      final lastMac = UserSimplePreferences.getMacAddress();
      if (lastMac != null) {
        _controller.text = lastMac;
      }
    });
  }

  void _handleBatteryUpdate(int batteryLevel) {
    setState(() {
      _currentBatteryLevel = batteryLevel;
      _connectionManager.setBattery(
        FormatUtils.formatBatteryLevel(batteryLevel),
      );
    });
  }

  void _handleServiceDisconnect() {
    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Device disconnected by service");
    _connectionManager.setBattery(FormatUtils.formatBatteryLevel(-1));
    _connectionManager.setActiveSensors([]);
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleConnectionSuccess(
    String macAddress,
    int batteryLevel,
    List<String> activeSensors,
  ) {
    _connectionManager.setActiveSensors(activeSensors);
    _connectionManager.setConnected(true);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Connected to $macAddress");
    _connectionManager.setConnectedDevice(macAddress);
    _connectionManager.setBattery(FormatUtils.formatBatteryLevel(batteryLevel));

    _currentBatteryLevel = batteryLevel;

    _startBackgroundServices(macAddress, batteryLevel);
  }

  Future<void> _startBackgroundServices(
    String macAddress,
    int batteryLevel,
  ) async {
    final success = await _serviceManager.startService(macAddress);
    if (success) {
      log("Foreground service started successfully");

      await DataCollectionService().startDataCollection(
        context,
        _repository,
        macAddress,
        _handleBatteryUpdate,
      );
    } else {
      log("Failed to start foreground service");
    }
  }

  void _handleDisconnection(String reason) {
    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Device disconnected: $reason");
    _connectionManager.setBattery(FormatUtils.formatBatteryLevel(-1));
    _connectionManager.setActiveSensors([]);

    _serviceManager.stopService();
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectionManager.removeListener(_updateUI);
    super.dispose();
  }

  Future<void> _connect(String mac) async {
    _connectionManager.setConnectionStatus("Connecting...");
    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(true);
    _connectionManager.setActiveSensors([]);

    final result = await _repository.connectToDevice(context, mac);

    if (!result.isPresent) {
      _connectionManager.setConnectionStatus("Failed to connect to $mac");
      _connectionManager.setConnected(false);
      _connectionManager.setConnecting(false);
    }
  }

  void _disconnect() {
    _serviceManager.stopService();

    if (_connectionManager.isConnected || _connectionManager.isConnecting) {
      _repository.disconnectFromDevice(context);
    }

    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Disconnected");
    _connectionManager.setBattery(FormatUtils.formatBatteryLevel(-1));
    _connectionManager.setActiveSensors([]);

    UserSimplePreferences.removeMacAddress();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isConnected = _connectionManager.isConnected;
    final isConnecting = _connectionManager.isConnecting;
    final connectionStatus = _connectionManager.connectionStatus;
    final battery = _connectionManager.battery;
    final activeSensors = _connectionManager.activeSensors;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Connection"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textLightColor,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInfoCard(),

              const SizedBox(height: 16),

              ConnectionStatusCard(
                isConnected: isConnected,
                isConnecting: isConnecting,
                connectionStatus: connectionStatus,
                battery: battery,
                batteryLevel: _currentBatteryLevel,
                isServiceRunning: _serviceManager.isRunning,
              ),

              const SizedBox(height: 24),

              ActiveSensorsWidget(
                activeSensors: activeSensors,
                isConnected: isConnected,
              ),

              const SizedBox(height: 24),

              ConnectionForm(
                controller: _controller,
                isConnected: isConnected,
                isConnecting: isConnecting,
                formKey: _formKey,
                onConnect: _connect,
                onDisconnect: _disconnect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
