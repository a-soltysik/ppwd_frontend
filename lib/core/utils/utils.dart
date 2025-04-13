String getApiUrl() {
  return 'http://156.17.41.203:55555';
}

String getApiKey() {
  return 'apikey'; //@TODO Replace with actual api
}

String formatBatteryLevel(int level) {
  if (level < 0 || level > 100) {
    return "N/A";
  }

  return "$level%";
}

bool isValidMacAddress(String mac) {
  if (mac.isEmpty) {
    return false;
  }

  if (mac.length != 17) {
    return false;
  }

  for (int i = 2; i < 17; i += 3) {
    if (mac[i] != ':') {
      return false;
    }
  }

  for (int i = 0; i < 17; i++) {
    if (i % 3 == 2) {
      continue;
    }

    if (!RegExp(r'[0-9A-Fa-f]').hasMatch(mac[i])) {
      return false;
    }
  }

  return true;
}

enum MeasurementType {
  acceleration('Acceleration', 'Motion detection (X, Y, Z axes)'),
  illuminance('Illuminance', 'Ambient light measurement (lux)'),
  altitude('Altitude', 'Height from sea level (meters)'),
  pressure('Pressure', 'Atmospheric pressure (pascals)'),
  colorAdc('Color ADC', 'Color detection (RGB values)'),
  angularVelocity('Angular Velocity', 'Rotation rate (deg/sec)'),
  humidity('Humidity', 'Relative humidity (%)'),
  magneticField('Magnetic Field', 'Magnetic field strength (Gauss)'),
  proximityAdc('Proximity', 'Object presence detection');

  final String displayName;
  final String description;

  const MeasurementType(this.displayName, this.description);
}
