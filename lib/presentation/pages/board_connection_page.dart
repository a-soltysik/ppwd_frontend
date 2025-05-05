import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ppwd_frontend/core/utils/scan_for_available_devices.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';

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

  @override
  void initState() {
    super.initState();

    _connectionManager.addListener(_updateUI);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.setupConnectionHandlers(
        context,
        onConnected: _handleConnectionSuccess,
        onDisconnected: _handleDisconnection,
      );

      if (_connectionManager.isConnected && _dataTimer == null) {
        _startDataCollection(_connectionManager.connectedDevice);
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
              if (!isConnected && !isConnecting)
                BluetoothDeviceSelector(
                  onDeviceSelected: (macAddress) {
                    _controller.text = macAddress;
                    connect(macAddress);
                  },
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
