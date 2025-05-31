import 'package:flutter/material.dart';

import '../../../core/models/activity_type.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_shared_preference.dart';
import '../../../data/repositories/board_repository.dart';
import '../services/prediction_service.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  late final PredictionService _service;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int? _currentPrediction;
  DateTime? _lastPredictionTime;
  bool _isConnected = false;
  String? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _service = PredictionService(repository: BoardRepository());
    _initializePage();
  }

  void _initializePage() {
    _loadCachedPrediction();
    _checkConnectionAndStart();
  }

  void _loadCachedPrediction() {
    final lastPrediction = UserSimplePreferences.getLastPrediction();
    final lastTime = UserSimplePreferences.getLastPredictionTime();

    if (lastPrediction != null) {
      setState(() {
        _currentPrediction = lastPrediction;
        _lastPredictionTime = lastTime;
      });
    }
  }

  void _checkConnectionAndStart() {
    final macAddress = UserSimplePreferences.getMacAddress();
    final isConnected = macAddress != null && macAddress.isNotEmpty;

    setState(() {
      _isConnected = isConnected;
      _connectedDevice = macAddress;
    });

    if (isConnected) {
      _startPredictionTimer();
    }
  }

  void _startPredictionTimer() {
    setState(() {
      _isLoading = _currentPrediction == null;
      _hasError = false;
    });

    _service.startTimer(_onPredictionUpdate);
  }

  void _onPredictionUpdate() {
    if (mounted) {
      setState(() {
        _currentPrediction = UserSimplePreferences.getLastPrediction();
        _lastPredictionTime = UserSimplePreferences.getLastPredictionTime();
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  void _refresh() {
    _checkConnectionAndStart();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppTheme.backgroundColor,
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Live Activity Detection"),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.textLightColor,
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildPredictionCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_run, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  "AI Activity Recognition",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Real-time AI detection of your physical activity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            _buildPredictionHeader(),
            const SizedBox(height: 24),
            _buildPredictionContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_run, color: AppTheme.primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          'Current Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionContent() {
    if (!_isConnected) {
      return _buildNoConnectionState();
    } else if (_hasError) {
      return _buildErrorState();
    } else if (_isLoading) {
      return _buildLoadingState();
    } else if (_currentPrediction != null) {
      return _buildPredictionValue();
    } else {
      return _buildWaitingState();
    }
  }

  Widget _buildNoConnectionState() {
    return Column(
      children: [
        Icon(Icons.bluetooth_disabled, color: Colors.grey, size: 64),
        const SizedBox(height: 16),
        Text(
          'No Device Connected',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to a device in the Connect tab to detect activities',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          'Error',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Detecting Activity...',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Column(
      children: [
        Icon(Icons.timer, color: Colors.orange, size: 64),
        const SizedBox(height: 16),
        Text(
          'Waiting for Data',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Collecting sensor data...',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPredictionValue() {
    final isLive = _service.isTimerActive;
    final activityType = ActivityType.fromValue(_currentPrediction!);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _getActivityColor(activityType).withAlpha(25),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: _getActivityColor(activityType),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                _getActivityIcon(activityType),
                size: 72,
                color: _getActivityColor(activityType),
              ),
              Text(
                activityType.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getActivityColor(activityType),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ID: ${_currentPrediction}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(isLive),
            if (_lastPredictionTime != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatTime(_lastPredictionTime!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.check_circle : Icons.access_time,
            size: 16,
            color: isLive ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            isLive ? 'Live' : 'Cached',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLive ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Connection',
              _isConnected ? 'Connected' : 'Not Connected',
              _isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              _isConnected ? Colors.green : Colors.red,
            ),
            if (_isConnected && _connectedDevice != null) ...[
              const SizedBox(height: 8),
              _buildStatusRow(
                'Device',
                _connectedDevice!,
                Icons.device_hub,
                Colors.blue,
              ),
            ],
            const SizedBox(height: 8),
            _buildStatusRow(
              'Live Updates',
              _service.isTimerActive ? 'Active (every 2.5s)' : 'Inactive',
              _service.isTimerActive ? Icons.timer : Icons.timer_off,
              _service.isTimerActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildInfoBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _service.isTimerActive
                  ? 'Getting live activity detection every 2.5 seconds while on this page.'
                  : 'Showing last detected activity. Return to this page for live updates.',
              style: TextStyle(color: Colors.blue[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time).inSeconds;

    if (diff < 60) {
      return '${diff}s ago';
    } else if (diff < 3600) {
      return '${(diff / 60).round()}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getActivityColor(ActivityType activity) {
    switch (activity) {
      case ActivityType.laying:
        return Colors.blue;
      case ActivityType.sitting:
        return Colors.purple;
      case ActivityType.standing:
        return Colors.green;
      case ActivityType.walking:
        return Colors.orange;
      case ActivityType.walkingDownstairs:
        return Colors.red;
      case ActivityType.walkingUpstairs:
        return Colors.indigo;
    }
  }

  IconData _getActivityIcon(ActivityType activity) {
    switch (activity) {
      case ActivityType.laying:
        return Icons.hotel;
      case ActivityType.sitting:
        return Icons.chair;
      case ActivityType.standing:
        return Icons.person;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.walkingDownstairs:
        return Icons.keyboard_arrow_down;
      case ActivityType.walkingUpstairs:
        return Icons.keyboard_arrow_up;
    }
  }
}
