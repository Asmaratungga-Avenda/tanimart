import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/core/config/api_config.dart';
import 'package:tokotani/core/utils/formatters.dart';
import 'package:tokotani/core/utils/order_status.dart';
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
  });

  group('OrderStatus', () {
    test('tombol aksi hanya pada status yang tepat', () {
      expect(OrderStatus.canPay('menunggu_pembayaran'), isTrue);
      expect(OrderStatus.canPay('diproses'), isFalse);
      expect(OrderStatus.canComplete('tiba'), isTrue);
      expect(OrderStatus.canComplete('dikirim'), isFalse);
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

        // Paginated produk response
        final allProducts = [
          {'id': 1, 'nama': 'Tomat', 'harga': 9000, 'kategori': 'Sayuran', 'stok': 5, 'tersedia': true, 'satuan_jual': 'kg', 'foto': null},
          {'id': 2, 'nama': 'Apel', 'harga': 30000, 'kategori': 'Buah', 'stok': 0, 'tersedia': true, 'satuan_jual': 'kg', 'foto': null},
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
      // Tunggu pemuatan ulang kategori selesai (async).
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
  });
}
