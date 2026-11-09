import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manajemen mode tema (Light / Dark / System) dengan penyimpanan di SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'agrimart_theme_mode_v1';

  ThemeMode _mode = ThemeMode.system;
  bool _isLoading = true;

  ThemeMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        switch (raw) {
          case 'light':
            _mode = ThemeMode.light;
            break;
          case 'dark':
            _mode = ThemeMode.dark;
            break;
          case 'system':
            _mode = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      _mode = ThemeMode.system;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String value;
      switch (mode) {
        case ThemeMode.light:
          value = 'light';
          break;
        case ThemeMode.dark:
          value = 'dark';
          break;
        case ThemeMode.system:
          value = 'system';
          break;
      }
      await prefs.setString(_storageKey, value);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}
