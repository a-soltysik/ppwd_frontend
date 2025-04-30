import 'package:shared_preferences/shared_preferences.dart';

class UserSimplePreferences {
  static late SharedPreferences _preferences;

  // Keys for SharedPreferences
  static String PREFS_MAC_ADDRESS = "last_connected_mac";
  static String PREFS_CONNECTION_ACTIVE = "connection_active";
  static String PREFS_DEVICE_BATTERY = "device_battery_level";
  static String PREFS_ACTIVE_SENSORS = "active_sensors";

  // Notification
  static String PREFS_NOTIFICATION_STATE = "notification_state";
  static String PREFS_NOTIF_KEY = "battery_low_notification_shown";
  static String PREFS_NOTIF_TIME = "last_battery_notification_time";

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future<void> setMacAddress(String mac) async =>
      await _preferences.setString(PREFS_MAC_ADDRESS, mac);

  static String? getMacAddress() => _preferences.getString(PREFS_MAC_ADDRESS);

  static Future<void> removeMacAddress() =>
      _preferences.remove(PREFS_MAC_ADDRESS);

  static Future<void> setConnectionActive(bool value) async =>
      await _preferences.setBool(PREFS_CONNECTION_ACTIVE, value);

  static bool? getConnectionActive() =>
      _preferences.getBool(PREFS_CONNECTION_ACTIVE);

  static Future<void> setDeviceBattery(int battery) async =>
      await _preferences.setInt(PREFS_DEVICE_BATTERY, battery);

  static int? getDeviceBattery() => _preferences.getInt(PREFS_DEVICE_BATTERY);

  static Future<void> setActiveSensors(List<String> sensors) async =>
      await _preferences.setStringList(PREFS_ACTIVE_SENSORS, sensors);

  static List<String>? getActiveSensors() =>
      _preferences.getStringList(PREFS_ACTIVE_SENSORS);

  static Future<void> setNotificationState(String state) async =>
      await _preferences.setString(PREFS_NOTIFICATION_STATE, state);

  static String? getNotificationState() =>
      _preferences.getString(PREFS_NOTIFICATION_STATE);

  static Future<void> setNotificationKey(bool value) async =>
      await _preferences.setBool(PREFS_NOTIF_KEY, value);

  static bool? getNotificationKey() => _preferences.getBool(PREFS_NOTIF_KEY);

  static Future<void> setNotificationTime(int time) async =>
      await _preferences.setInt(PREFS_NOTIF_TIME, time);

  static int? getNotificationTime() => _preferences.getInt(PREFS_NOTIF_TIME);

  static Future<void> removeNotificationKey() =>
      _preferences.remove(PREFS_NOTIF_KEY);
}
