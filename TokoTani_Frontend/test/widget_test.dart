import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/main.dart';

import 'test_support.dart';

void main() {
  setUp(configureUnavailableApi);

  testWidgets('Aplikasi utama menampilkan navigasi customer', (tester) async {
    await tester.pumpWidget(testApp(const MainNavigationPage()));
    await tester.pumpAndSettle();

    expect(find.text('Tani Mart'), findsOneWidget);
    expect(find.byType(MainNavigationPage), findsOneWidget);
  });

  testWidgets('Menu CRUD tetap dapat dibuka melalui entry point kompatibilitas', (tester) async {
    await tester.pumpWidget(testApp(const MenuPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kelola Produk (CRUD)'), findsOneWidget);
    expect(find.text('Tambah Produk'), findsOneWidget);
  });
}
