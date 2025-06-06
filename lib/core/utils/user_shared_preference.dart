import 'package:shared_preferences/shared_preferences.dart';

import 'logger.dart';

class UserSimplePreferences {
  static SharedPreferences? _preferences;

  static Future init() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      Logger.i('SharedPreferences initialized successfully');
    } catch (e) {
      Logger.e('Error initializing SharedPreferences', error: e);
      throw Exception('Failed to initialize SharedPreferences');
    }
  }

  static String? getMacAddress() {
    if (_preferences == null) {
      Logger.w('SharedPreferences not initialized when getting MAC address');
      return null;
    }

    final String? mac = _preferences!.getString('mac_address');
    Logger.d('Retrieved MAC address: $mac');
    return mac;
  }

  static Future<bool> setMacAddress(String mac) async {
    if (_preferences == null) {
      Logger.w('SharedPreferences not initialized when setting MAC address');
      await init();
    }

    Logger.d('Saving MAC address: $mac');
    return await _preferences!.setString('mac_address', mac);
  }

  static Future<bool> removeMacAddress() async {
    if (_preferences == null) {
      Logger.w('SharedPreferences not initialized when removing MAC address');
      return false;
    }

    Logger.d('Removing MAC address from preferences');
    return await _preferences!.remove('mac_address');
  }

  static List<String>? getRecentDevices() {
    if (_preferences == null) {
      Logger.w('SharedPreferences not initialized when getting recent devices');
      return null;
    }

    final List<String>? devices = _preferences!.getStringList(
      'metawear_devices',
    );
    Logger.d('Retrieved recent devices address');
    return devices;
  }

  static Future<bool> setRecentDevices(List<String> devices) async {
    if (_preferences == null) {
      Logger.w('SharedPreferences not initialized when setting recent devices');
      await init();
    }

    Logger.d('Saving recent devices');
    return await _preferences!.setStringList('metawear_devices', devices);
  }

  static int? getLastPrediction() {
    if (_preferences == null) {
      Logger.w(
        'SharedPreferences not initialized when getting last prediction',
      );
      return null;
    }
    return _preferences!.getInt('last_prediction');
  }

  static Future<bool> setLastPrediction(int prediction) async {
    if (_preferences == null) {
      Logger.w(
        'SharedPreferences not initialized when setting last prediction',
      );
      await init();
    }
    Logger.d('Saving last prediction: $prediction');
    return await _preferences!.setInt('last_prediction', prediction);
  }

  static DateTime? getLastPredictionTime() {
    if (_preferences == null) {
      Logger.w(
        'SharedPreferences not initialized when getting last prediction time',
      );
      return null;
    }
    final timeString = _preferences!.getString('last_prediction_time');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  static Future<bool> setLastPredictionTime(DateTime time) async {
    if (_preferences == null) {
      Logger.w(
        'SharedPreferences not initialized when setting last prediction time',
      );
      await init();
    }
    return await _preferences!.setString(
      'last_prediction_time',
      time.toIso8601String(),
    );
  }
}
