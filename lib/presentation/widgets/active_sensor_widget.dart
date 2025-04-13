import 'package:flutter/material.dart';

class ActiveSensorsWidget extends StatelessWidget {
  final List<String> activeSensors;
  final bool isConnected;

  const ActiveSensorsWidget({
    super.key,
    required this.activeSensors,
    this.isConnected = false,
  });

  static const Map<String, String> allSensors = {
    'Accelerometer':
        'Measures acceleration forces in X, Y, and Z axes. Used for detecting motion and orientation.',
    'Ambient Light': 'Measures environmental light levels in lux.',
    'Barometer': 'Measures atmospheric pressure and can determine altitude.',
    'Color Sensor': 'Detects RGB color values of objects.',
    'Gyroscope':
        'Measures rotational velocity around X, Y, and Z axes. Used for detecting precise orientation changes.',
    'Humidity Sensor':
        'Measures relative humidity in the air. Used for environmental monitoring.',
    'Magnetometer': 'Measures magnetic field strength and direction.',
    'Proximity Sensor': 'Detects nearby objects without physical contact.',
    'Battery': 'Monitors device battery level. Used for power management.',
  };

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Sensors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Connect to a device to see available sensors',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    final sortedSensors =
        allSensors.keys.toList()..sort((a, b) {
          final aActive = activeSensors.contains(a);
          final bActive = activeSensors.contains(b);
          if (aActive != bActive) {
            return aActive ? -1 : 1;
          }
          return a.compareTo(b);
        });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Device Sensors (${activeSensors.length}/${allSensors.length} active)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  sortedSensors.map((sensor) {
                    final bool isActive = activeSensors.contains(sensor);

                    return InkWell(
                      onTap: () => _showSensorInfo(context, sensor, isActive),
                      child: Chip(
                        avatar: _getIconForSensor(sensor, isActive),
                        label: Text(
                          sensor,
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.black54,
                          ),
                        ),
                        backgroundColor:
                            isActive
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                        side: BorderSide(
                          color: isActive ? Colors.green : Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap on a sensor for more information',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap on the Graphs tab to visualize sensor data',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorInfo(BuildContext context, String sensorName, bool isActive) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                _getIconForSensor(sensorName, isActive, size: 24),
                const SizedBox(width: 8),
                Text(sensorName),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Not Available',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  allSensors[sensorName] ?? 'No description available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Sample data if active
                if (isActive)
                  const Text(
                    'Data from this sensor will be collected and can be viewed in the Graphs tab.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _getIconForSensor(
    String sensorName,
    bool isActive, {
    double size = 12,
  }) {
    IconData iconData = Icons.sensors;

    if (sensorName.contains('Accelerometer')) {
      iconData = Icons.speed;
    } else if (sensorName.contains('Gyroscope')) {
      iconData = Icons.rotate_90_degrees_ccw;
    } else if (sensorName.contains('Magnetometer')) {
      iconData = Icons.compass_calibration;
    } else if (sensorName.contains('Ambient Light')) {
      iconData = Icons.lightbulb;
    } else if (sensorName.contains('Barometer')) {
      iconData = Icons.compress;
    } else if (sensorName.contains('Humidity')) {
      iconData = Icons.water_drop;
    } else if (sensorName.contains('Color')) {
      iconData = Icons.color_lens;
    } else if (sensorName.contains('Proximity')) {
      iconData = Icons.nearby_error;
    } else if (sensorName.contains('Battery')) {
      iconData = Icons.battery_full;
    }

    return CircleAvatar(
      backgroundColor: isActive ? Colors.green : Colors.grey,
      radius: size,
      child: Icon(iconData, size: size, color: Colors.white),
    );
  }
}
