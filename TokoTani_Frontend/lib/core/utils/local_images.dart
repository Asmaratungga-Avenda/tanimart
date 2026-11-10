import 'package:flutter/services.dart';

/// Resolver gambar lokal dari assets Flutter.
/// Gambar disimpan di assets sehingga selalu tampil tanpa perlu jaringan backend.
class LocalImages {
  static const Map<String, String> _productMap = {
    'kentang': 'assets/images/products/kentang.jpeg',
    'sayuran': 'assets/images/products/sayuran.jpg',
    'wortel': 'assets/images/products/wortel.jpeg',
    'tomat': 'assets/images/products/tomat.jpeg',
    'bawang merah': 'assets/images/products/bawang_merah.jpeg',
    'beras': 'assets/images/products/beras.jpeg',
    'buah': 'assets/images/products/buah.jpeg',
    'cabai rawit': 'assets/images/products/cabai_rawit.jpg',
    'garam': 'assets/images/products/garam.jpeg',
    'minyak sawit': 'assets/images/products/minyak_sawit.jpeg',
    'telur ayam': 'assets/images/products/telur_ayam.jpeg',
    'tepung terigu': 'assets/images/products/tepung_terigu.jpeg',
    'alat siram': 'assets/images/products/alat_siram.jpeg',
    'bibit cabai': 'assets/images/products/bibit_cabai.jpeg',
    'pupuk': 'assets/images/products/pupuk.jpeg',
  };

  static const Map<String, String> _categoryMap = {
    'sayuran segar': 'assets/images/categories/sayuran.jpg',
    'kebutuhan dapur': 'assets/images/categories/cabai_rawit.jpg',
    'kebutuhan tani': 'assets/images/categories/pupuk.jpeg',
  };

  /// Cari asset lokal berdasarkan nama produk.
  static String? forProduct(String? namaProduk) {
    if (namaProduk == null || namaProduk.trim().isEmpty) return null;
    return _productMap[namaProduk.toLowerCase().trim()];
  }

  /// Cari asset lokal berdasarkan nama kategori.
  static String? forCategory(String? namaKategori) {
    if (namaKategori == null || namaKategori.trim().isEmpty) return null;
    return _categoryMap[namaKategori.toLowerCase().trim()];
  }

  /// Cek apakah file asset tersedia di bundle Flutter.
  static Future<bool> exists(String assetPath) async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final entries = (manifest as dynamic)['assets'] as Map?;
    if (entries == null) return false;
    return entries.containsKey(assetPath);
  }
}
