import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  // Format Iraqi phone numbers to International format (+964...)
  static String formatIraqiPhone(String phone) {
    var clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('0')) {
      clean = '+964${clean.substring(1)}';
    } else if (clean.startsWith('7') && clean.length == 10) {
      clean = '+964$clean';
    } else if (!clean.startsWith('+')) {
      clean = '+$clean';
    }
    return clean;
  }

  // Open WhatsApp with a pre-filled message
  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    try {
      final formattedPhone = formatIraqiPhone(phone).replaceAll('+', '');
      final encodedMessage = Uri.encodeComponent(message);

      final Uri whatsappAppUri = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$encodedMessage');
      final Uri whatsappWebUri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

      if (await canLaunchUrl(whatsappAppUri)) {
        return await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        return await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      return false;
    }
  }

  // Launch Phone Call
  static Future<bool> makePhoneCall(String phone) async {
    try {
      final clean = phone.replaceAll(' ', '');
      final Uri callUri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(callUri)) {
        return await launchUrl(callUri);
      }
      return false;
    } catch (e) {
      debugPrint('Call error: $e');
      return false;
    }
  }

  // Launch Website URL
  static Future<bool> openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('URL launch error: $e');
      return false;
    }
  }
}
