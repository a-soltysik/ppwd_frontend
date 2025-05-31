import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/board.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/user_shared_preference.dart';
import '../../../data/repositories/board_repository.dart';

class PredictionService {
  final BoardRepository _repository;
  final Dio _dio;

  Timer? _timer;

  static const Duration _updateInterval = Duration(
    seconds: 2,
    milliseconds: 500,
  );

  PredictionService({required BoardRepository repository, Dio? dio})
    : _repository = repository,
      _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(
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
  }

  void startTimer(VoidCallback onUpdate) {
    stopTimer();
    _fetchPrediction(onUpdate); // First fetch immediately
    _timer = Timer.periodic(_updateInterval, (_) => _fetchPrediction(onUpdate));
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isTimerActive => _timer?.isActive ?? false;

  Future<int?> _fetchPrediction(VoidCallback onUpdate) async {
    try {
      final measurementsOptional = await _repository.getModuleData(null);

      if (!measurementsOptional.isPresent ||
          measurementsOptional.value.isEmpty) {
        return null;
      }

      final macAddress = UserSimplePreferences.getMacAddress();
      if (macAddress == null) return null;

      final board = Board(macAddress, measurementsOptional.value);
      final prediction = await _callPredictionAPI(board);

      if (prediction != null) {
        UserSimplePreferences.setLastPrediction(prediction);
        UserSimplePreferences.setLastPredictionTime(DateTime.now());
        onUpdate();
      }

      return prediction;
    } catch (e) {
      Logger.e('Error fetching prediction', error: e);
      return null;
    }
  }

  Future<int?> _callPredictionAPI(Board board) async {
    try {
      final response = await _dio.post('/api/predict', data: board.toJson());

      if (response.statusCode == 200) {
        final prediction = response.data['prediction'] as int;
        Logger.d('Prediction received: $prediction');
        return prediction;
      }

      return null;
    } on DioException catch (e) {
      Logger.e('Prediction API exception', error: e.message);
      return null;
    }
  }

  void dispose() {
    stopTimer();
  }
}
