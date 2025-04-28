import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as bg;
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';
import 'package:ppwd_frontend/data/services/notification_service.dart';
import 'package:ppwd_frontend/data/services/data_collection_service.dart';

@pragma('vm:entry-point')
Future<void> initializeBackgroundService() async {
  final service = bg.FlutterBackgroundServiceAndroid();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'device_monitor_channel',
      initialNotificationTitle: 'Device Monitor',
      initialNotificationContent: 'Waiting for board…',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onStart,
      onBackground: _onIosBg,
    ),
  );
  service.start();
}

@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final repo = BoardRepository();
  final dataSvc = DataCollectionService();
  String mac = '';
  bool lowBattNotified = false;

  if (service is bg.AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Device Monitor',
      content: 'Waiting for board…',
    );
  }

  service.on('updateMac').listen((evt) async {
    final m = evt?['mac'] as String?;
    if (m == null || m.isEmpty) return;
    mac = m;

    if (service is bg.AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Monitoring $mac',
        content: 'Collecting data every minute',
      );
    }

    final opt = await repo.connectToDevice(null, mac);
    if (!opt.isPresent || !(opt.value)) {
      log('BgService: failed to connect to $mac');
      return;
    }

    dataSvc.startDataCollection(null, repo, mac, (batteryLevel) {
      if (batteryLevel < 20 && !lowBattNotified) {
        lowBattNotified = true;
        NotificationService().showBatteryLowNotification(batteryLevel);
      } else if (batteryLevel >= 20) {
        lowBattNotified = false;
      }
    });
  });
}

@pragma('vm:entry-point')
bool _onIosBg(ServiceInstance service) => true;
