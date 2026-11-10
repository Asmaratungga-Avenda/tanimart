import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Satu-satunya sumber konfigurasi koneksi ke Laravel API.
///
/// Pelanggan tidak pernah mengatur alamat server. Developer menentukannya saat
/// build, misalnya:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
///   flutter build apk --dart-define=API_BASE_URL=https://api.tanimart.id/api
class ApiConfig {
  const ApiConfig._();

  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api';
  static const String _localUrl = 'http://127.0.0.1:8000/api';

  static const Duration timeout = Duration(seconds: 15);
  static const Duration checkoutTimeout = Duration(seconds: 30);

  static String get baseUrl {
    final defined = _definedBaseUrl.trim();
    if (defined.isNotEmpty) {
      return defined.endsWith('/')
          ? defined.substring(0, defined.length - 1)
          : defined;
    }
    if (kIsWeb) return _localUrl;
    try {
      if (Platform.isAndroid) return _androidEmulatorUrl;
    } catch (_) {
      // Platform tidak dapat dideteksi; pakai alamat lokal.
    }
    return _localUrl;
  }

  /// Alamat server tanpa akhiran `/api` (dipakai untuk berkas gambar).
  static String get origin {
    final base = baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  static bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  /// Mengubah nilai `foto` dari API menjadi URL yang dapat dibuka perangkat.
  ///
  /// * URL absolut dipakai apa adanya. Bila Laravel mengirim host loopback
  ///   (localhost / 127.0.0.1) padahal API diakses lewat alamat lain (misalnya
  ///   10.0.2.2 pada emulator), host diganti dengan host API.
  /// * Path relatif dianggap berada di `<server>/storage/<path>`.
  static String? resolveMediaUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final lower = value.toLowerCase();
    final isUrl = lower.startsWith('http://') || lower.startsWith('https://');

    if (isUrl) {
      final uri = Uri.tryParse(value);
      final api = Uri.tryParse(baseUrl);
      if (uri != null && api != null && _isLoopback(uri.host)) {
        // Ganti host loopback dengan host API agar bisa diakses dari perangkat luar/emulator.
        // Pastikan port juga ikut disesuaikan jika API menggunakan port khusus.
        return Uri(
          scheme: uri.scheme,
          host: api.host,
          port: api.hasPort ? api.port : (uri.hasPort ? uri.port : null),
          path: uri.path,
          query: uri.hasQuery ? uri.query : null,
        ).toString();
      }
      return value;
    }

    // Untuk path relatif, pastikan mengarah ke direktori storage Laravel yang benar.
    var path = value.startsWith('/') ? value.substring(1) : value;
    if (!path.startsWith('storage/')) {
      path = 'storage/$path';
    }
    return '$origin/$path';
  }
}
