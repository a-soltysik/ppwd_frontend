import 'package:flutter/material.dart';

class ConnectionStateManager {
  static final ConnectionStateManager _instance =
      ConnectionStateManager._internal();

  factory ConnectionStateManager() => _instance;

  ConnectionStateManager._internal();

  bool isConnected = false;
  bool isConnecting = false;
  String connectionStatus = "";
  String connectedDevice = "";
  String battery = "N/A";

  List<String> activeSensors = [];

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void setConnected(bool connected) {
    isConnected = connected;
    if (!connected) {
      activeSensors = [];
    }
    notifyListeners();
  }

  void setConnecting(bool connecting) {
    isConnecting = connecting;
    notifyListeners();
  }

  void setConnectionStatus(String status) {
    connectionStatus = status;
    notifyListeners();
  }

  void setConnectedDevice(String device) {
    connectedDevice = device;
    notifyListeners();
  }

  void setBattery(String batteryLevel) {
    battery = batteryLevel;
    notifyListeners();
  }

  void setActiveSensors(List<String> sensors) {
    activeSensors = List<String>.from(sensors);
    notifyListeners();
  }

  void reset() {
    isConnected = false;
    isConnecting = false;
    connectionStatus = "";
    connectedDevice = "";
    battery = "N/A";
    activeSensors = [];
    notifyListeners();
  }
}
