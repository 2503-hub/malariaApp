import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/batch_prediction.dart';
import '../models/chat_message.dart';

class AIService {
  static const String baseUrl = 'http://192.168.198.21:8000';

  static Future<Map<String, dynamic>> predict(XFile image) async {
    final uri = Uri.parse('$baseUrl/predict');
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Prediction failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<BatchPredictionResponse> predictBatch(
    List<XFile> images,
  ) async {
    final uri = Uri.parse('$baseUrl/predict-batch');
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Batch prediction failed: ${response.body}');
    }

    return BatchPredictionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<ChatResponse> chat(String message) async {
    final uri = Uri.parse('$baseUrl/chat');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Chat request failed: ${response.body}');
    }

    return ChatResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
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
}
