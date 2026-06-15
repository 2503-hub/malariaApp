import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import 'auth_service.dart';
import 'on_device_malaria_service.dart';
import '../models/batch_prediction.dart';
import '../models/chat_message.dart';
import '../models/detection_result.dart';

class AIService {
  static Future<DetectionResult> predict(XFile image) async {
    return OnDeviceMalariaService.instance.predict(image);
  }

  static Future<BatchPredictionResponse> predictBatch(
    List<XFile> images,
  ) async {
    final results = await OnDeviceMalariaService.instance.predictMany(images);
    final batchResults = <BatchPrediction>[];

    for (var index = 0; index < results.length; index++) {
      final result = results[index];
      batchResults.add(
        BatchPrediction(
          imageName: images[index].name,
          prediction: result.prediction,
          confidence: result.confidence,
        ),
      );
    }

    return BatchPredictionResponse(
      results: batchResults,
      summary: _summarizeBatch(batchResults),
    );
  }

  static Future<Map<String, dynamic>> predictRemote(XFile image) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/predict');
    final request = http.MultipartRequest('POST', uri);
    final bytes = await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
        contentType: MediaType('image', _mimeSubTypeFor(image.name)),
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Prediction failed: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw Exception('Unable to reach the prediction server.');
    } on http.ClientException {
      throw Exception('Unable to reach the prediction server.');
    } on TimeoutException {
      throw Exception('Prediction request timed out.');
    }
  }

  static Future<BatchPredictionResponse> predictBatchRemote(
    List<XFile> images,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/predict-batch');
    final request = http.MultipartRequest('POST', uri);

    for (final image in images) {
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: image.name,
          contentType: MediaType('image', _mimeSubTypeFor(image.name)),
        ),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 40),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Batch prediction failed: ${response.body}');
      }

      return BatchPredictionResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      throw Exception('Unable to reach the prediction server.');
    } on http.ClientException {
      throw Exception('Unable to reach the prediction server.');
    } on TimeoutException {
      throw Exception('Batch prediction request timed out.');
    }
  }

  static Future<ChatResponse> chat(
    String message, {
    List<ChatMessage> history = const [],
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/chat');
    final recentHistory = history.length > 12
        ? history.sublist(history.length - 12)
        : history;

    try {
      final response = await http
          .post(
            uri,
            headers: await AuthService.instance.authHeaders(),
            body: jsonEncode({
              'message': message,
              'session_id': 'flutter-local-session',
              'history': recentHistory.map((item) => item.toApiJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception(_errorMessageFromResponse(response.body));
      }

      return ChatResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      throw Exception('Unable to reach the health assistant service.');
    } on http.ClientException {
      throw Exception('Unable to reach the health assistant service.');
    } on TimeoutException {
      throw Exception('Health assistant request timed out.');
    }
  }

  static BatchSummary _summarizeBatch(List<BatchPrediction> results) {
    final parasitizedCount =
        results.where((item) => item.prediction == 'Parasitized').length;
    final uninfectedCount =
        results.where((item) => item.prediction == 'Uninfected').length;
    final invalidImagesCount = results
        .where((item) =>
            item.prediction == 'Not Cell Image' || item.prediction == 'Uncertain')
        .length;
    final validTotal = parasitizedCount + uninfectedCount;
    final infectionPercentage =
        validTotal > 0 ? (parasitizedCount / validTotal) * 100 : 0;

    return BatchSummary(
      totalImages: results.length,
      parasitizedCount: parasitizedCount,
      uninfectedCount: uninfectedCount,
      invalidImagesCount: invalidImagesCount,
      infectionPercentage: double.parse(infectionPercentage.toStringAsFixed(2)),
    );
  }

  static String _mimeSubTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    final mimeMap = {
      'jpg': 'jpeg',
      'jpeg': 'jpeg',
      'png': 'png',
      'gif': 'gif',
      'webp': 'webp',
      'bmp': 'bmp',
    };

    return mimeMap[ext] ?? 'jpeg';
  }

  static String _errorMessageFromResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['detail']?.toString() ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
