import 'package:flutter/material.dart';

class ActiveSensorsWidget extends StatelessWidget {
  final List<String> activeSensors;
  final bool isConnected;

  const ActiveSensorsWidget({
    super.key,
    required this.activeSensors,
    this.isConnected = false,
  });

  static const Map<String, SensorInfo> _sensorInfoMap = {
    'Accelerometer': SensorInfo(
      description:
          'Measures acceleration forces in X, Y, and Z axes. Used for detecting motion and orientation.',
      icon: Icons.speed,
    ),
    'Gyroscope': SensorInfo(
      description:
          'Measures rotational velocity around X, Y, and Z axes. Used for detecting precise orientation changes.',
      icon: Icons.rotate_90_degrees_ccw,
    ),
    'Battery': SensorInfo(
      description: 'Monitors device battery level. Used for power management.',
      icon: Icons.battery_full,
    ),
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
                  'Device Sensors (${activeSensors.length}/${_sensorInfoMap.length} active)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fixed layout: Row with Expanded for equal spacing of 3 sensors
            Row(
              children:
                  _sensorInfoMap.keys.map((sensor) {
                    final isActive = activeSensors.contains(sensor);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildSensorChip(context, sensor, isActive),
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

  Widget _buildSensorChip(BuildContext context, String sensor, bool isActive) {
    final sensorInfo = _sensorInfoMap[sensor]!;

    return InkWell(
      onTap: () => _showSensorDialog(context, sensor, isActive, sensorInfo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: isActive ? Colors.green : Colors.grey,
              radius: 16,
              child: Icon(sensorInfo.icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              sensor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.black : Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorDialog(
    BuildContext context,
    String sensorName,
    bool isActive,
    SensorInfo info,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive ? Colors.green : Colors.grey,
                  radius: 12,
                  child: Icon(info.icon, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(sensorName),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(info.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
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
}

class SensorInfo {
  final String description;
  final IconData icon;

  const SensorInfo({required this.description, required this.icon});
}
