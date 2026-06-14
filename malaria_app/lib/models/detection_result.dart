enum DetectionMode {
  online,
  offline,
}

extension DetectionModeLabel on DetectionMode {
  String get label {
    return switch (this) {
      DetectionMode.online => 'Online Detection',
      DetectionMode.offline => 'Offline Detection',
    };
  }

  String get shortLabel {
    return switch (this) {
      DetectionMode.online => 'Online',
      DetectionMode.offline => 'Offline',
    };
  }

  String get storageValue => name;
}

DetectionMode detectionModeFromStorageValue(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'online' => DetectionMode.online,
    'offline' => DetectionMode.offline,
    _ => DetectionMode.offline,
  };
}

class DetectionResult {
  const DetectionResult({
    required this.prediction,
    required this.confidence,
    required this.processingTimeMs,
    required this.mode,
    this.modelLoadingTimeMs,
    this.memoryUsageMb,
    this.detail,
  });

  final String prediction;
  final double confidence;
  final int processingTimeMs;
  final DetectionMode mode;
  final int? modelLoadingTimeMs;
  final double? memoryUsageMb;
  final String? detail;

  Map<String, Object?> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
      'processing_time_ms': processingTimeMs,
      'detection_mode': mode.storageValue,
      'model_loading_time_ms': modelLoadingTimeMs,
      'memory_usage_mb': memoryUsageMb,
      'detail': detail,
    };
  }
}
