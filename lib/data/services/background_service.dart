// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:ppwd_frontend/bg_service.dart' as bg;
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:ppwd_frontend/data/repositories/board_repository.dart';
import 'package:ppwd_frontend/data/services/board_service.dart';
import 'package:ppwd_frontend/data/services/notification_service.dart';
import 'package:ppwd_frontend/core/models/board.dart';

@pragma('vm:entry-point')
Future<void> initializeBackgroundService() async {
  final service = bg.FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'device_monitor_channel',
      initialNotificationTitle: 'Device Monitor',
      initialNotificationContent: 'Monitoring sensors and battery',
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
void _onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  String backgroundConnectedMac = "";

  log('BgService: started');
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Monitor Active',
      content: 'Collecting data every minute',
    );
  }
  // NotificationService().showStopServiceNotification();

  // Listen for “updateMac” events from the UI
  service.on('updateMac').listen((event) {
    final m = event?['mac'] as String?;
    if (m != null) backgroundConnectedMac = m;
  });

  final repo = BoardRepository();
  final backend = BoardService();

  Timer.periodic(const Duration(minutes: 1), (_) async {
    log('Periodic timer tick: collecting data');
    final mac = backgroundConnectedMac;
    log('Mac address: $mac');
    if (mac.isEmpty) return;

    try {
      final dataOpt = await repo.getModuleData(null);
      log('Data opt: $dataOpt');
      dataOpt.filter((list) => list.isNotEmpty).ifPresent((measurements) async {
        log('Measurements: $measurements');
        final success = await backend.sendSensorData(Board(mac, measurements));
        log('Data sent to backend: $success');
        (await repo.getBatteryLevel(null)).ifPresent((batt) {
          if (batt < 20) {
            log('Battery low threshold reached, showing notification');
            NotificationService().showBatteryLowNotification(batt);
          }
        });
      });
    } catch (e, st) {
      log('Error in data collection cycle: $e', error: e, stackTrace: st);
    }
  });
}

@pragma('vm:entry-point')
bool _onIosBg(ServiceInstance service) {
  // DartPluginRegistrant.ensureInitialized();
  return true;
}
