enum MeasurementType {
  acceleration('Acceleration', 'Motion detection (X, Y, Z axes)'),
  angularVelocity('Angular Velocity', 'Rotation rate (deg/sec)');

  final String displayName;
  final String description;

  const MeasurementType(this.displayName, this.description);
}
