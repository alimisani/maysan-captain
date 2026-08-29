import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class R2StorageService {
  static const String accountId = 'c5cdb20e13c1a6d175483b1f9047afda';
  static const String bucketName = 'maysan-captain';
  static const String accessKeyId = '312327f7c67ff369d4363352add28241';
  static const String secretAccessKey = 'bcaf7c8acf44a420a2305949b8bad00c1320fc7261252929188b6df7bfd73aef';
  static const String publicBaseUrl = 'https://pub-259d1465c3aa4a4d99f16bec3816ff43.r2.dev';
  static const String region = 'auto';

  static final String _host = '$accountId.r2.cloudflarestorage.com';

  /// Automatically compress an image Uint8List (< 250 KB) while retaining crisp quality
  static Uint8List compressImage(Uint8List rawBytes, {int maxWidth = 1600, int quality = 75}) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image processed = decoded;
      if (decoded.width > maxWidth || decoded.height > maxWidth) {
        processed = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? maxWidth : null,
          height: decoded.height >= decoded.width ? maxWidth : null,
          interpolation: img.Interpolation.linear,
        );
      }

      final compressed = img.encodeJpg(processed, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return rawBytes;
    }
  }

  /// Uploads a file (auto-compressing images) directly to Cloudflare R2 and returns the public CDN URL
  static Future<String> uploadFile({
    required Uint8List rawBytes,
    required String folder, // e.g. 'verifications', 'avatars', 'vehicles'
    String? customFileName,
    String mimeType = 'image/jpeg',
    bool autoCompress = true,
  }) async {
    try {
      final Uint8List payloadBytes = (autoCompress && mimeType.startsWith('image'))
          ? compressImage(rawBytes)
          : rawBytes;

      final extension = mimeType.contains('pdf') ? 'pdf' : (mimeType.contains('png') ? 'png' : 'jpg');
      final fileName = customFileName ?? '${const Uuid().v4()}.$extension';
      final objectKey = '$folder/$fileName';

      final now = DateTime.now().toUtc();
      final amzDate = _formatAmzDate(now);
      final dateStamp = _formatDateStamp(now);

      final payloadHash = sha256.convert(payloadBytes).toString();
      final canonicalUri = '/$bucketName/$objectKey';

      final canonicalHeaders = 'host:$_host\n'
          'x-amz-content-sha256:$payloadHash\n'
          'x-amz-date:$amzDate\n';
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      final canonicalRequest = 'PUT\n'
          '$canonicalUri\n'
          '\n'
          '$canonicalHeaders\n'
          '$signedHeaders\n'
          '$payloadHash';

      final credentialScope = '$dateStamp/$region/s3/aws4_request';
      final stringToSign = 'AWS4-HMAC-SHA256\n'
          '$amzDate\n'
          '$credentialScope\n'
          '${sha256.convert(utf8.encode(canonicalRequest))}';

      final signingKey = _getSignatureKey(secretAccessKey, dateStamp, region, 's3');
      final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

      final authorization = 'AWS4-HMAC-SHA256 '
          'Credential=$accessKeyId/$credentialScope, '
          'SignedHeaders=$signedHeaders, '
          'Signature=$signature';

      final url = Uri.parse('https://$_host$canonicalUri');
      final response = await http.put(
        url,
        headers: {
          'Host': _host,
          'Content-Type': mimeType,
          'Content-Length': payloadBytes.length.toString(),
          'x-amz-date': amzDate,
          'x-amz-content-sha256': payloadHash,
          'Authorization': authorization,
        },
        body: payloadBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = '$publicBaseUrl/$objectKey';
        debugPrint('Cloudflare R2 upload success: $publicUrl');
        return publicUrl;
      } else {
        debugPrint('Cloudflare R2 upload error (${response.statusCode}): ${response.body}');
        throw Exception('Cloudflare R2 upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('R2StorageService upload error: $e');
      rethrow;
    }
  }

  // --- AWS SigV4 Helper Functions ---

  static String _formatAmzDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateStamp(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  static List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp)).bytes;
    final kRegion = Hmac(sha256, kDate).convert(utf8.encode(regionName)).bytes;
    final kService = Hmac(sha256, kRegion).convert(utf8.encode(serviceName)).bytes;
    return Hmac(sha256, kService).convert(utf8.encode('aws4_request')).bytes;
  }
}
