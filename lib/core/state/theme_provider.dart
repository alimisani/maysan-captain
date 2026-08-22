import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'is_dark_mode';
  bool _isDark = true; // Default Aurora Dark Mode

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefKey) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _isDark);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDark = isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _isDark);
    } catch (_) {}
  }
}
