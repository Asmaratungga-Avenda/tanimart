
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/core/config/api_config.dart';
import 'package:tokotani/core/utils/formatters.dart';
import 'package:tokotani/core/utils/order_status.dart';
import 'package:tokotani/models/cart_item.dart';
import 'package:tokotani/models/category.dart';
import 'package:tokotani/models/courier.dart';
import 'package:tokotani/models/payment_method.dart';
import 'package:tokotani/providers/product_provider.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatters', () {
    test('formatRupiah memakai pemisah ribuan', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(12000), 'Rp 12.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('formatDate menerima tanggal API', () {
      expect(formatDate('2026-11-09'), '9 Nov 2026');
      expect(formatDate(null), '-');
    });

    test('formatDateTime memformat tanggal dan waktu secara tepat', () {
      expect(formatDateTime('2026-11-09T17:49:00Z'), isNotNull);
      expect(formatDateTime(null), '-');
      expect(formatDateTime(''), '-');
    });

    test('toApiDate memformat objek DateTime ke format YYYY-MM-DD', () {
      final date = DateTime(2026, 11, 9);
      expect(toApiDate(date), '2026-11-09');
    });
  });

  group('CartItem model', () {
    test('menghitung subtotal dengan benar', () {
      final item = CartItem(
        id: 1,
        produkId: 10,
        nama: 'Tomat Segar',
        harga: 15000,
        jumlah: 3,
        stok: 10,
        satuanJual: 'kg',
      );

      expect(item.subtotal, 45000);
      expect(item.isOutOfStock, isFalse);
      expect(item.hasSufficientStock, isTrue);
    });

    test('validasi stok habis dan batas pesanan', () {
      final itemHabis = CartItem(
        id: 2,
        produkId: 11,
        nama: 'Cabai Rawit',
        harga: 25000,
        jumlah: 2,
        stok: 0,
        satuanJual: 'kg',
      );

      expect(itemHabis.isOutOfStock, isTrue);
      expect(itemHabis.hasSufficientStock, isFalse);
    });

    test('copyWith memperbarui field secara spesifik', () {
      final item = CartItem(
        id: 1,
        produkId: 10,
        nama: 'Tomat Segar',
        harga: 15000,
        jumlah: 1,
        stok: 10,
        satuanJual: 'kg',
      );

      final updated = item.copyWith(jumlah: 5);
      expect(updated.jumlah, 5);
      expect(updated.subtotal, 75000);
      expect(updated.nama, item.nama);
    });

    test('fromJson melakukan sanitasi string dan angka', () {
      final item = CartItem.fromJson({
        'id': '5',
        'produk_id': '12',
        'nama': '  Bayam Hijau  ',
        'harga': '5000',
        'jumlah': '2',
        'stok': '20',
        'satuan_jual': ' ikat ',
      });

      expect(item.id, 5);
      expect(item.produkId, 12);
      expect(item.nama, 'Bayam Hijau');
      expect(item.harga, 5000);
      expect(item.jumlah, 2);
      expect(item.stok, 20);
      expect(item.satuanJual, 'ikat');
      expect(item.subtotal, 10000);
    });
  });

  group('Courier & PaymentMethod models', () {
    test('Courier mengenali gratis ongkir dan sanitasi nama', () {
      final freeCourier = Courier.fromJson({
        'id': 1,
        'nama': '  Ambil di Kebun  ',
        'tarif': 0,
        'aktif': 1,
      });

      expect(freeCourier.nama, 'Ambil di Kebun');
      expect(freeCourier.isGratisOngkir, isTrue);
      expect(freeCourier.aktif, isTrue);

      final regularCourier = Courier.fromJson({
        'id': 2,
        'nama': 'Kurir Standar',
        'tarif': 15000,
        'aktif': 'true',
      });

      expect(regularCourier.isGratisOngkir, isFalse);
      expect(regularCourier.tarif, 15000);
    });

    test('PaymentMethod melakukan parsing dan sanitasi deskripsi', () {
      final payment = PaymentMethod.fromJson({
        'id': 1,
        'nama': '  Transfer Bank  ',
        'deskripsi': '  BCA / Mandiri / BRI  ',
        'aktif': 1,
      });

      expect(payment.nama, 'Transfer Bank');
      expect(payment.deskripsi, 'BCA / Mandiri / BRI');
      expect(payment.aktif, isTrue);
    });
  });

  group('OrderStatus', () {
    test('tombol aksi hanya pada status yang tepat', () {
      expect(OrderStatus.canPay('menunggu_pembayaran'), isTrue);
      expect(OrderStatus.canPay('diproses'), isFalse);
      expect(OrderStatus.canComplete('tiba'), isTrue);
      expect(OrderStatus.canComplete('dikirim'), isTrue);
      expect(OrderStatus.canComplete('diproses'), isFalse);
    });

    test('stepper menandai tahap aktif', () {
      final steps = OrderStatus.stepper('dikirim');
      expect(steps.where((s) => s.current).single.title, 'Dikirim');
      expect(OrderStatus.stepper('dibatalkan').last.failed, isTrue);
    });
  });

  group('ApiConfig.resolveMediaUrl', () {
    test('path relatif diarahkan ke storage server', () {
      final url = ApiConfig.resolveMediaUrl('produk/tomat.jpg');
      expect(url, '${ApiConfig.origin}/storage/produk/tomat.jpg');
    });

    test('category image paths from Laravel resolve to public storage', () {
      final category = ProductCategory.fromJson({
        'id': 8,
        'nama_kategori': 'Sayuran Segar',
        'gambar': 'categories/sayuranSegar/sayuran.jpg',
      });

      expect(
        ApiConfig.resolveMedia(category.gambar),
        '${ApiConfig.origin}/storage/categories/sayuranSegar/sayuran.jpg',
      );
    });

    test('foto kosong menghasilkan null (tanpa foto pengganti)', () {
      expect(ApiConfig.resolveMediaUrl(null), isNull);
      expect(ApiConfig.resolveMediaUrl('  '), isNull);
    });

    test('URL absolut dipertahankan', () {
      expect(
        ApiConfig.resolveMediaUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });
  });

  group('ProductProvider', () {
    setUp(() {
      ApiService.authTokenReader = () async => null;
      ApiService.httpClient = MockClient((request) async {
        final path = request.url.path;
        final query = request.url.queryParameters;
        final page = int.tryParse(query['page'] ?? '1') ?? 1;

        if (path.endsWith('/kategori')) {
          return http.Response(
            jsonEncode({
              'status': 'sukses',
              'code': 200,
              'data': [
                {'id': 1, 'nama': 'Sayuran', 'gambar': null},
                {'id': 2, 'nama': 'Buah', 'gambar': null},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        final allProducts = [
          {
            'id': 1,
            'nama': 'Tomat',
            'harga': 9000,
            'kategori': 'Sayuran',
            'stok': 5,
            'tersedia': true,
            'satuan_jual': 'kg',
            'foto': null,
          },
          {
            'id': 2,
            'nama': 'Apel',
            'harga': 30000,
            'kategori': 'Buah',
            'stok': 0,
            'tersedia': true,
            'satuan_jual': 'kg',
            'foto': null,
          },
        ];

        final start = (page - 1) * 15;
        final pageProducts = allProducts.skip(start).take(15).toList();

        return http.Response(
          jsonEncode({
            'status': 'sukses',
            'code': 200,
            'data': pageProducts,
            'current_page': page,
            'last_page': 1,
            'total': allProducts.length,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    });

    test('memuat sekali lalu memfilter di perangkat', () async {
      final provider = ProductProvider();
      await provider.ensureLoaded();

      expect(provider.all.length, 2);
      expect(provider.categories.map((c) => c.nama), ['Sayuran', 'Buah']);

      provider.setCategory('Buah');
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(provider.filtered.map((p) => p.nama), ['Apel']);

      provider.setFilter(query: 'tom');
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(provider.filtered.map((p) => p.nama), ['Tomat']);

      provider.setSort(ProductSort.priceDesc);
      provider.clearFilter();
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(provider.filtered.first.nama, 'Apel');
    });

    test('produk stok 0 tidak dianggap tersedia', () async {
      final provider = ProductProvider();
      await provider.ensureLoaded();

      expect(provider.all.firstWhere((p) => p.id == 2).isAvailable, isFalse);
      expect(provider.latest().map((p) => p.id), [1]);
    });

    test('refresh gagal tetap mempertahankan produk sebelumnya', () async {
      final provider = ProductProvider();
      await provider.ensureLoaded();

      final produkSebelumnya =
          provider.all.map((p) => p.id).toList();

      ApiService.httpClient = MockClient((request) async {
        throw Exception('Koneksi terputus');
      });

      await provider.refresh();

      expect(
        provider.all.map((p) => p.id).toList(),
        produkSebelumnya,
      );
      expect(
        provider.refreshError,
        'Terjadi gangguan pada sistem. Silakan coba beberapa saat lagi.',
      );
      expect(provider.isRefreshing, isFalse);
    });

    test('produk dapat diurutkan berdasarkan harga dan nama', () async {
      final provider = ProductProvider();
      await provider.ensureLoaded();

      provider.setSort(ProductSort.priceAsc);
      expect(
        provider.filtered.map((p) => p.nama).toList(),
        ['Tomat', 'Apel'],
      );

      provider.setSort(ProductSort.name);
      expect(
        provider.filtered.map((p) => p.nama).toList(),
        ['Apel', 'Tomat'],
      );
    });
  });
}
