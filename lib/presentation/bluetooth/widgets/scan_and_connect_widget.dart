import 'package:flutter/material.dart';
import 'package:ppwd_frontend/data/services/scan_device_service.dart';
import 'package:ppwd_frontend/presentation/bluetooth/widgets/connection_form.dart';
import 'package:ppwd_frontend/presentation/bluetooth/widgets/scanning_tips.dart';

class ScanAndConnectWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final GlobalKey<FormState> formKey;
  final Function(String) onConnect;
  final VoidCallback onDisconnect;

  const ScanAndConnectWidget({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.formKey,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  State<ScanAndConnectWidget> createState() => _ScanAndConnectWidgetState();
}

class _ScanAndConnectWidgetState extends State<ScanAndConnectWidget> {
  String? mac;
  ScanDeviceService scanDeviceService = ScanDeviceService();

  @override
  void initState() {
    scanDeviceService.loadRecentDevices();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect to MetaWear Device',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ConnectionForm(
              controller: widget.controller,
              isConnected: widget.isConnected,
              isConnecting: widget.isConnecting,
              formKey: widget.formKey,
              onConnect: widget.onConnect,
              onDisconnect: widget.onDisconnect,
              onScanPressed: () async {
                mac = await scanDeviceService.startScan();
                if (mac != null) {
                  widget.controller.text = mac!;
                  widget.onConnect(mac!);
                }
              },
            ),
            if (!widget.isConnected && !widget.isConnecting)
              Column(
                children: [
                  const SizedBox(height: 8),

                  ScanningTips(),

                  if (scanDeviceService.recentDevices.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'Recent Devices',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    ...List.generate(
                      scanDeviceService.recentDevices.length,
                      (index) => ListTile(
                        dense: true,
                        title: Text(scanDeviceService.recentDevices[index]),
                        leading: const Icon(Icons.bluetooth, size: 18),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          if (mac != null) {
                            widget.controller.text = mac!;
                            widget.onConnect(mac!);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
