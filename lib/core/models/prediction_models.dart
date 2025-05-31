class PredictionResponse {
  final int prediction;

  PredictionResponse({required this.prediction});

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(prediction: json['prediction'] as int);
  }
}

class HistoryItem {
  final int prediction;
  final String timestamp;

  HistoryItem({required this.prediction, required this.timestamp});

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      prediction: json['prediction'] as int,
      timestamp: json['timestamp'] as String,
    );
  }
}

class HistoryResponse {
  final List<HistoryItem> predictions;

  HistoryResponse({required this.predictions});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['predictions'] as List<dynamic>;
    return HistoryResponse(
      predictions: list.map((item) => HistoryItem.fromJson(item)).toList(),
    );
  }
}
