import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tokotani/models/cart_item.dart';
import 'package:tokotani/pages/checkout_page.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  setUp(() {
    ApiService.useMock = true;
  });

  final testItems = [
    const CartItem(
      id: 1,
      produkId: 10,
      nama: 'Beras Pandan Wangi',
      harga: 75000,
      jumlah: 1, // Kuantitas 1 (paling sedikit)
      stok: 10,
      satuanJual: 'pak 5kg',
    ),
    const CartItem(
      id: 2,
      produkId: 20,
      nama: 'Cabai Merah Keriting',
      harga: 32000,
      jumlah: 5, // Kuantitas 5 (paling banyak)
      stok: 15,
      satuanJual: 'kg',
    ),
    const CartItem(
      id: 3,
      produkId: 30,
      nama: 'Bayam Hijau Segar',
      harga: 6000,
      jumlah: 3, // Kuantitas 3 (menengah)
      stok: 20,
      satuanJual: 'ikat',
    ),
  ];

  testWidgets(
    'CheckoutPage menampilkan komponen nama barang, harga, dan jumlah dalam model list ke bawah',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutPage(
            items: testItems,
            subtotal: 75000 * 1 + 32000 * 5 + 6000 * 3,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verifikasi judul halaman
      expect(find.text('Checkout Pesanan'), findsOneWidget);

      // 2. Verifikasi komponen nama barang
      expect(find.text('Beras Pandan Wangi'), findsOneWidget);
      expect(find.text('Cabai Merah Keriting'), findsOneWidget);
      expect(find.text('Bayam Hijau Segar'), findsOneWidget);

      // 3. Verifikasi komponen harga
      expect(find.text('Rp 75.000 / pak 5kg'), findsOneWidget);
      expect(find.text('Rp 32.000 / kg'), findsOneWidget);
      expect(find.text('Rp 6.000 / ikat'), findsOneWidget);

      // 4. Verifikasi komponen jumlah
      expect(find.text('1 pak 5kg'), findsOneWidget);
      expect(find.text('5 kg'), findsOneWidget);
      expect(find.text('3 ikat'), findsOneWidget);
    },
  );

  testWidgets(
    'CheckoutPage mengurutkan barang dari atas sampai bawah sesuai jumlah barang (terbanyak di atas)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CheckoutPage(items: testItems, subtotal: 253000)),
      );

      await tester.pumpAndSettle();

      // Dapatkan posisi vertikal (Y coordinate) masing-masing item di layar
      final top1Finder = find.text('Cabai Merah Keriting'); // jumlah: 5
      final top2Finder = find.text('Bayam Hijau Segar'); // jumlah: 3
      final top3Finder = find.text('Beras Pandan Wangi'); // jumlah: 1

      expect(top1Finder, findsOneWidget);
      expect(top2Finder, findsOneWidget);
      expect(top3Finder, findsOneWidget);

      final y1 = tester.getTopLeft(top1Finder).dy;
      final y2 = tester.getTopLeft(top2Finder).dy;
      final y3 = tester.getTopLeft(top3Finder).dy;

      // Verifikasi urutan vertikal dari atas ke bawah:
      // Cabai (jumlah 5, paling atas: y terkecil)
      // Bayam (jumlah 3, di tengah)
      // Beras (jumlah 1, paling bawah: y terbesar)
      expect(
        y1 < y2,
        isTrue,
        reason: 'Cabai (jumlah 5) harus di atas Bayam (jumlah 3)',
      );
      expect(
        y2 < y3,
        isTrue,
        reason: 'Bayam (jumlah 3) harus di atas Beras (jumlah 1)',
      );
    },
  );

  testWidgets(
    'CheckoutPage dapat mengubah urutan barang dengan tombol Ubah Urutan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CheckoutPage(items: testItems, subtotal: 253000)),
      );

      await tester.pumpAndSettle();

      // Tekan tombol Ubah Urutan untuk membalik ke ascending (tersedikit di atas)
      await tester.ensureVisible(find.text('Ubah Urutan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah Urutan'));
      await tester.pumpAndSettle();

      final top1Finder = find.text('Beras Pandan Wangi'); // jumlah: 1
      final top2Finder = find.text('Bayam Hijau Segar'); // jumlah: 3
      final top3Finder = find.text('Cabai Merah Keriting'); // jumlah: 5

      final y1 = tester.getTopLeft(top1Finder).dy;
      final y2 = tester.getTopLeft(top2Finder).dy;
      final y3 = tester.getTopLeft(top3Finder).dy;

      // Verifikasi setelah toggle: Beras (1) berada di atas Cabai (5)
      expect(
        y1 < y2,
        isTrue,
        reason: 'Beras (jumlah 1) sekarang di atas Bayam (jumlah 3)',
      );
      expect(
        y2 < y3,
        isTrue,
        reason: 'Bayam (jumlah 3) sekarang di atas Cabai (jumlah 5)',
      );
    },
  );
}
