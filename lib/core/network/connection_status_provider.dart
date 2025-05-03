import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

class ConnectionStatus {
  final bool isConnected;
  final int cachedRequestsCount;

  ConnectionStatus({
    required this.isConnected,
    required this.cachedRequestsCount,
  });
}

class ConnectionStatusProvider extends ChangeNotifier {
  static final ConnectionStatusProvider _instance =
      ConnectionStatusProvider._internal();

  factory ConnectionStatusProvider() => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  bool _isConnected = true;
  int _cachedRequestsCount = 0;

  Stream<ConnectionStatus> get statusStream =>
      _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  int get cachedRequestsCount => _cachedRequestsCount;

  ConnectionStatusProvider._internal() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      Logger.i('Initializing connectivity monitoring');

      await _checkConnectivity();

      await _connectivitySubscription?.cancel();
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) {
        Logger.i('Connectivity changed event received: $results');
        _checkConnectivity();
      });
    } catch (e) {
      Logger.e('Could not initialize connectivity', error: e);
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.vpn);

      _updateConnectionStatus(hasConnection);
    } catch (e) {
      Logger.e('Connectivity check error', error: e);
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    bool wasConnected = _isConnected;

    if (wasConnected != isConnected) {
      Logger.i(
        'INTERNET CONNECTIVITY CHANGED: ${isConnected ? "CONNECTED" : "DISCONNECTED"}',
      );

      _isConnected = isConnected;
      _notifyAboutStatus();
      notifyListeners();
    }
  }

  void updateCachedRequestsCount(int count) {
    if (_cachedRequestsCount != count) {
      Logger.i(
        'Cached requests count updated: $_cachedRequestsCount -> $count',
      );
      _cachedRequestsCount = count;
      _notifyAboutStatus();
      notifyListeners();
    }
  }

  void _notifyAboutStatus() {
    _connectionStatusController.add(
      ConnectionStatus(
        isConnected: _isConnected,
        cachedRequestsCount: _cachedRequestsCount,
      ),
    );
  }

  Future<void> checkConnectivity() async {
    try {
      Logger.i('Manually checking connectivity status');
      await _checkConnectivity();
    } catch (e) {
      Logger.e('Error checking connectivity', error: e);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
    super.dispose();
  }
}
