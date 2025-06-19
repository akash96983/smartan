import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'smartan_unsigned';
  static const String apiKey = '567681519639876';
  static const String apiSecret = 'K18INV6es_c6sx25gB28y6otgLY';
  static const String uploadPreset = 'smartan_unsigned';

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (e, st) {
      // Optionally log error
      return null;
    }
  }
}
