import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppwd_frontend/core/models/board.dart';
import 'package:ppwd_frontend/core/models/measurement.dart';
import 'package:ppwd_frontend/data/services/board_service.dart';
import 'notification_service.dart';

/// Global variable for the connected device’s MAC address.
/// (Update this from your UI when a connection is established.)
String backgroundConnectedMac = '';

@pragma('vm:entry-point')
Future<void> backgroundServiceEntryPoint(ServiceInstance service) async {
  // Ensure plugins are registered.
  DartPluginRegistrant.ensureInitialized();

  // Immediately mark this service as a foreground service.
  if (service is AndroidServiceInstance) {
    try {
      service.setAsForegroundService();
    } catch (e) {
      log("Error calling setAsForegroundService: $e");
    }
  }

  // Initialize notifications.
  await NotificationService().init();

  // Show a persistent notification with a "Stop Service" action.
  await NotificationService().showStopNotification();

  // Listen for a stop command.
  service.on("stopService").listen((event) {
    log("Stopping background service as requested.");
    service.stopSelf();
  });

  // Periodically run background tasks every minute.
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final int batteryLevel = await getBatteryLevelBackground();
    final bool internetConnected = await isInternetConnected();
    final bool isDeviceConnected = batteryLevel >= 0;

    // Read the app lifecycle flag.
    final prefs = await SharedPreferences.getInstance();
    bool appInBackground = prefs.getBool('appInBackground') ?? true;

    // Optionally show notifications only if the app is backgrounded.
    if (appInBackground) {
      if (isDeviceConnected && batteryLevel < 15) {
        await NotificationService().showBatteryLowNotification(batteryLevel);
      }
      if (!isDeviceConnected) {
        await NotificationService().showDisconnectedNotification();
      }
      if (!internetConnected) {
        await NotificationService().showNoInternetNotification();
      }
    }

    // Always send sensor data.
    final Map<String, List<dynamic>> moduleData =
        await getModuleDataBackground();
    if (moduleData.isNotEmpty && backgroundConnectedMac.isNotEmpty) {
      try {
        final board = Board(
          backgroundConnectedMac,
          moduleData.map((key, value) {
            final List<Measurement> measurements =
                value.map((item) {
                  return Measurement(
                    item[0].toString(),
                    int.tryParse(item[1].toString()) ?? 0,
                  );
                }).toList();
            return MapEntry(key, measurements);
          }),
        );
        await BoardService().sendSensorData(board);
      } catch (e) {
        log("Error sending sensor data: $e");
      }
    }
    log(
      "Background update at ${DateTime.now()} - Battery: $batteryLevel, Connected: $isDeviceConnected, Internet: $internetConnected, AppInBackground: $appInBackground",
    );
  });
}

Future<int> getBatteryLevelBackground() async {
  try {
    const platform = MethodChannel('flutter.native/board');
    final int? batteryLevel = await platform.invokeMethod('getBatteryLevel');
    return batteryLevel ?? -1;
  } catch (e) {
    log("Error fetching battery level: $e");
    return -1;
  }
}

Future<bool> isInternetConnected() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    log("No internet connection: $e");
    return false;
  }
}

Future<Map<String, List<dynamic>>> getModuleDataBackground() async {
  try {
    const platform = MethodChannel('flutter.native/board');
    final Map<Object?, Object?> rawData = await platform.invokeMethod(
      'getModulesData',
    );
    if (rawData.isEmpty) return {};
    return rawData.map(
      (key, value) =>
          MapEntry(key.toString(), List<dynamic>.from(value as List)),
    );
  } catch (e) {
    log("Error fetching module data: $e");
    return {};
  }
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  const String notificationChannelId = 'my_foreground_channel';
  const String notificationId = '888';

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundServiceEntryPoint,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Device Monitor',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: int.parse(notificationId),
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}
