import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/home_page.dart';
import 'package:tokotani/pages/main_shell.dart';
import 'package:tokotani/pages/order_history_page.dart';
import 'package:tokotani/pages/product_catalog_page.dart';
import 'package:tokotani/pages/profile_page.dart';
import 'package:tokotani/services/api_service.dart';

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

  testWidgets('Nama kategori dua baris tidak overflow di beranda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      ApiService.httpClient.close();
      ApiService.httpClient = http.Client();
      ApiService.authTokenReader = null;
    });

    ApiService.authTokenReader = () async => null;
    ApiService.httpClient = MockClient((request) async {
      final data = request.url.path.endsWith('/kategori')
          ? [
              {'id': 8, 'nama_kategori': 'Sayuran Segar', 'gambar': null},
              {'id': 9, 'nama_kategori': 'Kebutuhan Dapur', 'gambar': null},
            ]
          : <Map<String, dynamic>>[];
      return http.Response(
        jsonEncode({'status': 'sukses', 'code': 200, 'data': data}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(testApp(const HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Kebutuhan Dapur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
