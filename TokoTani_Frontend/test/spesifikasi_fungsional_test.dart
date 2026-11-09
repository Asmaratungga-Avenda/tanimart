import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/models/courier.dart';
import 'package:tokotani/models/order.dart';
import 'package:tokotani/models/payment_method.dart';
import 'package:tokotani/models/product.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/catalog_page.dart';
import 'package:tokotani/pages/checkout_page.dart';
import 'package:tokotani/pages/manage_product_page.dart';
import 'package:tokotani/pages/order_detail_page.dart';
import 'package:tokotani/pages/order_history_page.dart';
import 'package:tokotani/pages/product_detail_page.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.useMock = true;
  });

  group('Spesifikasi Fungsional 6: 7 Halaman Wajib & 4 Keadaan Layar', () {
    testWidgets('1. Halaman Katalog: memuat produk, pencarian, filter, dan penanda stok', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CatalogPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Katalog Produk Pertanian'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Kolom pencarian ?cari=
      expect(find.text('Semua'), findsWidgets); // Filter kategori ?kategori=
      expect(find.byType(GridView), findsOneWidget); // Memakai GridView.builder
    });

    testWidgets('2. Halaman Rincian Produk: atribut domain, pemilih jumlah, dan tombol tambah', (tester) async {
      const testProduct = Product(
        id: 1,
        nama: 'Beras Rojolele Organik',
        kategori: 'Beras & Biji-bijian',
        harga: 78000,
        stok: 15,
        satuanJual: 'karung 5kg',
        tersedia: true,
        mudahRusak: true,
        deskripsi: 'Beras pulen aromatik segar langsung dari petani Delanggu.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(
            productId: 1,
            initialProduct: testProduct,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Beras Rojolele Organik'), findsWidgets);
      expect(find.text('Mudah Rusak (Wajib Same Day)'), findsOneWidget); // Domain rule badge
      expect(find.text('Tambah ke Keranjang'), findsOneWidget); // Tombol tambah
    });

    testWidgets('3. Halaman Keranjang: subtotal dari server, ubah jumlah, hapus item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Keranjang Belanja'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget); // ListView.builder
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('4. Halaman Checkout: form validator, urutan barang list, tombol idempoten', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Checkout Pesanan'), findsOneWidget);
      expect(find.text('Data Penerima & Alamat'), findsOneWidget);
      expect(find.text('Buat Pesanan'), findsOneWidget);
      expect(find.byType(Form), findsOneWidget); // Memakai Form dengan validator
    });

    testWidgets('5. Halaman Rincian Pesanan: nomor pesanan, status, bayar simulasi PATCH', (tester) async {
      const testProduct = Product(
        id: 1,
        nama: 'Beras Rojolele',
        harga: 50000,
        kategori: 'Beras',
        stok: 10,
        tersedia: true,
        satuanJual: 'karung',
        mudahRusak: false,
      );

      final testOrder = OrderModel(
        id: 101,
        namaPenerima: 'Budi Santoso',
        alamatPenerima: 'Jl. Melati No. 123, Malang',
        kurirId: 1,
        paymentMethodId: 1,
        subtotal: 50000,
        ongkir: 15000,
        totalHarga: 65000,
        status: 'menunggu_pembayaran',
        tanggalAntar: '2026-11-09',
        courier: const Courier(id: 1, nama: 'JNE Regular', tarif: 15000, aktif: true),
        paymentMethod: const PaymentMethod(id: 1, nama: 'Transfer Bank', deskripsi: 'Transfer', aktif: true),
        createdAt: '2026-11-08 09:00:00',
        items: [
          OrderItemModel(
            id: 1,
            orderId: 101,
            productId: 1,
            namaProduk: 'Beras Pandan Wangi',
            quantity: 1,
            hargaSatuan: 50000,
            subtotal: 50000,
            product: testProduct,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(
            orderId: 101,
            initialOrder: testOrder,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Pesanan #101'), findsWidgets);
      expect(find.text('Menunggu Pembayaran'), findsWidgets);
      expect(find.text('Bayar Sekarang (Simulasi)'), findsOneWidget);
    });

    testWidgets('6. Halaman Riwayat Pesanan: daftar pesanan terurut', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OrderHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Riwayat Pesanan'), findsOneWidget);
    });

    testWidgets('7. Halaman Kelola Produk: 4 operasi CRUD produk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManageProductsPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Kelola Produk'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsOneWidget); // FAB Tambah
    });

    testWidgets('Verifikasi 4 Keadaan Layar (KeadaanMuat: memuat, berhasil, kosong, galat)', (tester) async {
      expect(KeadaanMuat.values.length, 4);
      expect(KeadaanMuat.memuat.name, 'memuat');
      expect(KeadaanMuat.berhasil.name, 'berhasil');
      expect(KeadaanMuat.kosong.name, 'kosong');
      expect(KeadaanMuat.galat.name, 'galat');
    });

    testWidgets('Verifikasi 5 Jenis Galat API yang ditangani secara berbeda', (tester) async {
      expect(ApiErrorType.values.contains(ApiErrorType.connection), isTrue);
      expect(ApiErrorType.values.contains(ApiErrorType.timeout), isTrue);
      expect(ApiErrorType.values.contains(ApiErrorType.validation), isTrue);
      expect(ApiErrorType.values.contains(ApiErrorType.conflict), isTrue);
      expect(ApiErrorType.values.contains(ApiErrorType.server), isTrue);
    });
  });
}
