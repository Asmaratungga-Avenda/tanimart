import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
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
  timeout, // Batas waktu terlampaui (.timeout terpicu)
  validation, // 422 Validasi formulir gagal
  conflict, // 409 Bentrok keadaan (stok tidak cukup / produk terpakai pada pesanan)
  server, // 500 Galat internal di sisi server
  notFound, // 404 Data tidak ditemukan
  other, // Galat lainnya
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

  const CartResponse({required this.items, required this.subtotal});
}

class ApiService {
  // Menggunakan konfigurasi dinamis sesuai platform (Emulator, Device Fisik, atau Localhost)
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration timeoutDuration = ApiConfig.timeoutDuration;

  // Token statis atau ID pelanggan yang disepakati kelompok (sesuai batasan tugas)
  static const Map<String, String> headers = ApiConfig.defaultHeaders;

  /// Flag simulasi data tiruan (Jalur B pada dokumen tugas).
  /// Bernilai false secara default agar seluruh data diambil langsung dari Laravel API (Single Source of Truth).
  static bool useMock = false;

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
        errorType: response.statusCode >= 500
            ? ApiErrorType.server
            : ApiErrorType.other,
      );
    }

    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    // Kompatibel dengan respons dual 'status: sukses' dan 'success: true'
    final isSuccessStatus =
        body['status'] == 'sukses' || body['success'] == true;
    final isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isHttpSuccess || !isSuccessStatus) {
      final code = int.tryParse('${body['code']}') ?? response.statusCode;
      final rawErrors = body['errors'];
      final errorsMap = rawErrors is Map
          ? Map<String, dynamic>.from(rawErrors)
          : const <String, dynamic>{};

      ApiErrorType type;
      String defaultMsg;

      switch (code) {
        case 404:
          type = ApiErrorType.notFound;
          defaultMsg = 'Data yang diminta tidak ditemukan.';
          break;
        case 409:
          type = ApiErrorType.conflict;
          defaultMsg =
              'Stok tidak mencukupi atau permintaan bertentangan dengan server.';
          break;
        case 422:
          type = ApiErrorType.validation;
          defaultMsg =
              'Validasi gagal. Periksa kembali kolom formulir yang bertanda merah.';
          break;
        case 500:
          type = ApiErrorType.server;
          defaultMsg =
              'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.';
          break;
        default:
          type = ApiErrorType.other;
          defaultMsg = 'Permintaan gagal diproses oleh server.';
      }

      final serverMessage = body['message']?.toString();
      throw ApiException(
        statusCode: code,
        message: (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage
            : defaultMsg,
        errorType: type,
        errors: errorsMap,
      );
    }

    return body;
  }

  static dynamic _extractData(Map<String, dynamic> body) =>
      body['data'] ?? body;

  static ApiException _handleNetworkError(Object error) {
    if (error is ApiException) return error;

    if (error is TimeoutException) {
      return const ApiException(
        statusCode: 408,
        message:
            'Server tidak membalas dalam batas waktu (10 detik). Silakan coba lagi.',
        errorType: ApiErrorType.timeout,
      );
    }

    if (error is SocketException || error is http.ClientException) {
      return const ApiException(
        statusCode: 0,
        message:
            'Sambungan ke server gagal. Pastikan server Laravel aktif dan periksa jaringan Anda.',
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
    if (useMock) return _mockGetCart();

    try {
      final response = await http
          .get(_uri('/keranjang'), headers: headers)
          .timeout(timeoutDuration);

      final body = _decodeResponse(response);
      final data = _extractData(body);

      List<CartItem> items = [];
      int subtotal = 0;

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final rawItems =
            map['items'] ?? map['detail'] ?? map['keranjang'] ?? [];
        if (rawItems is List) {
          items = rawItems
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        subtotal = int.tryParse('${map['subtotal'] ?? 0}') ?? 0;
      } else if (data is List) {
        items = data
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        subtotal = int.tryParse('${body['subtotal'] ?? 0}') ?? 0;
      }

      return CartResponse(items: items, subtotal: subtotal);
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/keranjang
  /// Menambah item baru ke keranjang belanja.
  static Future<void> addCart(int produkId, int jumlah) async {
    if (useMock) return _mockAddCart(produkId, jumlah);
    await _send('POST', '/keranjang', {
      'produk_id': produkId,
      'jumlah': jumlah,
    });
  }

  /// PUT /api/keranjang/{id}
  /// Mengubah jumlah item keranjang.
  /// Server mengembalikan kode 409 bila stok tidak mencukupi,
  /// dan kode 422 bila jumlah <= 0.
  static Future<void> updateCart(int cartId, int jumlah) async {
    if (useMock) return _mockUpdateCart(cartId, jumlah);
    await _send('PUT', '/keranjang/$cartId', {'jumlah': jumlah});
  }

  /// DELETE /api/keranjang/{id}
  /// Menghapus satu item dari keranjang belanja.
  static Future<void> deleteCart(int cartId) async {
    if (useMock) return _mockDeleteCart(cartId);
    await _send('DELETE', '/keranjang/$cartId');
  }

  // -------------------------------------------------------------
  // ENDPOINT KELOLA PRODUK (Anggota 5)
  // -------------------------------------------------------------

  /// GET /api/produk
  /// Mendukung parameter ?kategori= dan ?cari= sesuai spesifikasi Kriteria 2.
  static Future<List<Product>> getProducts({
    String? kategori,
    String? cari,
  }) async {
    if (useMock) return _mockGetProducts(kategori: kategori, cari: cari);

    try {
      final queryParams = <String, String>{};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      if (cari != null && cari.trim().isNotEmpty) {
        queryParams['cari'] = cari.trim();
      }

      final uri = _uri('/produk', queryParams.isEmpty ? null : queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);

      final list = data is List
          ? data
          : (data is Map && data['data'] is List
                ? data['data'] as List
                : <dynamic>[]);

      return list
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/kategori
  static Future<List<String>> getCategories() async {
    if (useMock) return _mockGetCategories();

    try {
      final response = await http
          .get(_uri('/kategori'), headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      if (data is! List) return const [];

      return data
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              return '${item['nama_kategori'] ?? item['kategori'] ?? item['nama'] ?? ''}';
            }
            return '';
          })
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// POST /api/produk
  /// Menambah produk pertanian baru. Mengembalikan 422 jika validasi gagal.
  static Future<void> createProduct(Map<String, dynamic> payload) async {
    if (useMock) return _mockCreateProduct(payload);
    await _send('POST', '/produk', payload);
  }

  /// PUT /api/produk/{id}
  /// Memperbarui data produk pertanian. Mengembalikan 404 bila tidak ada, 422 bila validasi gagal.
  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> payload,
  ) async {
    if (useMock) return _mockUpdateProduct(id, payload);
    await _send('PUT', '/produk/$id', payload);
  }

  /// DELETE /api/produk/{id}
  /// Menghapus produk. Mengembalikan 409 bila produk masih terpakai pada pesanan aktif.
  static Future<void> deleteProduct(int id) async {
    if (useMock) return _mockDeleteProduct(id);
    await _send('DELETE', '/produk/$id');
  }

  // -------------------------------------------------------------
  // ENDPOINT KURIR
  // -------------------------------------------------------------

  /// GET /api/kurir
  static Future<List<Courier>> getCouriers() async {
    if (useMock) return _mockGetCouriers();
    try {
      final response = await http
          .get(_uri('/kurir'), headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => Courier.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // -------------------------------------------------------------
  // ENDPOINT METODE PEMBAYARAN
  // -------------------------------------------------------------

  /// GET /api/metode-pembayaran
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    if (useMock) return _mockGetPaymentMethods();
    try {
      final response = await http
          .get(_uri('/metode-pembayaran'), headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => PaymentMethod.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/produk/{id}
  static Future<Product> getProduct(int id) async {
    if (useMock) return _mockGetProduct(id);
    try {
      final response = await http.get(_uri('/produk/$id'), headers: headers).timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      return Product.fromJson(Map<String, dynamic>.from(data));
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
    if (useMock) {
      final mockOrder = await _mockCheckout(payload);
      return {'data': mockOrder.toJson()};
    }
    final reqHeaders = Map<String, String>.from(headers);
    if (idempotencyKey != null) {
      reqHeaders['X-Kunci-Idempoten'] = idempotencyKey;
    }
    try {
      final response = await http
          .post(_uri('/checkout'), headers: reqHeaders, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));
      return _decodeResponse(response);
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // -------------------------------------------------------------
  // ENDPOINT PESANAN
  // -------------------------------------------------------------

  /// GET /api/pesanan (Riwayat Pesanan)
  static Future<List<Order>> getOrders() async {
    if (useMock) return _mockGetOrders();
    try {
      final response = await http
          .get(_uri('/pesanan'), headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/pesanan/{id}
  static Future<Order> getOrderDetail(int id) async {
    if (useMock) return _mockGetOrderDetail(id);
    try {
      final response = await http
          .get(_uri('/pesanan/$id'), headers: headers)
          .timeout(timeoutDuration);
      final body = _decodeResponse(response);
      final data = _extractData(body);
      return Order.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  /// GET /api/pesanan/{id} (Alias)
  static Future<Order> getOrder(int id) => getOrderDetail(id);

  /// PATCH /api/pesanan/{id}/status
  static Future<Order> updateOrderStatus(int id, String status) async {
    if (useMock) return _mockUpdateOrderStatus(id, status);
    final body = await _send('PATCH', '/pesanan/$id/status', {
      'status': status,
    });
    final data = _extractData(body);
    if (data is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'Format balasan server tidak dapat dibaca.',
        errorType: ApiErrorType.other,
      );
    }
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  // -------------------------------------------------------------
  // GENERIC HTTP REQUEST DISPATCHER
  // -------------------------------------------------------------

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      late http.Response response;
      final uri = _uri(path);
      final body = payload != null ? jsonEncode(payload) : null;

      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(timeoutDuration);
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
  // MOCK DATA STORE (Jalur B - Cadangan Pengujian Sisi Flutter)
  // -------------------------------------------------------------

  static final List<Product> _mockProducts = [
    const Product(
      id: 1,
      nama: 'Beras Pandan Wangi Organik',
      harga: 75000,
      kategori: 'Beras & Biji-bijian',
      stok: 25,
      tersedia: true,
      satuanJual: 'pak 5kg',
      mudahRusak: false,
      deskripsi: 'Beras putih alami tanpa pemutih, wangi dan pulen.',
    ),
    const Product(
      id: 2,
      nama: 'Cabai Merah Keriting Segar',
      harga: 32000,
      kategori: 'Bumbu & Rempah',
      stok: 12,
      tersedia: true,
      satuanJual: 'kg',
      mudahRusak: true,
      deskripsi:
          'Cabai segar dipanen langsung dari kebun petani lereng gunung.',
    ),
    const Product(
      id: 3,
      nama: 'Tomat Buah Segar',
      harga: 14000,
      kategori: 'Sayuran',
      stok: 18,
      tersedia: true,
      satuanJual: 'kg',
      mudahRusak: true,
      deskripsi: 'Tomat segar kaya vitamin C, cocok untuk jus dan sambal.',
    ),
    const Product(
      id: 4,
      nama: 'Bawang Merah Brebes Pilihan',
      harga: 38000,
      kategori: 'Bumbu & Rempah',
      stok: 20,
      tersedia: true,
      satuanJual: 'kg',
      mudahRusak: false,
      deskripsi: 'Bawang merah kering berkualitas tinggi, aroma sedap.',
    ),
    const Product(
      id: 5,
      nama: 'Bayam Hijau Hidroponik',
      harga: 6000,
      kategori: 'Sayuran',
      stok: 15,
      tersedia: true,
      satuanJual: 'ikat',
      mudahRusak: true,
      deskripsi: 'Bayam segar hidroponik bebas pestisida kimia.',
    ),
    const Product(
      id: 6,
      nama: 'Kangkung Cabut Segar',
      harga: 5000,
      kategori: 'Sayuran',
      stok: 0, // Produk stok nol untuk menguji penolakan di keranjang
      tersedia: true,
      satuanJual: 'ikat',
      mudahRusak: true,
      deskripsi: 'Kangkung cabut renyah dan segar.',
    ),
    const Product(
      id: 7,
      nama: 'Wortel Brastagi Manis',
      harga: 16000,
      kategori: 'Sayuran',
      stok: 0, // Produk kedua berstok nol sesuai syarat ukuran data
      tersedia: false,
      satuanJual: 'kg',
      mudahRusak: false,
      deskripsi: 'Wortel segar berwarna oranye terang, manis dan renyah.',
    ),
  ];

  static final List<CartItem> _mockCartItems = [
    const CartItem(
      id: 101,
      produkId: 2,
      nama: 'Cabai Merah Keriting Segar',
      harga: 32000,
      jumlah: 2,
      stok: 12,
      satuanJual: 'kg',
      mudahRusak: true,
    ),
    const CartItem(
      id: 102,
      produkId: 5,
      nama: 'Bayam Hijau Hidroponik',
      harga: 6000,
      jumlah: 3,
      stok: 15,
      satuanJual: 'ikat',
      mudahRusak: true,
    ),
  ];

  static Future<CartResponse> _mockGetCart() async {
    await Future.delayed(const Duration(milliseconds: 350));
    final subtotal = _mockCartItems.fold<int>(
      0,
      (sum, item) => sum + (item.harga * item.jumlah),
    );
    return CartResponse(items: List.from(_mockCartItems), subtotal: subtotal);
  }

  static Future<void> _mockAddCart(int produkId, int jumlah) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final product = _mockProducts.firstWhere(
      (p) => p.id == produkId,
      orElse: () => throw const ApiException(
        statusCode: 404,
        message: 'Produk tidak ditemukan.',
        errorType: ApiErrorType.notFound,
      ),
    );

    if (product.stok < jumlah) {
      throw ApiException(
        statusCode: 409,
        message:
            'Stok tidak mencukupi untuk ${product.nama}. Sisa stok: ${product.stok}',
        errorType: ApiErrorType.conflict,
      );
    }

    final existingIndex = _mockCartItems.indexWhere(
      (c) => c.produkId == produkId,
    );
    if (existingIndex >= 0) {
      final current = _mockCartItems[existingIndex];
      final newQty = current.jumlah + jumlah;
      if (newQty > product.stok) {
        throw ApiException(
          statusCode: 409,
          message: 'Stok tidak mencukupi. Sisa stok: ${product.stok}',
          errorType: ApiErrorType.conflict,
        );
      }
      _mockCartItems[existingIndex] = CartItem(
        id: current.id,
        produkId: current.produkId,
        nama: current.nama,
        harga: current.harga,
        jumlah: newQty,
        stok: current.stok,
        satuanJual: current.satuanJual,
        mudahRusak: current.mudahRusak,
      );
    } else {
      _mockCartItems.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch % 10000,
          produkId: product.id,
          nama: product.nama,
          harga: product.harga,
          jumlah: jumlah,
          stok: product.stok,
          satuanJual: product.satuanJual,
          mudahRusak: product.mudahRusak,
        ),
      );
    }
  }

  static Future<void> _mockUpdateCart(int cartId, int jumlah) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (jumlah <= 0) {
      throw const ApiException(
        statusCode: 422,
        message: 'Jumlah item harus lebih dari nol.',
        errorType: ApiErrorType.validation,
      );
    }
    final index = _mockCartItems.indexWhere((c) => c.id == cartId);
    if (index < 0) {
      throw const ApiException(
        statusCode: 404,
        message: 'Item keranjang tidak ditemukan.',
        errorType: ApiErrorType.notFound,
      );
    }
    final item = _mockCartItems[index];
    if (jumlah > item.stok) {
      throw ApiException(
        statusCode: 409,
        message:
            'Stok tidak mencukupi untuk ${item.nama}! Tersedia hanya ${item.stok} ${item.satuanJual}.',
        errorType: ApiErrorType.conflict,
      );
    }
    _mockCartItems[index] = CartItem(
      id: item.id,
      produkId: item.produkId,
      nama: item.nama,
      harga: item.harga,
      jumlah: jumlah,
      stok: item.stok,
      satuanJual: item.satuanJual,
      mudahRusak: item.mudahRusak,
    );
  }

  static Future<void> _mockDeleteCart(int cartId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockCartItems.removeWhere((c) => c.id == cartId);
  }

  static Future<List<Product>> _mockGetProducts({
    String? kategori,
    String? cari,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    var list = List<Product>.from(_mockProducts);
    if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
      list = list
          .where((p) => p.kategori.toLowerCase() == kategori.toLowerCase())
          .toList();
    }
    if (cari != null && cari.trim().isNotEmpty) {
      final q = cari.trim().toLowerCase();
      list = list.where((p) => p.nama.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  static Future<Product> _mockGetProduct(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockProducts.firstWhere(
      (p) => p.id == id,
      orElse: () => throw const ApiException(
        statusCode: 404,
        message: 'Produk tidak ditemukan.',
        errorType: ApiErrorType.notFound,
      ),
    );
  }

  static Future<List<String>> _mockGetCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final categories =
        _mockProducts.map((product) => product.kategori).toSet().toList()
          ..sort();
    return categories;
  }

  static Future<void> _mockCreateProduct(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final errors = <String, dynamic>{};
    if (payload['nama'] == null || '${payload['nama']}'.trim().isEmpty) {
      errors['nama'] = ['Nama produk wajib diisi.'];
    }
    if (payload['harga'] == null ||
        (int.tryParse('${payload['harga']}') ?? 0) <= 0) {
      errors['harga'] = ['Harga produk harus lebih dari 0.'];
    }
    if (payload['stok'] == null ||
        (int.tryParse('${payload['stok']}') ?? -1) < 0) {
      errors['stok'] = ['Stok tidak boleh negatif.'];
    }
    if (payload['satuan_jual'] == null ||
        '${payload['satuan_jual']}'.trim().isEmpty) {
      errors['satuan_jual'] = ['Satuan jual wajib diisi.'];
    }
    if (errors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        message: 'Data produk yang dimasukkan belum lengkap.',
        errorType: ApiErrorType.validation,
        errors: errors,
      );
    }

    final newId =
        (_mockProducts.isEmpty
            ? 1
            : _mockProducts.map((p) => p.id).reduce((a, b) => a > b ? a : b)) +
        1;
    _mockProducts.add(
      Product(
        id: newId,
        nama: payload['nama'],
        harga: int.parse('${payload['harga']}'),
        kategori: payload['kategori'] ?? 'Lainnya',
        stok: int.parse('${payload['stok']}'),
        tersedia: payload['tersedia'] == true || payload['tersedia'] == 1,
        deskripsi: payload['deskripsi'],
        satuanJual: payload['satuan_jual'] ?? 'kg',
        mudahRusak:
            payload['mudah_rusak'] == true || payload['mudah_rusak'] == 1,
      ),
    );
  }

  static Future<void> _mockUpdateProduct(
    int id,
    Map<String, dynamic> payload,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index < 0) {
      throw const ApiException(
        statusCode: 404,
        message: 'Produk tidak ditemukan untuk diperbarui.',
        errorType: ApiErrorType.notFound,
      );
    }

    final errors = <String, dynamic>{};
    if (payload['nama'] == null || '${payload['nama']}'.trim().isEmpty) {
      errors['nama'] = ['Nama produk wajib diisi.'];
    }
    if (payload['harga'] == null ||
        (int.tryParse('${payload['harga']}') ?? 0) <= 0) {
      errors['harga'] = ['Harga produk harus lebih dari 0.'];
    }
    if (payload['stok'] == null ||
        (int.tryParse('${payload['stok']}') ?? -1) < 0) {
      errors['stok'] = ['Stok tidak boleh negatif.'];
    }
    if (errors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        message: 'Periksa kembali isian formulir produk.',
        errorType: ApiErrorType.validation,
        errors: errors,
      );
    }

    final p = _mockProducts[index];
    _mockProducts[index] = Product(
      id: p.id,
      nama: payload['nama'] ?? p.nama,
      harga: int.parse('${payload['harga'] ?? p.harga}'),
      kategori: payload['kategori'] ?? p.kategori,
      stok: int.parse('${payload['stok'] ?? p.stok}'),
      tersedia: payload['tersedia'] == true || payload['tersedia'] == 1,
      deskripsi: payload['deskripsi'],
      satuanJual: payload['satuan_jual'] ?? p.satuanJual,
      mudahRusak: payload['mudah_rusak'] == true || payload['mudah_rusak'] == 1,
    );
  }

  static Future<void> _mockDeleteProduct(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Skenario 409 bila produk masih terkait di pesanan aktif (contoh: id == 1)
    if (id == 1) {
      throw const ApiException(
        statusCode: 409,
        message:
            'Produk tidak dapat dihapus karena masih terpakai pada pesanan aktif.',
        errorType: ApiErrorType.conflict,
      );
    }
    _mockProducts.removeWhere((p) => p.id == id);
  }

  // ---- Mock Kurir ----
  static final List<Courier> _mockCouriers = [
    const Courier(id: 1, nama: 'JNE Regular', tarif: 15000, aktif: true),
    const Courier(id: 2, nama: 'SiCepat HALU', tarif: 12000, aktif: true),
    const Courier(id: 3, nama: 'Gojek Instant', tarif: 25000, aktif: true),
  ];

  static Future<List<Courier>> _mockGetCouriers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockCouriers);
  }

  // ---- Mock Metode Pembayaran ----
  static final List<PaymentMethod> _mockPaymentMethods = [
    const PaymentMethod(id: 1, nama: 'COD (Bayar di Tempat)', aktif: true),
    const PaymentMethod(id: 2, nama: 'Transfer Bank BCA', aktif: true),
    const PaymentMethod(id: 3, nama: 'Transfer Bank BRI', aktif: true),
  ];

  static Future<List<PaymentMethod>> _mockGetPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockPaymentMethods);
  }

  // ---- Mock Pesanan ----
  static final List<Order> _mockOrders = [
    Order(
      id: 1001,
      namaPenerima: 'Budi Santoso',
      alamatPenerima: 'Jl. Merdeka No. 10, Jakarta Pusat',
      kurirId: 1,
      namaCourier: 'JNE Regular',
      paymentMethodId: 1,
      namaPaymentMethod: 'COD (Bayar di Tempat)',
      subtotal: 110000,
      ongkir: 15000,
      totalHarga: 125000,
      status: 'selesai',
      tanggalAntar: '2026-11-01',
      createdAt: '2026-10-31T10:00:00',
      items: [
        const OrderItem(
          id: 1,
          orderId: 1001,
          productId: 1,
          namaProduk: 'Beras Pandan Wangi Organik',
          quantity: 1,
          hargaSatuan: 75000,
          subtotal: 75000,
        ),
        const OrderItem(
          id: 2,
          orderId: 1001,
          productId: 3,
          namaProduk: 'Tomat Buah Segar',
          quantity: 2,
          hargaSatuan: 14000,
          subtotal: 28000,
        ),
        const OrderItem(
          id: 3,
          orderId: 1001,
          productId: 5,
          namaProduk: 'Bayam Hijau Hidroponik',
          quantity: 1,
          hargaSatuan: 6000,
          subtotal: 6000,
        ),
      ],
    ),
    Order(
      id: 1002,
      namaPenerima: 'Siti Rahayu',
      alamatPenerima: 'Jl. Pahlawan No. 25, Bandung',
      kurirId: 2,
      namaCourier: 'SiCepat HALU',
      paymentMethodId: 2,
      namaPaymentMethod: 'Transfer Bank BCA',
      subtotal: 70000,
      ongkir: 12000,
      totalHarga: 82000,
      status: 'dikirim',
      tanggalAntar: '2026-11-07',
      createdAt: '2026-11-06T14:30:00',
      items: [
        const OrderItem(
          id: 4,
          orderId: 1002,
          productId: 2,
          namaProduk: 'Cabai Merah Keriting Segar',
          quantity: 2,
          hargaSatuan: 32000,
          subtotal: 64000,
        ),
        const OrderItem(
          id: 5,
          orderId: 1002,
          productId: 4,
          namaProduk: 'Bawang Merah Brebes Pilihan',
          quantity: 0,
          hargaSatuan: 38000,
          subtotal: 0,
        ),
      ],
    ),
    Order(
      id: 1003,
      namaPenerima: 'Ahmad Fauzi',
      alamatPenerima: 'Jl. Sudirman No. 88, Surabaya',
      kurirId: 3,
      namaCourier: 'Gojek Instant',
      paymentMethodId: 1,
      namaPaymentMethod: 'COD (Bayar di Tempat)',
      subtotal: 38000,
      ongkir: 25000,
      totalHarga: 63000,
      status: 'menunggu_pembayaran',
      tanggalAntar: '2026-11-07',
      createdAt: '2026-11-07T09:00:00',
      items: [
        const OrderItem(
          id: 6,
          orderId: 1003,
          productId: 4,
          namaProduk: 'Bawang Merah Brebes Pilihan',
          quantity: 1,
          hargaSatuan: 38000,
          subtotal: 38000,
        ),
      ],
    ),
  ];

  static Future<List<Order>> _mockGetOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_mockOrders);
  }

  static Future<Order> _mockGetOrderDetail(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockOrders.firstWhere((o) => o.id == id);
    } catch (_) {
      throw const ApiException(
        statusCode: 404,
        message: 'Pesanan tidak ditemukan.',
        errorType: ApiErrorType.notFound,
      );
    }
  }

  static Future<Order> _mockUpdateOrderStatus(int id, String status) async {
    const allowedStatuses = {
      'menunggu_pembayaran',
      'dibayar',
      'diproses',
      'dikirim',
      'selesai',
      'dibatalkan',
    };
    if (!allowedStatuses.contains(status)) {
      throw const ApiException(
        statusCode: 422,
        message: 'Status pesanan tidak valid.',
        errorType: ApiErrorType.validation,
      );
    }

    final index = _mockOrders.indexWhere((order) => order.id == id);
    if (index < 0) {
      throw const ApiException(
        statusCode: 404,
        message: 'Pesanan tidak ditemukan.',
        errorType: ApiErrorType.notFound,
      );
    }

    final updatedOrder = _mockOrders[index].copyWith(status: status);
    _mockOrders[index] = updatedOrder;
    return updatedOrder;
  }

  static int _mockOrderIdCounter = 1004;

  static Future<Order> _mockCheckout(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final errors = <String, dynamic>{};
    if ((payload['nama_penerima'] ?? '').toString().trim().isEmpty) {
      errors['nama_penerima'] = ['Nama penerima wajib diisi.'];
    }
    if ((payload['alamat_penerima'] ?? '').toString().trim().isEmpty) {
      errors['alamat_penerima'] = ['Alamat pengiriman wajib diisi.'];
    }
    if (payload['kurir_id'] == null) {
      errors['kurir_id'] = ['Kurir wajib dipilih.'];
    }
    if (payload['payment_method_id'] == null) {
      errors['payment_method_id'] = ['Metode pembayaran wajib dipilih.'];
    }
    final rawItems = payload['items'];
    if (rawItems == null || rawItems is! List || rawItems.isEmpty) {
      errors['items'] = ['Keranjang tidak boleh kosong.'];
    }
    if (errors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        message: 'Periksa kembali data checkout.',
        errorType: ApiErrorType.validation,
        errors: errors,
      );
    }

    final kurir = _mockCouriers.firstWhere(
      (c) => c.id == payload['kurir_id'],
      orElse: () => _mockCouriers.first,
    );
    final payment = _mockPaymentMethods.firstWhere(
      (p) => p.id == payload['payment_method_id'],
      orElse: () => _mockPaymentMethods.first,
    );

    final items = (rawItems as List).map((item) {
      final productId = item['product_id'] as int;
      final quantity = item['quantity'] as int;
      final product = _mockProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw ApiException(
          statusCode: 404,
          message: 'Produk tidak ditemukan.',
          errorType: ApiErrorType.notFound,
        ),
      );
      return OrderItem(
        id: 0,
        orderId: 0,
        productId: productId,
        namaProduk: product.nama,
        quantity: quantity,
        hargaSatuan: product.harga,
        subtotal: product.harga * quantity,
      );
    }).toList();

    final subtotal = items.fold<int>(0, (s, i) => s + i.subtotal);
    final ongkir = kurir.tarif;
    final newOrder = Order(
      id: _mockOrderIdCounter++,
      namaPenerima: payload['nama_penerima'],
      alamatPenerima: payload['alamat_penerima'],
      kurirId: kurir.id,
      namaCourier: kurir.nama,
      paymentMethodId: payment.id,
      namaPaymentMethod: payment.nama,
      subtotal: subtotal,
      ongkir: ongkir,
      totalHarga: subtotal + ongkir,
      status: 'menunggu_pembayaran',
      tanggalAntar: payload['tanggal_antar'] ?? '',
      createdAt: DateTime.now().toIso8601String(),
      items: items,
    );
    _mockOrders.insert(0, newOrder);
    return newOrder;
  }
}
