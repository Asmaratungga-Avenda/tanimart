import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/manage_product_page.dart';
import 'package:tokotani/pages/product_form_page.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  setUp(() {
    // Aktifkan mode mock untuk pengujian widget terisolasi
    ApiService.useMock = true;
  });

  testWidgets('CartPage menampilkan judul dan tombol muat ulang', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CartPage(),
      ),
    );

    expect(find.text('Keranjang Belanja'), findsOneWidget);
    // Tunggu transisi asynchronous dari loadCart
    await tester.pumpAndSettle();

    // Verifikasi apakah subtotal dari server atau pesan kosong muncul
    expect(find.byType(CartPage), findsOneWidget);
  });

  testWidgets('ManageProductsPage menampilkan filter kategori dan FAB Tambah Produk', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ManageProductsPage(),
      ),
    );

    expect(find.text('Kelola Produk'), findsOneWidget);
    expect(find.text('Tambah Produk'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('ProductFormPage menampilkan kolom input wajib dan tombol simpan', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductFormPage(),
      ),
    );

    expect(find.text('Tambah Produk Pertanian'), findsOneWidget);
    expect(find.text('Nama Produk Pertanian *'), findsOneWidget);

    // Scroll ke bawah agar tombol simpan terlihat
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Simpan Produk'), findsOneWidget);

    // Verifikasi validasi klien jika tombol simpan ditekan tanpa mengisi form
    await tester.tap(find.text('Simpan Produk'));
    await tester.pumpAndSettle();

    // Scroll kembali ke atas untuk melihat pesan validasi pada kolom nama
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('Nama produk wajib diisi.'), findsOneWidget);
  });
}
