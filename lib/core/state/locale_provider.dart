import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';
  Locale _locale = const Locale('ar'); // Default Arabic for Maysan

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LocaleProvider() {
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'ar' || savedCode == 'en')) {
        _locale = Locale(savedCode);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(next);
  }
}
