import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AIService {
  static const String baseUrl = 'http://192.168.10.39:8000';

  static Future<Map<String, dynamic>> predict(XFile image) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);
    final bytes = await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: image.name),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Prediction failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
