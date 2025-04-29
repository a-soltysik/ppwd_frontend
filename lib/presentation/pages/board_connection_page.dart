import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as bg;
import 'package:ppwd_frontend/data/repositories/board_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/board.dart';
import '../../core/utils/mac_address_utils.dart';
import '../../data/services/board_service.dart';
import '../state/connection_state_manager.dart';
import '../widgets/active_sensor_widget.dart';

class BoardConnectionPage extends StatefulWidget {
  const BoardConnectionPage({super.key});

  @override
  _BoardConnectionPageState createState() => _BoardConnectionPageState();
}

class _BoardConnectionPageState extends State<BoardConnectionPage>
    with AutomaticKeepAliveClientMixin {
  final _repository = BoardRepository();
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _connectionManager = ConnectionStateManager();

  Timer? _dataTimer;
  static const String PREFS_MAC_ADDRESS = "last_connected_mac";
  static const String PREFS_CONNECTION_ACTIVE = "connection_active";

  @override
  void initState() {
    super.initState();

    _connectionManager.addListener(_updateUI);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _repository.setupConnectionHandlers(
        context,
        onConnected: _handleConnectionSuccess,
        onDisconnected: _handleDisconnection,
      );

      // Try to restore the last connected MAC address
      final prefs = await SharedPreferences.getInstance();
      final lastMac = prefs.getString(PREFS_MAC_ADDRESS);
      final isActive = prefs.getBool(PREFS_CONNECTION_ACTIVE) ?? false;

      if (lastMac != null && isActive) {
        log('Restoring last connection to: $lastMac');
        _controller.text = lastMac;

        // Update UI to show we're attempting to connect
        _connectionManager.setConnectionStatus(
          "Restoring connection to $lastMac...",
        );
        _connectionManager.setConnecting(true);
      }
    });
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
    _connectionManager.setBattery(_formatBatteryLevel(batteryLevel));

    _startDataCollection(macAddress);

    // Ensure the background service knows about this connection
    final service = bg.FlutterBackgroundServiceAndroid();
    service.invoke('updateMac', {"mac": macAddress});
  }

  void _handleDisconnection(String reason) {
    _dataTimer?.cancel();
    _dataTimer = null;

    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Device disconnected: $reason");
    _connectionManager.setBattery(_formatBatteryLevel(-1));
    _connectionManager.setActiveSensors([]);
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _controller.dispose();
    _connectionManager.removeListener(_updateUI);
    super.dispose();
  }

  Future<void> connect(String mac) async {
    _dataTimer?.cancel();

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

  void _startDataCollection(String mac) {
    _dataTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (!_connectionManager.isConnected) {
        timer.cancel();
        return;
      }

      await _collectData(mac);
    });

    _collectData(mac);
  }

  Future<void> _collectData(String mac) async {
    try {
      final data = await _repository.getModuleData(context);
      data
          .filter((list) => list.isNotEmpty)
          .ifPresent(
            (value) async {
              await BoardService().sendSensorData(Board(mac, value));
              (await _repository.getBatteryLevel(context)).ifPresent((
                batteryLevel,
              ) {
                _connectionManager.setBattery(
                  _formatBatteryLevel(batteryLevel),
                );
              });
            },
            orElse: () {
              log("No data received from board");
            },
          );
    } catch (e) {
      log("Error collecting data: $e");
      if (_connectionManager.isConnected) {
        _connectionManager.setConnectionStatus("Error: $e");
      }
    }
  }

  void disconnect() {
    _dataTimer?.cancel();
    _dataTimer = null;

    if (_connectionManager.isConnected || _connectionManager.isConnecting) {
      _repository.disconnectFromDevice(context);
    }

    _connectionManager.setConnected(false);
    _connectionManager.setConnecting(false);
    _connectionManager.setConnectionStatus("Disconnected");
    _connectionManager.setBattery(_formatBatteryLevel(-1));
    _connectionManager.setActiveSensors([]);

    // Notify background service of disconnection
    final service = bg.FlutterBackgroundServiceAndroid();
    service.invoke('disconnect', {});
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
      appBar: AppBar(title: const Text("Device Connection")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Background service status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Background Service",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Data collection will continue in the background even when app is closed.",
                        textAlign: TextAlign.center,
                      ),
                      if (isConnected) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "You can safely close this app and data will still be collected and sent to the server.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Connection status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        isConnecting
                            ? "Status: Connecting..."
                            : "Status: ${isConnected ? 'Connected' : 'Disconnected'}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isConnecting
                                  ? Colors.orange
                                  : (isConnected ? Colors.green : Colors.red),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(connectionStatus),
                      if (isConnected) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.battery_full),
                            const SizedBox(width: 8),
                            Text(
                              "Battery: $battery",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ActiveSensorsWidget(
                activeSensors: activeSensors,
                isConnected: isConnected,
              ),

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: MacAddressTextField(
                  controller: _controller,
                  enabled: !isConnected && !isConnecting,
                ),
              ),
              const SizedBox(height: 16),

              if (!isConnected && !isConnecting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Examples: C1:74:71:F3:94:E0',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              if (!isConnected && !isConnecting)
                ElevatedButton(
                  onPressed: () {
                    final mac = _controller.text.trim();
                    if (mac.isNotEmpty) {
                      connect(mac);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a MAC address'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_connected),
                      SizedBox(width: 8),
                      Text(
                        "Connect to device",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: disconnect,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_disabled, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Disconnect",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBatteryLevel(int level) {
    return level < 0 ? "N/A" : "$level%";
  }

  @override
  bool get wantKeepAlive => true;
}
