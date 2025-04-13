import 'dart:convert';

import 'measurement.dart';

class Board {
  final String macAddress;
  final Map<String, List<Measurement>> measurements;

  Board(this.macAddress, this.measurements);

  @override
  String toString() {
    return '{macAddress: $macAddress, measurements: ${jsonEncode(_serializeMeasurements())}}';
  }

  Map<String, dynamic> toJson() {
    return {'macAddress': macAddress, 'measurements': _serializeMeasurements()};
  }

  List<Map<String, dynamic>> _serializeMeasurements() {
    return measurements.entries.map((entry) {
      return {
        'type': entry.key,
        'payload': entry.value.map((m) => m.toJson()).toList(),
      };
    }).toList();
  }
}
