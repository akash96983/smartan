import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String backendUrl = 'http://YOUR_BACKEND_URL/upload'; // Set this when backend is ready

  static Future<String?> getKeypointsFromBackend(File imageFile) async {
    final uri = Uri.parse(backendUrl);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return jsonEncode(data['keypoints']);
      } else {
        return null;
      }
    } catch (e, st) {
      // Optionally log error
      return null;
    }
  }
} 