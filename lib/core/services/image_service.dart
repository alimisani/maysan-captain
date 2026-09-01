import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'r2_storage_service.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image, compress it to ultra-lightweight JPEG, and upload to Cloudflare R2
  static Future<String?> pickAndCompressAvatar({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      // Decode and resize image to optimal 400x400 avatar
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final resized = img.copyResize(
        original,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.linear,
      );

      final compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 75));

      // Upload directly to Cloudflare R2
      try {
        final uid = userId ?? const Uuid().v4();
        final fileName = 'avatar_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final r2Url = await R2StorageService.uploadFile(
          rawBytes: compressedBytes,
          folder: 'avatars',
          customFileName: fileName,
          mimeType: 'image/jpeg',
          autoCompress: false, // already compressed
        );
        return r2Url;
      } catch (e) {
        debugPrint('R2 avatar upload fallback: $e');
        final base64String = base64Encode(compressedBytes);
        return 'data:image/jpeg;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Error picking and compressing avatar: $e');
      return null;
    }
  }

  /// Pick an image, optimize for commercial banner, and upload to Cloudflare R2
  static Future<String?> pickAndUploadBannerImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      // Resize to banner dimensions max 1200 width
      final width = original.width > 1200 ? 1200 : original.width;
      final height = (width * (original.height / original.width)).round();

      final resized = img.copyResize(
        original,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      final compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));

      final id = const Uuid().v4().substring(0, 8);
      final fileName = 'banner_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final r2Url = await R2StorageService.uploadFile(
        rawBytes: compressedBytes,
        folder: 'banners',
        customFileName: fileName,
        mimeType: 'image/jpeg',
        autoCompress: false,
      );
      return r2Url;
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      return null;
    }
  }
}
