import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode tema (Terang / Gelap / Sistem) yang tersimpan setelah aplikasi ditutup.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode initialMode = ThemeMode.system})
    : _mode = initialMode;

  // Kunci lama dipertahankan agar pilihan pengguna sebelumnya tetap terbaca.
  static const String _storageKey = 'agrimart_theme_mode_v1';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Dipanggil di `main()` sebelum `runApp` agar tema benar sejak frame pertama.
  static Future<ThemeMode> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_storageKey)) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (_) {
      // Penyimpanan gagal: tema tetap berlaku untuk sesi ini.
    }
  }
}
