import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

class ApiService {
  static Future<void> sendImage(File imageFile) async {
    var uri = Uri.parse("${ApiConstants.baseUrl}/predict");

    var request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE: $responseBody");
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }
}
