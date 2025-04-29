import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as bg;
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';
import 'package:ppwd_frontend/data/services/data_collection_service.dart';
import 'package:ppwd_frontend/data/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences
const String PREFS_MAC_ADDRESS = "last_connected_mac";
const String PREFS_CONNECTION_ACTIVE = "connection_active";

Future<void> initializeBackgroundService() async {
  final service = bg.FlutterBackgroundServiceAndroid();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'device_monitor_channel',
      initialNotificationTitle: 'Device Monitor',
      initialNotificationContent: 'Initializing service...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onStart,
      onBackground: _onIosBg,
    ),
  );

  await service.start();
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final repo = BoardRepository();
  final dataSvc = DataCollectionService();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  bool lowBattNotified = false;
  String? lastConnectedMac;
  bool? isConnectionActive;

  String notificationTitle = 'Device Monitor';
  String notificationContent = 'Service running...';

  if (service is bg.AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: notificationTitle,
      content: notificationContent,
    );
  }

  try {
    lastConnectedMac = prefs.getString(PREFS_MAC_ADDRESS);
    isConnectionActive = prefs.getBool(PREFS_CONNECTION_ACTIVE);

    if (lastConnectedMac != null && isConnectionActive == true) {
      log('BgService: Restoring connection to $lastConnectedMac');

      if (service is bg.AndroidServiceInstance) {
        notificationTitle = 'Reconnecting';
        notificationContent = 'Trying to connect to $lastConnectedMac';
        service.setForegroundNotificationInfo(
          title: notificationTitle,
          content: notificationContent,
        );
      }

      // Attempt to reconnect
      _connectToDevice(
        service,
        repo,
        dataSvc,
        lastConnectedMac,
        lowBattNotified,
        notificationTitle,
        notificationContent,
      );
    }
  } catch (e) {
    log('BgService: Error restoring connection: $e');
  }

  // Listen for connection updates from the main app
  service.on('updateMac').listen((evt) async {
    final macAddress = evt?['mac'] as String?;
    if (macAddress == null || macAddress.isEmpty) return;

    // Store MAC address for reconnecting if the service restarts
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREFS_MAC_ADDRESS, macAddress);
    await prefs.setBool(PREFS_CONNECTION_ACTIVE, true);

    log('BgService: Connection request for $macAddress');

    _connectToDevice(
      service,
      repo,
      dataSvc,
      macAddress,
      lowBattNotified,
      notificationTitle,
      notificationContent,
    );
  });

  // Listen for disconnect requests
  service.on('disconnect').listen((evt) async {
    log('BgService: Disconnect requested');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFS_CONNECTION_ACTIVE, false);

    if (service is bg.AndroidServiceInstance) {
      notificationTitle = 'Device Monitor';
      notificationContent = 'Disconnected from device';
      service.setForegroundNotificationInfo(
        title: notificationTitle,
        content: notificationContent,
      );
    }

    // Disconnect from the board but don't kill the service
    await repo.disconnectFromDevice(null);
    await dataSvc.stopDataCollection();
  });

  // Keep this service running with regular health checks
  Timer.periodic(const Duration(minutes: 1), (_) async {
    // Service heartbeat
    if (service is bg.AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: notificationTitle,
        content: notificationContent,
      );
    }

    // Check if we need to reconnect
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    lastConnectedMac = prefs.getString(PREFS_MAC_ADDRESS);
    isConnectionActive = prefs.getBool(PREFS_CONNECTION_ACTIVE);

    if (lastConnectedMac != null &&
        isConnectionActive == true &&
        !dataSvc.isCollectingSync()) {
      log(
        'BgService: Heartbeat detected disconnection, reconnecting to $lastConnectedMac',
      );
      _connectToDevice(
        service,
        repo,
        dataSvc,
        lastConnectedMac!,
        lowBattNotified,
        notificationTitle,
        notificationContent,
      );
    }
  });
}

Future<void> _connectToDevice(
  ServiceInstance service,
  BoardRepository repo,
  DataCollectionService dataSvc,
  String macAddress,
  bool lowBattNotified,
  String notificationTitle,
  String notificationContent,
) async {
  if (service is bg.AndroidServiceInstance) {
    notificationTitle = 'Connecting to device';
    notificationContent = 'Attempting to connect to $macAddress';
    service.setForegroundNotificationInfo(
      title: notificationTitle,
      content: notificationContent,
    );
  }

  try {
    final opt = await repo.connectToDevice(null, macAddress);

    if (!opt.isPresent || !(opt.value)) {
      log('BgService: Failed to connect to $macAddress');

      if (service is bg.AndroidServiceInstance) {
        notificationTitle = 'Connection failed';
        notificationContent = 'Could not connect to $macAddress';
        service.setForegroundNotificationInfo(
          title: notificationTitle,
          content: notificationContent,
        );
      }

      // Schedule retry
      Timer(const Duration(seconds: 30), () {
        log('BgService: Retrying connection to $macAddress');
        _connectToDevice(
          service,
          repo,
          dataSvc,
          macAddress,
          lowBattNotified,
          notificationTitle,
          notificationContent,
        );
      });

      return;
    }

    if (service is bg.AndroidServiceInstance) {
      notificationTitle = 'Monitoring $macAddress';
      notificationContent = 'Collecting data in background';
      service.setForegroundNotificationInfo(
        title: notificationTitle,
        content: notificationContent,
      );
    }

    // Setup data collection
    await dataSvc.startDataCollection(null, repo, macAddress, (batteryLevel) {
      if (batteryLevel < 20 && !lowBattNotified) {
        NotificationService().showBatteryLowNotification(batteryLevel);
        lowBattNotified = true;
      } else if (batteryLevel >= 20) {
        lowBattNotified = false;
      }

      // Update notification with battery info
      if (service is bg.AndroidServiceInstance) {
        notificationTitle = 'Monitoring $macAddress';
        notificationContent = 'Battery: $batteryLevel%, collecting data';
        service.setForegroundNotificationInfo(
          title: notificationTitle,
          content: notificationContent,
        );
      }
    });

    log('BgService: Successfully connected to $macAddress');
  } catch (e) {
    log('BgService: Error during connection: $e');

    if (service is bg.AndroidServiceInstance) {
      notificationTitle = 'Connection error';
      notificationContent = 'Error: $e';
      service.setForegroundNotificationInfo(
        title: notificationTitle,
        content: notificationContent,
      );
    }

    // Schedule retry
    Timer(const Duration(seconds: 30), () {
      _connectToDevice(
        service,
        repo,
        dataSvc,
        macAddress,
        lowBattNotified,
        notificationTitle,
        notificationContent,
      );
    });
  }
}

@pragma('vm:entry-point')
bool _onIosBg(ServiceInstance service) => true;
