class BatchPrediction {
  final String imageName;
  final String prediction;
  final double confidence;

  const BatchPrediction({
    required this.imageName,
    required this.prediction,
    required this.confidence,
  });

  factory BatchPrediction.fromJson(Map<String, dynamic> json) {
    return BatchPrediction(
      imageName: json['image_name'] as String? ?? 'Unnamed image',
      prediction: json['prediction'] as String? ?? 'Not Cell Image',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
    );
  }
}

class BatchSummary {
  final int totalImages;
  final int parasitizedCount;
  final int uninfectedCount;
  final int invalidImagesCount;
  final double infectionPercentage;

  const BatchSummary({
    required this.totalImages,
    required this.parasitizedCount,
    required this.uninfectedCount,
    required this.invalidImagesCount,
    required this.infectionPercentage,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) {
    return BatchSummary(
      totalImages: json['total_images'] as int? ?? 0,
      parasitizedCount: json['parasitized_count'] as int? ?? 0,
      uninfectedCount: json['uninfected_count'] as int? ?? 0,
      invalidImagesCount: json['invalid_images_count'] as int? ?? 0,
      infectionPercentage:
          (json['infection_percentage'] as num? ?? 0).toDouble(),
    );
  }
}

class BatchPredictionResponse {
  final List<BatchPrediction> results;
  final BatchSummary summary;

  const BatchPredictionResponse({
    required this.results,
    required this.summary,
  });

  factory BatchPredictionResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final rawSummary = json['summary'] as Map<String, dynamic>? ?? {};

    return BatchPredictionResponse(
      results: rawResults
          .map((item) => BatchPrediction.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: BatchSummary.fromJson(rawSummary),
    );
  }
}
