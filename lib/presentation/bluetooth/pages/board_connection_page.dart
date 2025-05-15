import 'package:flutter/material.dart';
import 'package:ppwd_frontend/core/utils/format_utils.dart';
import 'package:ppwd_frontend/core/utils/logger.dart';
import 'package:ppwd_frontend/core/utils/scan_for_available_devices.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';

import '../../../core/network/connection_status_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/data_collection_service.dart';
import '../../../data/services/foreground_service_manager.dart';
import '../state/connection_state_manager.dart';
import '../widgets/active_sensor_widget.dart';
import '../widgets/app_info_card.dart';
import '../widgets/connection_actions_widget.dart';
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
  final _dataCollectionService = DataCollectionService();
  final _connectionProvider = ConnectionStatusProvider();

  int _currentBatteryLevel = 0;
  bool _isNetworkConnected = true;
  int _cachedRequestsCount = 0;
  bool _isSendingCachedData = false;

  @override
  void initState() {
    super.initState();

    _connectionManager.addListener(_updateUI);
    _setupConnectivityMonitoring();
    _setupServiceCallbacks();
    _initializeRepository();
    _setupConnectionStatusListener();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _connectionProvider.checkConnectivity();
      _checkAndRestorePreviousConnection();
    });
  }

  void _setupConnectivityMonitoring() {
    _connectionProvider.addListener(() {
      if (mounted) {
        setState(() {
          _isNetworkConnected = _connectionProvider.isConnected;
          _cachedRequestsCount = _connectionProvider.cachedRequestsCount;
        });

        if (_isNetworkConnected &&
            !_isSendingCachedData &&
            _cachedRequestsCount > 0) {
          _attemptToSendCachedData();
        }
      }
    });
  }

  void _setupConnectionStatusListener() {
    _dataCollectionService.setConnectionStatusCallback((
      isConnected,
      cachedCount,
    ) {
      if (mounted) {
        setState(() {
          _isNetworkConnected = isConnected;
          _cachedRequestsCount = cachedCount;
        });
      }
    });
  }

  void _setupServiceCallbacks() {
    _serviceManager.setCallbacks(
      onBatteryUpdate: _handleBatteryUpdate,
      onDisconnect: _handleServiceDisconnect,
    );
  }

  void _initializeRepository() {
    _repository.setupConnectionHandlers(
      context,
      onConnected: _handleConnectionSuccess,
      onDisconnected: _handleDisconnection,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lastMac = UserSimplePreferences.getMacAddress();
      if (lastMac != null) {
        _controller.text = lastMac;
      }
    });
  }

  Future<void> _checkAndRestorePreviousConnection() async {
    final lastMac = UserSimplePreferences.getMacAddress();
    if (lastMac != null && lastMac.isNotEmpty) {
      Logger.i('Found previous connection to device: $lastMac');

      if (mounted) {
        setState(() {
          _controller.text = lastMac;
        });
      }
    }
  }

  void _handleBatteryUpdate(int batteryLevel) {
    if (mounted) {
      setState(() {
        _currentBatteryLevel = batteryLevel;
        _connectionManager.setBattery(
          FormatUtils.formatBatteryLevel(batteryLevel),
        );
      });
    }
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
      Logger.i("Foreground service started successfully");

      await _dataCollectionService.startDataCollection(
        context,
        _repository,
        macAddress,
        _handleBatteryUpdate,
      );

      if (_isNetworkConnected && _cachedRequestsCount > 0) {
        _attemptToSendCachedData();
      }
    } else {
      Logger.e("Failed to start foreground service");
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

  Future<void> _attemptToSendCachedData() async {
    if (_isSendingCachedData) {
      return;
    }

    if (!_isNetworkConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No internet connection available - cannot send cached data",
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_cachedRequestsCount <= 0) {
      return;
    }

    setState(() {
      _isSendingCachedData = true;
    });

    try {
      Logger.i('Sending cached data...');
      final sentCount = await _dataCollectionService.sendCachedData();

      if (sentCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sent $sentCount cached requests successfully"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.e('Error sending cached data', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCachedData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppTheme.backgroundColor,
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Device Connection"),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.textLightColor,
      actions: [
        ConnectionActionsWidget(
          isConnected: _connectionManager.isConnected,
          isConnecting: _connectionManager.isConnecting,
          isNetworkConnected: _isNetworkConnected,
          cachedRequestsCount: _cachedRequestsCount,
          isSendingCachedData: _isSendingCachedData,
          onSendCachedData: _attemptToSendCachedData,
        ),
      ],
    );
  }

  Widget _buildBody() {
    final isConnected = _connectionManager.isConnected;
    final isConnecting = _connectionManager.isConnecting;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppInfoCard(),

            const SizedBox(height: 16),

            ConnectionStatusCard(
              isConnected: isConnected,
              isConnecting: isConnecting,
              connectionStatus: _connectionManager.connectionStatus,
              battery: _connectionManager.battery,
              batteryLevel: _currentBatteryLevel,
              isServiceRunning: _serviceManager.isRunning,
              isNetworkConnected: _isNetworkConnected,
              cachedRequestsCount: _cachedRequestsCount,
            ),

            const SizedBox(height: 24),

            ActiveSensorsWidget(
              activeSensors: _connectionManager.activeSensors,
              isConnected: isConnected,
            ),

            const SizedBox(height: 24),
            if (!isConnected && !isConnecting)
              BluetoothDeviceSelector(
                onDeviceSelected: (macAddress) {
                  _controller.text = macAddress;
                  _connect;
                },
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
