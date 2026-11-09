import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../models/courier.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../models/product.dart';

/// Empat keadaan layar wajib sesuai ketentuan Rubrik Kriteria 7.
enum KeadaanMuat { memuat, berhasil, kosong, galat }

/// Klasifikasi jenis galat wajib sesuai ketentuan Rubrik Kriteria 6.
enum ApiErrorType {
  connection, // Tidak ada sambungan (server mati / mode pesawat)
  timeout,    // Batas waktu terlampaui (.timeout terpicu)
  validation, // 422 Validasi formulir gagal
  conflict,   // 409 Bentrok keadaan (stok tidak cukup / produk terpakai pada pesanan)
  server,     // 500 Galat internal di sisi server
  notFound,   // 404 Data tidak ditemukan
  other,      // Galat lainnya
}

/// Kelas representasi galat API terstruktur.
/// Tidak membocorkan jejak teknis e.toString() kepada pengguna akhir.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final ApiErrorType errorType;
  final Map<String, dynamic> errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    required this.errorType,
    this.errors = const {},
  });

  /// Mengambil pemetaan pesan galat per kolom untuk validasi HTTP 422.
  Map<String, String> get fieldErrors {
    final result = <String, String>{};
    errors.forEach((key, val) {
      if (val is List && val.isNotEmpty) {
        result[key] = val.first.toString();
      } else if (val != null) {
        result[key] = val.toString();
      }
    });
    return result;
  }

  @override
  String toString() => message;
}

/// Respons keranjang belanja dari server.
/// Subtotal wajib berasal dari respons server, bukan dihitung ulang di Flutter.
class CartResponse {
  final List<CartItem> items;
  final int subtotal;

  const CartResponse({
    required this.items,
    required this.subtotal,
  });
}

