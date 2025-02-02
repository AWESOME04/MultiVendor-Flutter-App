import 'package:crypto/crypto.dart';
import 'dart:convert';

class Config {
  static const String cloudinaryCloudName = 'dat7slh1u';
  static const String cloudinaryUploadPreset = 'multivendor';
  static const String cloudinaryApiKey = '724538952917337';
  static const String cloudinaryApiSecret = 'Cf9-_r9zyBImzqUqIGAs_kObyI8';

  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  static Future<String> generateSignature(int timestamp, String folder) async {
    // Match the exact string format from React implementation
    final stringToSign =
        'folder=$folder&timestamp=$timestamp&upload_preset=$cloudinaryUploadPreset$cloudinaryApiSecret';

    // Use SHA-256 to match React implementation
    final bytes = utf8.encode(stringToSign);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }
}
