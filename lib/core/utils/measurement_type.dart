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