class ApiService {
  // Emulator Android memakai http://10.0.2.2:8000/api
  // HP fisik: ganti dengan IP lokal laptop (misal http://192.168.1.10:8000/api)
  // Web/Desktop: http://127.0.0.1:8000/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api';
  }
  static const Duration timeoutDuration = Duration(seconds: 10);
  @visibleForTesting
  static http.Client httpClient = http.Client();

  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // -------------------------------------------------------------
  // HELPER URI & RESPONSE DECODING
  // -------------------------------------------------------------

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.statusCode >= 500
            ? 'Terjadi gangguan pada server internal (500).'
            : 'Format balasan server tidak dapat dibaca.',
        errorType: response.statusCode >= 500 ? ApiErrorType.server : ApiErrorType.other,
      );
    }

    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final isSuccessStatus = body['status'] == 'sukses';
    final isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (!isHttpSuccess || !isSuccessStatus) {
      final code = int.tryParse('${body['code']}') ?? response.statusCode;
      final rawErrors = body['errors'];
      final errorsMap = rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : const <String, dynamic>{};

      ApiErrorType type;
      String defaultMsg;

      switch (code) {
        case 404:
          type = ApiErrorType.notFound;
          defaultMsg = 'Data yang diminta tidak ditemukan.';
          break;
        case 409:
          type = ApiErrorType.conflict;
          defaultMsg = 'Stok tidak mencukupi atau permintaan bertentangan dengan server.';
          break;
        case 422:
          type = ApiErrorType.validation;
          defaultMsg = 'Validasi gagal. Periksa kembali kolom formulir yang bertanda merah.';
          break;
        case 500:
          type = ApiErrorType.server;
          defaultMsg = 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.';
          break;
        default:
          type = ApiErrorType.other;
          defaultMsg = 'Permintaan gagal diproses oleh server.';
      }

      final serverMessage = body['message']?.toString();
      throw ApiException(
        statusCode: code,
        message: (serverMessage != null && serverMessage.trim().isNotEmpty) ? serverMessage : defaultMsg,
        errorType: type,
        errors: errorsMap,
      );
    }

    return body;
  }

  static dynamic _extractData(Map<String, dynamic> body) => body['data'] ?? body;

  static ApiException _invalidResponse(String resource) => ApiException(
        statusCode: 502,
        message: 'Format respons $resource dari server tidak valid.',
        errorType: ApiErrorType.other,
      );

  static List<dynamic> _requireList(dynamic data, String resource) {
    if (data is! List) throw _invalidResponse(resource);
    return data;
  }

  static Map<String, dynamic> _requireMap(dynamic data, String resource) {
    if (data is! Map) throw _invalidResponse(resource);
    return Map<String, dynamic>.from(data);
  }

  static ApiException _handleNetworkError(Object error) {
    if (error is ApiException) return error;

    if (error is TimeoutException) {
      return const ApiException(
        statusCode: 408,
        message: 'Server tidak membalas dalam batas waktu (10 detik). Silakan coba lagi.',
        errorType: ApiErrorType.timeout,
      );
    }

    if (error is SocketException || error is http.ClientException) {
      return const ApiException(
        statusCode: 0,
        message: 'Sambungan ke server gagal. Pastikan server Laravel aktif dan periksa jaringan Anda.',
        errorType: ApiErrorType.connection,
      );
    }

    return const ApiException(
      statusCode: 500,
      message: 'Terjadi gangguan pada sistem. Silakan coba beberapa saat lagi.',
      errorType: ApiErrorType.other,
    );
  }

  // -------------------------------------------------------------
  // ENDPOINT KERANJANG BELANJA (Anggota 5)
  // -------------------------------------------------------------

  /// GET /api/keranjang
  /// Mengambil isi keranjang belanja beserta subtotal yang dihitung oleh server.
  static Future<CartResponse> getCart() async {
    try {
      final response = await httpClient
          .get(_uri('/keranjang'), headers: headers)
          .timeout(timeoutDuration);

      final body = _decodeResponse(response);
      final data = _extractData(body);

      dynamic rawItems;
      dynamic rawSubtotal;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        rawItems = map['items'] ?? map['detail'] ?? map['keranjang'];
        rawSubtotal = map['subtotal'];
      } else if (data is List) {
        rawItems = data;
        rawSubtotal = body['subtotal'];
      } else {
        throw _invalidResponse('keranjang');
      }

      if (rawItems is! List) throw _invalidResponse('keranjang');
      final subtotal = int.tryParse('$rawSubtotal');
      if (subtotal == null || subtotal < 0) throw _invalidResponse('keranjang');
      final items = rawItems
          .map((item) => CartItem.fromJson(_requireMap(item, 'item keranjang')))
          .toList();
      return CartResponse(items: items, subtotal: subtotal);
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/keranjang
  /// Menambah item baru ke keranjang belanja.
  static Future<void> addCart(int produkId, int jumlah) async {
    await _send('POST', '/keranjang', {'produk_id': produkId, 'jumlah': jumlah});
  }

  /// PUT /api/keranjang/{id}
  /// Mengubah jumlah item keranjang.
  /// Server mengembalikan kode 409 bila stok tidak mencukupi,
  /// dan kode 422 bila jumlah <= 0.
  static Future<void> updateCart(int cartId, int jumlah) async {
    await _send('PUT', '/keranjang/$cartId', {'jumlah': jumlah});
  }

  /// DELETE /api/keranjang/{id}
  /// Menghapus satu item dari keranjang belanja.
  static Future<void> deleteCart(int cartId) async {
    await _send('DELETE', '/keranjang/$cartId');
  }

  /// DELETE /api/keranjang
  /// Mengosongkan keranjang melalui API.
  static Future<void> clearCart() async {
    await _send('DELETE', '/keranjang');
  }

  // -------------------------------------------------------------
  // ENDPOINT KELOLA PRODUK (Anggota 5)
  // -------------------------------------------------------------

  /// GET /api/produk
  /// Mendukung parameter ?kategori= dan ?cari= sesuai spesifikasi Kriteria 2.
  static Future<List<Product>> getProducts({String? kategori, String? cari}) async {
    try {
      final queryParams = <String, String>{};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      if (cari != null && cari.trim().isNotEmpty) {
        queryParams['cari'] = cari.trim();
      }

      final uri = _uri('/produk', queryParams.isEmpty ? null : queryParams);
      final response = await httpClient.get(uri, headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);

      final list = data is Map
          ? _requireList(data['data'], 'produk')
          : _requireList(data, 'produk');

      return list.map((e) => Product.fromJson(_requireMap(e, 'produk'))).toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/produk
  /// Menambah produk pertanian baru. Mengembalikan 422 jika validasi gagal.
  static Future<void> createProduct(Map<String, dynamic> payload) async {
    await _send('POST', '/produk', payload);
  }

  /// PUT /api/produk/{id}
  /// Memperbarui data produk pertanian. Mengembalikan 404 bila tidak ada, 422 bila validasi gagal.
  static Future<void> updateProduct(int id, Map<String, dynamic> payload) async {
    await _send('PUT', '/produk/$id', payload);
  }

  /// DELETE /api/produk/{id}
  /// Menghapus produk. Mengembalikan 409 bila produk masih terpakai pada pesanan aktif.
  static Future<void> deleteProduct(int id) async {
    await _send('DELETE', '/produk/$id');
  }

  // -------------------------------------------------------------
  // ENDPOINT CHECKOUT & PENGIRIMAN
  // -------------------------------------------------------------

  /// GET /api/kurir
  static Future<List<Courier>> getCouriers() async {
    try {
      final response = await httpClient.get(_uri('/kurir'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = _requireList(data, 'kurir');
      return list.map((e) => Courier.fromJson(_requireMap(e, 'kurir'))).toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/metode-pembayaran
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await httpClient.get(_uri('/metode-pembayaran'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = _requireList(data, 'metode pembayaran');
      return list.map((e) => PaymentMethod.fromJson(_requireMap(e, 'metode pembayaran'))).toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/produk/{id}
  static Future<Product> getProduct(int id) async {
    try {
      final response = await httpClient.get(_uri('/produk/$id'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      return Product.fromJson(_requireMap(data, 'produk'));
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/kategori
  static Future<List<String>> getCategories() async {
    try {
      final response = await httpClient.get(_uri('/kategori'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = _requireList(data, 'kategori');
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/checkout
  /// Menyertakan header X-Kunci-Idempoten (idempotency key) untuk mencegah duplikasi pesanan.
  static Future<Map<String, dynamic>> checkout(
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    final extra = idempotencyKey != null ? {'X-Kunci-Idempoten': idempotencyKey} : null;
    try {
      final res = await _send('POST', '/checkout', payload, extra);
      return res;
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/pesanan (Riwayat Pesanan)
  static Future<List<OrderModel>> getOrders() async {
    try {
      final response = await httpClient.get(_uri('/pesanan'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = _requireList(data, 'pesanan');
      return list.map((e) => OrderModel.fromJson(_requireMap(e, 'pesanan'))).toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/pesanan/{id} (Rincian Pesanan)
  static Future<OrderModel> getOrder(int id) async {
    try {
      final response = await httpClient.get(_uri('/pesanan/$id'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      return OrderModel.fromJson(_requireMap(data, 'pesanan'));
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// PATCH /api/pesanan/{id}/status
  static Future<OrderModel> updateOrderStatus(int id, String status) async {
    try {
      final res = await _send('PATCH', '/pesanan/$id/status', {'status': status});
      final data = _extractData(res);
      return OrderModel.fromJson(_requireMap(data, 'pesanan'));
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/pesanan/{id}/pembayaran
  /// Meminta backend mengonfirmasi pembayaran pesanan.
  static Future<OrderModel> confirmPayment(int id, int paymentMethodId) async {
    try {
      final response = await _send(
        'POST',
        '/pesanan/$id/pembayaran',
        {'payment_method_id': paymentMethodId},
      );
      final data = _extractData(response);
      if (data is! Map) {
        throw const ApiException(
          statusCode: 500,
          message: 'Respons konfirmasi pembayaran tidak valid.',
          errorType: ApiErrorType.other,
        );
      }
      return OrderModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // -------------------------------------------------------------
  // GENERIC HTTP REQUEST DISPATCHER
  // -------------------------------------------------------------

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? payload,
    Map<String, String>? extraHeaders,
  ]) async {
    try {
      late http.Response response;
      final uri = _uri(path);
      final reqHeaders = extraHeaders != null ? {...headers, ...extraHeaders} : headers;
      final body = payload != null ? jsonEncode(payload) : null;

      switch (method) {
        case 'POST':
          response = await httpClient.post(uri, headers: reqHeaders, body: body).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await httpClient.put(uri, headers: reqHeaders, body: body).timeout(timeoutDuration);
          break;
        case 'PATCH':
          response = await httpClient.patch(uri, headers: reqHeaders, body: body).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await httpClient.delete(uri, headers: reqHeaders).timeout(timeoutDuration);
          break;
        default:
          throw const ApiException(
            statusCode: 405,
            message: 'Metode HTTP tidak didukung.',
            errorType: ApiErrorType.other,
          );
      }

      return _decodeResponse(response);
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // -------------------------------------------------------------
}
