import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class UserSimplePreferences {
  static late SharedPreferences _preferences;

  static String get PREFS_MAC_ADDRESS => AppConstants.prefMacAddress;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future<void> setMacAddress(String mac) async =>
      await _preferences.setString(PREFS_MAC_ADDRESS, mac);

  static String? getMacAddress() => _preferences.getString(PREFS_MAC_ADDRESS);

  static Future<void> removeMacAddress() =>
      _preferences.remove(PREFS_MAC_ADDRESS);
}
