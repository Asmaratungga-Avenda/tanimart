import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  // Basis URL default. Jika memakai HP fisik asli, isi customBaseUrl dengan IP LAN komputer Anda
  // Contoh: ApiService.customBaseUrl = 'http://192.168.1.10:8000/api';
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  // Fungsi untuk mengambil data Katalog Produk (Sesuai tugas Anggota 1)
  static Future<List<dynamic>> getProduk() async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$baseUrl/produk');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(responseBody);

        List<dynamic> listProduk = [];
        if (decoded is List) {
          listProduk = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          listProduk = decoded['data'];
        }

        // Normalisasi key agar nama produk terbaca di seluruh halaman UI (nama -> nama_produk)
        return listProduk.map((item) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            if (!map.containsKey('nama_produk') && map.containsKey('nama')) {
              map['nama_produk'] = map['nama'];
            }
            return map;
          }
          return item;
        }).toList();
      } else {
        throw Exception('Server merespons status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke backend ($baseUrl).\n'
        'Pastikan server Laravel aktif (php artisan serve).\n'
        'Detail: $e'
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    } finally {
      client?.close();
    }
  }

  // Fungsi untuk mengambil rincian satu produk berdasarkan ID
  static Future<Map<String, dynamic>> getProdukDetail(int id) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$baseUrl/produk/$id');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dynamic decoded = jsonDecode(responseBody);

        Map<String, dynamic> item = {};
        if (decoded is Map && decoded.containsKey('data') && decoded['data'] is Map) {
          item = Map<String, dynamic>.from(decoded['data']);
        } else if (decoded is Map) {
          item = Map<String, dynamic>.from(decoded);
        }

        if (!item.containsKey('nama_produk') && item.containsKey('nama')) {
          item['nama_produk'] = item['nama'];
        }
        return item;
      } else {
        throw Exception('Gagal memuat detail produk (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    } finally {
      client?.close();
    }
  }
}
