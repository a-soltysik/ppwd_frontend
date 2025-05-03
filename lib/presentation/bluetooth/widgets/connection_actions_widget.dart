import 'package:flutter/material.dart';
import 'package:ppwd_frontend/core/theme/app_theme.dart';

class ConnectionActionsWidget extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final bool isNetworkConnected;
  final int cachedRequestsCount;
  final bool isSendingCachedData;
  final VoidCallback onSendCachedData;

  const ConnectionActionsWidget({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.isNetworkConnected,
    required this.cachedRequestsCount,
    required this.isSendingCachedData,
    required this.onSendCachedData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cached data send button
        if (cachedRequestsCount > 0)
          IconButton(
            icon:
                isSendingCachedData
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.sync),
            tooltip: "Send cached data ($cachedRequestsCount)",
            onPressed: isSendingCachedData ? null : onSendCachedData,
          ),
      ],
    );
  }
}

class ConnectButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onConnect;

  const ConnectButton({
    super.key,
    required this.controller,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final mac = controller.text.trim();
        if (mac.isNotEmpty) {
          onConnect();
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
  }
}

class DisconnectButton extends StatelessWidget {
  final VoidCallback onDisconnect;

  const DisconnectButton({super.key, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
