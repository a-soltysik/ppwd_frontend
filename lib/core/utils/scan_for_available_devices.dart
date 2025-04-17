import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceSelector extends StatefulWidget {
  final Function(String macAddress) onDeviceSelected;

  const BluetoothDeviceSelector({super.key, required this.onDeviceSelected});

  @override
  State<BluetoothDeviceSelector> createState() =>
      _BluetoothDeviceSelectorState();
}

class _BluetoothDeviceSelectorState extends State<BluetoothDeviceSelector> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  void _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults =
            results.where((r) => r.device.platformName.isNotEmpty).toList();
      });
    });

    await Future.delayed(const Duration(seconds: 5));

    FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);
  }

  void _showScanDialog() {
    _startScan();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Select a Device"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child:
                  _isScanning
                      ? const Center(child: CircularProgressIndicator())
                      : _scanResults.isEmpty
                      ? const Center(child: Text("No devices found"))
                      : ListView.builder(
                        itemCount: _scanResults.length,
                        itemBuilder: (context, index) {
                          final device = _scanResults[index].device;
                          return ListTile(
                            title: Text(device.platformName),
                            subtitle: Text(device.remoteId.str),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onDeviceSelected(device.remoteId.str);
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FlutterBluePlus.stopScan();
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _showScanDialog,
      icon: const Icon(Icons.search),
      label: const Text("Scan for Devices"),
    );
  }
}
