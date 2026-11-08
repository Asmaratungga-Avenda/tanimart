import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/main.dart';
import 'package:tokotani/pages/cart_page.dart';
import 'package:tokotani/pages/manage_product_page.dart';
import 'package:tokotani/pages/product_form_page.dart';
import 'package:tokotani/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.useMock = true;
  });

  group('Pengujian Tampilan Responsif (Mobile vs Desktop)', () {
    testWidgets('MainFocusedPage tampil proporsional di ukuran Mobile (400x800)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TokoTaniApp());
      await tester.pumpAndSettle();

      expect(find.text('TokoTani'), findsWidgets);
      expect(find.text('Keranjang Belanja'), findsWidgets);
      expect(find.text('Kelola Produk'), findsWidgets);
    });

    testWidgets('MainFocusedPage tampil proporsional di ukuran Desktop (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TokoTaniApp());
      await tester.pumpAndSettle();

      expect(find.text('TokoTani'), findsWidgets);
      expect(find.text('Keranjang Belanja'), findsWidgets);
      expect(find.text('Kelola Produk'), findsWidgets);
    });

    testWidgets('CartPage merender dengan baik di Desktop dan Mobile', (tester) async {
      // Desktop
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keranjang Belanja'), findsOneWidget);
    });

    testWidgets('ManageProductsPage merender dengan baik di Desktop dan Mobile', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ManageProductsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelola Produk'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsOneWidget);
    });

    testWidgets('ProductFormPage merender dengan baik di Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductFormPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Produk Pertanian'), findsOneWidget);
      expect(find.text('Nama Produk Pertanian *'), findsOneWidget);
    });
  });
}

