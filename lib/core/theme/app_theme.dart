import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary colors
  static const Color primaryColor = Colors.blue;
  static const Color primaryDarkColor = Color(0xFF1565C0);
  static const Color primaryLightColor = Color(0xFF90CAF9);

  // Accent colors
  static const Color accentColor = Colors.blue;

  // Status colors
  static const Color connectedColor = Colors.green;
  static const Color disconnectedColor = Colors.red;
  static const Color connectingColor = Colors.orange;
  static const Color lowBatteryColor = Colors.red;

  // Text colors
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color textLightColor = Colors.white;

  // Background colors
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Main theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorDark: primaryDarkColor,
      primaryColorLight: primaryLightColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
      ),
      appBarTheme: const AppBarTheme(
        color: primaryColor,
        foregroundColor: textLightColor,
      ),
      cardTheme: const CardTheme(
        color: cardColor,
        elevation: 2.0,
        margin: EdgeInsets.all(8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textLightColor,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
    );
  }

  // Status-specific styles
  static TextStyle statusTextStyle(bool isConnected, bool isConnecting) {
    Color textColor =
        isConnecting
            ? connectingColor
            : (isConnected ? connectedColor : disconnectedColor);

    return TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: 18.0,
    );
  }

  static TextStyle batteryTextStyle(int batteryLevel) {
    return TextStyle(
      color: batteryLevel < 20 ? lowBatteryColor : textPrimaryColor,
      fontWeight: batteryLevel < 20 ? FontWeight.bold : FontWeight.normal,
      fontSize: 16.0,
    );
  }
}
