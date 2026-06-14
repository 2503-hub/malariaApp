import 'detection_result.dart';

enum ScanAnalysisStatus { pending, completed, failed }

extension ScanAnalysisStatusLabel on ScanAnalysisStatus {
  String get value => switch (this) {
    ScanAnalysisStatus.pending => 'pending',
    ScanAnalysisStatus.completed => 'completed',
    ScanAnalysisStatus.failed => 'failed',
  };

  static ScanAnalysisStatus fromValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'pending' => ScanAnalysisStatus.pending,
      'failed' => ScanAnalysisStatus.failed,
      _ => ScanAnalysisStatus.completed,
    };
  }
}

class ScanHistory {
  static const Object _unset = Object();

  final int? id;
  final DateTime scannedAt;
  final String imagePath;
  final bool isLocalCopy;
  final String prediction;
  final double confidence;
  final DetectionMode detectionMode;
  final ScanAnalysisStatus analysisStatus;
  final String? analysisError;

  const ScanHistory({
    this.id,
    required this.scannedAt,
    required this.imagePath,
    required this.isLocalCopy,
    required this.prediction,
    required this.confidence,
    this.detectionMode = DetectionMode.offline,
    this.analysisStatus = ScanAnalysisStatus.completed,
    this.analysisError,
  });

  factory ScanHistory.fromMap(Map<String, Object?> map) {
    return ScanHistory(
      id: map['id'] as int?,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      imagePath: map['image_path'] as String,
      isLocalCopy: (map['is_local_copy'] as int? ?? 0) == 1,
      prediction: map['prediction'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      detectionMode: detectionModeFromStorageValue(map['detection_mode'] as String?),
      analysisStatus: ScanAnalysisStatusLabel.fromValue(
        map['analysis_status'] as String?,
      ),
      analysisError: map['analysis_error'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'scanned_at': scannedAt.toIso8601String(),
      'image_path': imagePath,
      'is_local_copy': isLocalCopy ? 1 : 0,
      'prediction': prediction,
      'confidence': confidence,
      'detection_mode': detectionMode.storageValue,
      'analysis_status': analysisStatus.value,
      'analysis_error': analysisError,
    };
  }

  ScanHistory copyWith({
    int? id,
    DateTime? scannedAt,
    String? imagePath,
    bool? isLocalCopy,
    String? prediction,
    double? confidence,
    DetectionMode? detectionMode,
    ScanAnalysisStatus? analysisStatus,
    Object? analysisError = _unset,
  }) {
    return ScanHistory(
      id: id ?? this.id,
      scannedAt: scannedAt ?? this.scannedAt,
      imagePath: imagePath ?? this.imagePath,
      isLocalCopy: isLocalCopy ?? this.isLocalCopy,
      prediction: prediction ?? this.prediction,
      confidence: confidence ?? this.confidence,
      detectionMode: detectionMode ?? this.detectionMode,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisError: identical(analysisError, _unset)
          ? this.analysisError
          : analysisError as String?,
    );
  }

  bool get isPending => analysisStatus == ScanAnalysisStatus.pending;
}
