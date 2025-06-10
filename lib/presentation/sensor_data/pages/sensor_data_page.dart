import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/activity_type.dart';
import '../../../core/models/prediction_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/user_shared_preference.dart'; // Dodany import

class SensorDataPage extends StatefulWidget {
  const SensorDataPage({super.key});

  @override
  State<SensorDataPage> createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage>
    with TickerProviderStateMixin {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': AppConstants.apiKey,
      },
    ),
  );

  List<HistoryItem>? _history;
  bool _loading = false;
  String _selectedTimeRange = '5 min';

  final List<TimeRangeOption> _timeRangeOptions = [
    TimeRangeOption('5 min', '5m', const Duration(minutes: 5), Icons.timer),
    TimeRangeOption('1 hour', '1h', const Duration(hours: 1), Icons.schedule),
    TimeRangeOption('1 day', '1d', const Duration(days: 1), Icons.today),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    final macAddress = UserSimplePreferences.getMacAddress();
    if (macAddress == null || macAddress.isEmpty) {
      setState(() {
        _history = null;
        _loading = false;
      });
      return;
    }

    final selectedOption = _timeRangeOptions.firstWhere(
      (option) => option.label == _selectedTimeRange,
    );
    final endDate = DateTime.now();
    final startDate = endDate.subtract(selectedOption.duration);

    try {
      final response = await _dio.get(
        '/api/history',
        queryParameters: {
          'start_date':
              startDate.subtract(const Duration(hours: 2)).toIso8601String(),
          'end_date':
              endDate.subtract(const Duration(hours: 2)).toIso8601String(),
          'mac_address': macAddress,
        },
      );

      if (response.statusCode == 200) {
        final history = HistoryResponse.fromJson(response.data);
        Logger.w(history.predictions.toString());
        setState(() {
          _history = history.predictions;
          _loading = false;
        });
      } else {
        Logger.w(response.toString());
        setState(() {
          _history = null;
          _loading = false;
        });
      }
    } catch (e) {
      Logger.w(e.toString());
      setState(() {
        _history = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Analytics"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textLightColor,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                _loading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadHistory,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeRangeSelector(),
              const SizedBox(height: 12),
              if (_loading)
                _buildLoadingCard()
              else if (_history != null && _history!.isNotEmpty) ...[
                _buildChartCard(),
              ] else
                _buildNoDataCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Time Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children:
                  _timeRangeOptions.map((option) {
                    final isSelected = option.label == _selectedTimeRange;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(
                                  () => _selectedTimeRange = option.label,
                                );
                                _loadHistory();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryColor.withOpacity(
                                                0.8,
                                              ),
                                            ],
                                          )
                                          : null,
                                  color: isSelected ? null : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      option.icon,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option.shortLabel,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey[700],
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final counts = <int, int>{};
    for (final item in _history!) {
      counts[item.prediction] = (counts[item.prediction] ?? 0) + 1;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Activity Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections:
                      counts.entries.map((entry) {
                        final percentage =
                            (entry.value / _history!.length) * 100;
                        final activityType = ActivityType.fromValue(entry.key);
                        final color = _getActivityColor(activityType);

                        return PieChartSectionData(
                          value: percentage,
                          title:
                              '${activityType.displayName}\n${percentage.round()}%',
                          color: color,
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getActivityIcon(activityType),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          badgePositionPercentageOffset: 1.2,
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 50),
            _buildLegend(counts),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<int, int> counts) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          counts.entries.map((entry) {
            final activityType = ActivityType.fromValue(entry.key);
            final color = _getActivityColor(activityType);
            final percentage = (entry.value / _history!.length) * 100;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getActivityIcon(activityType), color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${activityType.displayName} (${percentage.round()}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading Activity Analytics...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    final macAddress = UserSimplePreferences.getMacAddress();
    final isDeviceConnected = macAddress != null && macAddress.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDeviceConnected
                    ? Icons.analytics_outlined
                    : Icons.bluetooth_disabled,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isDeviceConnected
                  ? 'No Activity Data Available'
                  : 'No Device Connected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDeviceConnected
                  ? 'No activity history found for the selected time range.\nTry selecting a different time period or check back later.'
                  : 'Please connect to a device in the Connect tab to view activity analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isDeviceConnected ? _loadHistory : null,
              icon: Icon(
                isDeviceConnected ? Icons.refresh_rounded : Icons.bluetooth,
              ),
              label: Text(isDeviceConnected ? 'Retry' : 'Connect Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityType activity) {
    switch (activity) {
      case ActivityType.laying:
        return const Color(0xFF2196F3); // Blue
      case ActivityType.sitting:
        return const Color(0xFF9C27B0); // Purple
      case ActivityType.standing:
        return const Color(0xFF4CAF50); // Green
      case ActivityType.walking:
        return const Color(0xFFFF9800); // Orange
      case ActivityType.walkingDownstairs:
        return const Color(0xFFF44336); // Red
      case ActivityType.walkingUpstairs:
        return const Color(0xFF3F51B5); // Indigo
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

class TimeRangeOption {
  final String label;
  final String shortLabel;
  final Duration duration;
  final IconData icon;

  TimeRangeOption(this.label, this.shortLabel, this.duration, this.icon);
}
