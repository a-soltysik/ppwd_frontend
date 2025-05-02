import 'package:flutter/material.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';

class ConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String connectionStatus;
  final String connectedDevice;
  final String battery;
  final List<String> activeSensors;

  ConnectionState({
    required this.isConnected,
    required this.isConnecting,
    required this.connectionStatus,
    required this.connectedDevice,
    required this.battery,
    required this.activeSensors,
  });

  ConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? connectionStatus,
    String? connectedDevice,
    String? battery,
    List<String>? activeSensors,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      battery: battery ?? this.battery,
      activeSensors: activeSensors ?? this.activeSensors,
    );
  }
}

class ConnectionStateManager extends ChangeNotifier {
  static final ConnectionStateManager _instance =
      ConnectionStateManager._internal();

  factory ConnectionStateManager() => _instance;

  ConnectionStateManager._internal()
    : _state = ConnectionState(
        isConnected: false,
        isConnecting: false,
        connectionStatus: '',
        connectedDevice: '',
        battery: 'N/A',
        activeSensors: [],
      );

  ConnectionState _state;

  ConnectionState get state => _state;

  bool get isConnected => _state.isConnected;

  bool get isConnecting => _state.isConnecting;

  String get connectionStatus => _state.connectionStatus;

  String get connectedDevice => _state.connectedDevice;

  String get battery => _state.battery;

  List<String> get activeSensors => _state.activeSensors;

  void setConnected(bool connected) {
    _state = _state.copyWith(
      isConnected: connected,
      activeSensors: connected ? _state.activeSensors : [],
    );

    notifyListeners();
  }

  void setConnecting(bool connecting) {
    _state = _state.copyWith(isConnecting: connecting);
    notifyListeners();
  }

  void setConnectionStatus(String status) {
    _state = _state.copyWith(connectionStatus: status);
    notifyListeners();
  }

  void setConnectedDevice(String device) {
    _state = _state.copyWith(connectedDevice: device);

    // Sync with SharedPreferences
    if (device.isNotEmpty) {
      UserSimplePreferences.setMacAddress(device);
    }
    notifyListeners();
  }

  void setBattery(String batteryLevel) {
    _state = _state.copyWith(battery: batteryLevel);
    notifyListeners();
  }

  void setActiveSensors(List<String> sensors) {
    _state = _state.copyWith(activeSensors: List<String>.from(sensors));
    notifyListeners();
  }

  Future<void> loadFromPreferences() async {
    final connectedDevice = UserSimplePreferences.getMacAddress() ?? "";

    _state = ConnectionState(
      isConnected: isConnected,
      isConnecting: false,
      connectionStatus: isConnected ? "Connected to $connectedDevice" : "",
      connectedDevice: connectedDevice,
      battery: "N/A",
      activeSensors: activeSensors,
    );

    notifyListeners();
  }

  void reset() {
    _state = ConnectionState(
      isConnected: false,
      isConnecting: false,
      connectionStatus: "",
      connectedDevice: "",
      battery: "N/A",
      activeSensors: [],
    );

    UserSimplePreferences.removeMacAddress();

    notifyListeners();
  }
}
