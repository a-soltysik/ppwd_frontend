/// Application-wide constants
class AppConstants {
  AppConstants._();

  // API Constants
  static const String apiBaseUrl = 'http://156.17.41.203:55555';
  static const String apiKey = 'T5as2#L1';
  static const Duration apiTimeout = Duration(seconds: 10);

  // Bluetooth Constants
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration dataCollectionInterval = Duration(seconds: 10);
  static const Duration initialDelay = Duration(milliseconds: 500);

  static const int batteryAlertThreshold = 20;

  // SharedPreferences Keys
  static const String prefMacAddress = "last_connected_mac";
}
