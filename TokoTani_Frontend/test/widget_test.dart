import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokotani/main.dart';
import 'package:tokotani/views/halamanDetail.dart';

void main() {
  testWidgets('Memuat aplikasi TokoTaniApp dan menampilkan Halaman Katalog', (WidgetTester tester) async {
    // Memuat aplikasi utama
    await tester.pumpWidget(const TokoTaniApp());

    // Memverifikasi judul AppBar 'Produk Pertanian' dan ikon pencarian muncul di halaman katalog
    expect(find.text('Produk Pertanian'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Memuat HalamanDetail produk dan menguji perubahan jumlah pembelian', (WidgetTester tester) async {
    final mockProduk = {
      'id': 1,
      'nama': 'Bayam Hijau Segar',
      'nama_produk': 'Bayam Hijau Segar',
      'harga': 5000,
      'satuan_jual': 'ikat',
      'stok': 10,
      'mudah_rusak': true,
      'deskripsi': 'Bayam segar langsung dari petani lokal.',
    };

    // Render HalamanDetail secara langsung dengan data simulasi produk
    await tester.pumpWidget(
      MaterialApp(
        home: HalamanDetail(produk: mockProduk),
      ),
    );

    // Verifikasi komponen utama di HalamanDetail muncul
    expect(find.text('Rincian Produk'), findsOneWidget);
    expect(find.text('Bayam Hijau Segar'), findsOneWidget);
    expect(find.text('Rp 5000'), findsOneWidget);
    expect(find.text('Tambah ke Keranjang'), findsOneWidget);

    // Verifikasi jumlah beli awal adalah 1
    expect(find.text('1'), findsOneWidget);

    // Tekan tombol tambah jumlah pesanan (+)
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    // Verifikasi jumlah pembelian bertambah menjadi 2
    expect(find.text('2'), findsOneWidget);

    // Tekan tombol kurangi jumlah pesanan (-)
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();

    // Verifikasi kembali menjadi 1
    expect(find.text('1'), findsOneWidget);
  });
}
