class ScanHistory {
  final int? id;
  final DateTime scannedAt;
  final String imagePath;
  final String prediction;
  final double confidence;

  const ScanHistory({
    this.id,
    required this.scannedAt,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
  });

  factory ScanHistory.fromMap(Map<String, Object?> map) {
    return ScanHistory(
      id: map['id'] as int?,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      imagePath: map['image_path'] as String,
      prediction: map['prediction'] as String,
      confidence: (map['confidence'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'scanned_at': scannedAt.toIso8601String(),
      'image_path': imagePath,
      'prediction': prediction,
      'confidence': confidence,
    };
  }

  ScanHistory copyWith({
    int? id,
    DateTime? scannedAt,
    String? imagePath,
    String? prediction,
    double? confidence,
  }) {
    return ScanHistory(
      id: id ?? this.id,
      scannedAt: scannedAt ?? this.scannedAt,
      imagePath: imagePath ?? this.imagePath,
      prediction: prediction ?? this.prediction,
      confidence: confidence ?? this.confidence,
    );
  }
}
