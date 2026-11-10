import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/pages/main_shell.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  testWidgets('Navigasi bawah hanya memuat lima menu pelanggan', (tester) async {
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    for (final label in ['Beranda', 'Produk', 'Keranjang', 'Pesanan', 'Akun']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Mode Laravel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Setiap tab dapat dibuka tanpa galat', (tester) async {
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    for (final label in ['Produk', 'Pesanan', 'Akun', 'Beranda']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('Tema gelap langsung berlaku tanpa restart', (tester) async {
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Akun').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
