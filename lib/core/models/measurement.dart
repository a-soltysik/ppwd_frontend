import 'dart:convert';

class Measurement {
  final String data;
  final int timestamp;

  Measurement(this.data, this.timestamp);

  @override
  String toString() {
    return '{data: ${json.decode(data)}, timestamp: $timestamp}';
  }

  Map<String, dynamic> toJson() {
    return {'data': json.decode(data), 'timestamp': timestamp};
  }
}
