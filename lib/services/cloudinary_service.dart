import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'qrezztw4'; // from Cloudinary dashboard
  static const String uploadPreset = 'petbridge_unsigned'; // from Step 2

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final jsonData = json.decode(resBody);
      return jsonData['secure_url']; // this is your image URL to save in Firestore
    } else {
      return null; // upload failed
    }
  }
}