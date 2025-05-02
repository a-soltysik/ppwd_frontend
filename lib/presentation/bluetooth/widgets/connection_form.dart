import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mac_address_utils.dart';

class ConnectionForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isConnected;
  final bool isConnecting;
  final GlobalKey<FormState> formKey;
  final Function(String) onConnect;
  final VoidCallback onDisconnect;

  const ConnectionForm({
    super.key,
    required this.controller,
    required this.isConnected,
    required this.isConnecting,
    required this.formKey,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: formKey,
          child: MacAddressTextField(
            controller: controller,
            enabled: !isConnected && !isConnecting,
          ),
        ),
        const SizedBox(height: 16),
        if (!isConnected && !isConnecting)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Examples: C1:74:71:F3:94:E0',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        _buildActionButton(context),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!isConnected && !isConnecting) {
      return ElevatedButton(
        onPressed: () {
          final mac = controller.text.trim();
          if (mac.isNotEmpty) {
            onConnect(mac);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a MAC address')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.textLightColor,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_connected),
            SizedBox(width: 8),
            Text(
              "Connect to device",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onDisconnect,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppTheme.disconnectedColor,
          foregroundColor: AppTheme.textLightColor,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Disconnect",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
}
