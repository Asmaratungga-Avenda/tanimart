import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/main.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/home_page.dart';
import 'package:tokotani/pages/manage_product_page.dart';
import 'package:tokotani/pages/order_history_page.dart';
import 'package:tokotani/pages/product_catalog_page.dart';
import 'package:tokotani/pages/product_form_page.dart';
import 'package:tokotani/pages/profile_page.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  for (final size in [const Size(400, 800), const Size(1280, 800)]) {
    testWidgets('Navigasi utama sesuai ukuran layar $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(testApp(const MainNavigationPage()));
      await tester.pumpAndSettle();

      expect(find.text('Tani Mart'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Halaman utama tidak overflow pada layar mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final pages = <Widget>[
      const HomePage(),
      const ProductCatalogPage(),
      const CartPage(),
      const OrderHistoryPage(),
      const ProfilePage(),
    ];

    for (final page in pages) {
      await tester.pumpWidget(testApp(page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
    }
  });

  testWidgets('Cart, kelola produk, dan form produk dapat dirender', (tester) async {
    await tester.pumpWidget(testApp(const CartPage()));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang Belanja'), findsOneWidget);

    await tester.pumpWidget(testApp(const ManageProductsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Produk'), findsOneWidget);

    await tester.pumpWidget(testApp(const ProductFormPage()));
    await tester.pumpAndSettle();
    expect(find.text('Nama Produk Pertanian *'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Simpan Produk'),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Simpan Produk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
