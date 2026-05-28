import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<void> sendImage(File imageFile) async {
    var uri = Uri.parse("http://192.168.10.36:8000/predict");

    var request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE: $responseBody");
    } catch (e) {
      print("ERROR: $e");
    }
  }
}