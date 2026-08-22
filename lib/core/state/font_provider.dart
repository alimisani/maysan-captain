import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_font_family';
  String _currentFont = 'ReadexPro';

  String get currentFont => _currentFont;

  static const List<Map<String, String>> availableFonts = [
    {'id': 'ReadexPro', 'nameAr': 'ريدكس برو (الرسمي)', 'nameEn': 'Readex Pro (Official)'},
    {'id': 'Cairo', 'nameAr': 'كايرو', 'nameEn': 'Cairo'},
    {'id': 'Tajawal', 'nameAr': 'تجوال', 'nameEn': 'Tajawal'},
    {'id': 'Amiri', 'nameAr': 'الأميري', 'nameEn': 'Amiri'},
    {'id': 'AdobeArabic', 'nameAr': 'أدوبي عربي', 'nameEn': 'Adobe Arabic'},
    {'id': 'NotoNaskhArabic', 'nameAr': 'نوتو نسخ', 'nameEn': 'Noto Naskh Arabic'},
  ];

  FontProvider() {
    _loadFontPreference();
  }

  Future<void> _loadFontPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && availableFonts.any((f) => f['id'] == saved)) {
        _currentFont = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setFont(String fontId) async {
    if (_currentFont == fontId) return;
    _currentFont = fontId;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, fontId);
    } catch (_) {}
  }
}
