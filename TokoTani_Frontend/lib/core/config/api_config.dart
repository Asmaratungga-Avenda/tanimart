import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi terpusat untuk komunikasi REST API TokoTani.
/// Menyesuaikan alamat dasar (base URL) berdasarkan lingkungan target eksekusi.
class ApiConfig {
  /// Base URL untuk emulator resmi Android (mengarahkan localhost host OS).
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';

  /// Base URL untuk peramban web dan desktop (Windows/macOS/Linux).
  static const String localBaseUrl = 'http://127.0.0.1:8000/api';

  /// Base URL untuk pengujian pada perangkat fisik Android/iOS.
  /// Ganti dengan IP lokal Wi-Fi komputer/laptop pengembang (contoh: 192.168.1.10).
  static String physicalDeviceBaseUrl = 'http://192.168.1.10:8000/api';

  /// Kustomisasi alamat dasar yang dapat diubah saat runtime jika diperlukan.
  static String? customBaseUrl;

  /// Mengembalikan Base URL aktif berdasarkan platform yang sedang berjalan.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    if (kIsWeb) {
      return localBaseUrl;
    }

    try {
      if (Platform.isAndroid) {
        // Secara default menggunakan rute loopback emulator Android
        return emulatorBaseUrl;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return localBaseUrl;
      } else if (Platform.isIOS) {
        return localBaseUrl;
      }
    } catch (_) {
      // Fallback aman jika deteksi platform gagal
    }

    return emulatorBaseUrl;
  }

  /// Durasi batas waktu (timeout) permintaan HTTP standar.
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Durasi batas waktu untuk transaksi kompleks seperti checkout.
  static const Duration checkoutTimeout = Duration(seconds: 30);

  /// Header standar untuk seluruh permintaan API.
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Pelanggan-Id': '1',
  };
}

