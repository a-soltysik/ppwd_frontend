import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'network_status_widget.dart';

class ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String connectionStatus;
  final String battery;
  final int batteryLevel;
  final bool isServiceRunning;
  final bool isNetworkConnected;
  final int cachedRequestsCount;

  const ConnectionStatusCard({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.connectionStatus,
    required this.battery,
    required this.batteryLevel,
    required this.isServiceRunning,
    required this.isNetworkConnected,
    required this.cachedRequestsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 8),
            Text(connectionStatus),
            if (isConnected) ...[
              const SizedBox(height: 16),
              _buildBatteryIndicator(),
              const SizedBox(height: 8),
              _buildServiceStatusIndicator(),
              const SizedBox(height: 8),
              NetworkStatusWidget(
                isNetworkConnected: isNetworkConnected,
                cachedRequestsCount: cachedRequestsCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Text(
      isConnecting
          ? "Status: Connecting..."
          : "Status: ${isConnected ? 'Connected' : 'Disconnected'}",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color:
            isConnecting
                ? Colors.orange
                : (isConnected ? Colors.green : Colors.red),
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.battery_full,
          color:
              batteryLevel < AppConstants.batteryAlertThreshold
                  ? AppTheme.lowBatteryColor
                  : AppTheme.connectedColor,
        ),
        const SizedBox(width: 8),
        Text(
          "Battery: $battery",
          style: AppTheme.batteryTextStyle(batteryLevel),
        ),
      ],
    );
  }

  Widget _buildServiceStatusIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.trending_up,
          color:
              isServiceRunning
                  ? AppTheme.connectedColor
                  : AppTheme.disconnectedColor,
        ),
        const SizedBox(width: 8),
        Text(
          isServiceRunning
              ? "Background service: Active"
              : "Background service: Inactive",
          style: TextStyle(
            fontSize: 14,
            color:
                isServiceRunning
                    ? AppTheme.connectedColor
                    : AppTheme.disconnectedColor,
          ),
        ),
      ],
    );
  }
}
