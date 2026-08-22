import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image and compress it to high-efficiency ultra-compact Base64 URI (< 25 KB)
  static Future<String?> pickAndCompressAvatar({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      // Decode and resize image to exact 240x240 square
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final resized = img.copyResize(
        original,
        width: 240,
        height: 240,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with 65% quality (ultra-lightweight, ~15KB)
      final compressedBytes = img.encodeJpg(resized, quality: 65);

      final base64String = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Error picking and compressing avatar: $e');
      return null;
    }
  }
}
