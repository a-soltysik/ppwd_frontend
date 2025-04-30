import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as bg;
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';
import 'package:ppwd_frontend/data/services/data_collection_service.dart';
import 'package:ppwd_frontend/data/services/notification_service.dart';

String _lastTitle = '';
String _lastContent = '';
bool _serviceInitialized = false;

Future<void> initializeBackgroundService() async {
  if (_serviceInitialized) {
    log('Background service already initialized');
    return;
  }

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
  _serviceInitialized = true;
}

void updateForegroundNotification(
  bg.AndroidServiceInstance service, {
  required String title,
  required String content,
}) {
  if (title != _lastTitle || content != _lastContent) {
    service.setForegroundNotificationInfo(title: title, content: content);

    _lastTitle = title;
    _lastContent = content;

    _saveNotificationState(title, content);
  }
}

Future<void> _saveNotificationState(String title, String content) async {
  try {
    await UserSimplePreferences.setNotificationState('$title|$content');
  } catch (e) {
    log('Error saving notification state: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final repo = BoardRepository();
  final dataSvc = DataCollectionService();

  await UserSimplePreferences.init();

  String notificationTitle = 'Device Monitor';
  String notificationContent = 'Service running...';

  if (service is bg.AndroidServiceInstance) {
    updateForegroundNotification(
      service,
      title: notificationTitle,
      content: notificationContent,
    );
  }

  try {
    final lastConnectedMac = UserSimplePreferences.getMacAddress();
    final isConnectionActive = UserSimplePreferences.getConnectionActive();

    if (lastConnectedMac != null && isConnectionActive == true) {
      log('BgService: Restoring connection to $lastConnectedMac');

      if (service is bg.AndroidServiceInstance) {
        notificationTitle = 'Reconnecting';
        notificationContent = 'Trying to connect to $lastConnectedMac';

        updateForegroundNotification(
          service,
          title: notificationTitle,
          content: notificationContent,
        );
      }

      // Attempt to reconnect
      _connectToDevice(service, repo, dataSvc, lastConnectedMac);
    }
  } catch (e) {
    log('BgService: Error restoring connection: $e');
  }

  // Listen for connection updates from the main app
  service.on('updateMac').listen((evt) async {
    final macAddress = evt?['mac'] as String?;
    if (macAddress == null || macAddress.isEmpty) return;

    // Store MAC address for reconnecting if the service restarts
    await UserSimplePreferences.setMacAddress(macAddress);
    await UserSimplePreferences.setConnectionActive(true);

    log('BgService: Connection request for $macAddress');

    _connectToDevice(service, repo, dataSvc, macAddress);
  });

  // Listen for disconnect requests
  service.on('disconnect').listen((evt) async {
    log('BgService: Disconnect requested');

    await UserSimplePreferences.setConnectionActive(false);
    await UserSimplePreferences.removeMacAddress();

    if (service is bg.AndroidServiceInstance) {
      notificationTitle = 'Device Monitor';
      notificationContent = 'Disconnected from device';

      updateForegroundNotification(
        service,
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
    // Check if we need to reconnect
    final lastConnectedMac = UserSimplePreferences.getMacAddress();
    final isConnectionActive = UserSimplePreferences.getConnectionActive();

    if (lastConnectedMac != null &&
        isConnectionActive == true &&
        !dataSvc.isCollectingSync()) {
      log(
        'BgService: Heartbeat detected disconnection, reconnecting to $lastConnectedMac',
      );

      if (service is bg.AndroidServiceInstance) {
        notificationTitle = 'Reconnecting';
        notificationContent = 'Trying to connect to $lastConnectedMac';

        updateForegroundNotification(
          service,
          title: notificationTitle,
          content: notificationContent,
        );
      }

      _connectToDevice(service, repo, dataSvc, lastConnectedMac);
    }
  });
}

Future<void> _connectToDevice(
  ServiceInstance service,
  BoardRepository repo,
  DataCollectionService dataSvc,
  String macAddress,
) async {
  if (service is bg.AndroidServiceInstance) {
    updateForegroundNotification(
      service,
      title: 'Connecting to device',
      content: 'Attempting to connect to $macAddress',
    );
  }

  try {
    final opt = await repo.connectToDevice(null, macAddress);

    if (!opt.isPresent || !(opt.value)) {
      log('BgService: Failed to connect to $macAddress');

      // Schedule retry
      Timer(const Duration(seconds: 30), () {
        log('BgService: Retrying connection to $macAddress');
        _connectToDevice(service, repo, dataSvc, macAddress);
      });

      return;
    }

    // Setup data collection
    await dataSvc.startDataCollection(null, repo, macAddress, (
      batteryLevel,
    ) async {
      NotificationService().showBatteryLowNotification(batteryLevel);

      // Update notification with battery info
      if (service is bg.AndroidServiceInstance) {
        updateForegroundNotification(
          service,
          title: 'Monitoring $macAddress',
          content: 'Service is running in the background',
        );
      }

      await UserSimplePreferences.setDeviceBattery(batteryLevel);
    });

    log('BgService: Successfully connected to $macAddress');
  } catch (e) {
    log('BgService: Error during connection: $e');

    if (service is bg.AndroidServiceInstance) {
      updateForegroundNotification(
        service,
        title: 'Connection error',
        content: 'Error: $e',
      );
    }

    // Schedule retry
    Timer(const Duration(seconds: 30), () {
      _connectToDevice(service, repo, dataSvc, macAddress);
    });
  }
}

@pragma('vm:entry-point')
bool _onIosBg(ServiceInstance service) => true;
