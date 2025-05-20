import 'package:flutter/services.dart';
import 'package:ppwd_frontend/core/utils/user_shared_preference.dart';

class ScanDeviceService {
  List<String> _recentDevices = [];
  List<String> get recentDevices => _recentDevices;

  final _scannerChannel = const MethodChannel(
    'com.example.ppwd_frontend/metawear_scanner',
  );

  Future<String?> startScan() async {
    try {
      final dynamic result = await _scannerChannel.invokeMethod('startScan');
      if (result != null) {
        final macAddressObj = result['macAddress'];

        if (macAddressObj != null) {
          final String macAddress = macAddressObj.toString();

          if (macAddress.isNotEmpty) {
            await _saveDevice(macAddress);
            return macAddress;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRecentDevices() async {
    _recentDevices = UserSimplePreferences.getRecentDevices() ?? [];
  }

  Future<void> _saveDevice(String mac) async {
    if (mac.isEmpty) return;

    _recentDevices.remove(mac);
    _recentDevices.insert(0, mac);

    if (_recentDevices.length > 5) {
      _recentDevices = _recentDevices.sublist(0, 5);
    }

    await UserSimplePreferences.setRecentDevices(_recentDevices);
  }
}
