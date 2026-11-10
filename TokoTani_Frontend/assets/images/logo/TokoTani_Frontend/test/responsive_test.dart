import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/home_page.dart';
import 'package:tokotani/pages/main_shell.dart';
import 'package:tokotani/pages/order_history_page.dart';
import 'package:tokotani/pages/product_catalog_page.dart';
import 'package:tokotani/pages/profile_page.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  for (final size in [const Size(360, 640), const Size(400, 800), const Size(1280, 800)]) {
    testWidgets('Kerangka utama tidak overflow pada layar $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(testApp(const MainShell()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Semua halaman tab tidak overflow pada layar mobile', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
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
}
