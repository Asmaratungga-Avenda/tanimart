import 'package:flutter_test/flutter_test.dart';
import 'package:tanimart/main.dart';

void main() {
  testWidgets('Memverifikasi judul dan navigasi utama Tani Mart', (WidgetTester tester) async {
    // Membangun aplikasi Tani Mart
    await tester.pumpWidget(const TokoTaniApp());

    // Memverifikasi teks judul 'Tani Mart' muncul di AppBar
    expect(find.text('Tani Mart'), findsWidgets);

    // Memverifikasi dua tab navigasi utama tugas Anggota 5
    expect(find.text('Keranjang Belanja'), findsWidgets);
    expect(find.text('Kelola Produk'), findsWidgets);
  });

  testWidgets('Memverifikasi menu navigasi evaluasi Tani Mart', (WidgetTester tester) async {
    // Membangun menu ringkasan tugas
    await tester.pumpWidget(const TokoTaniApp(home: MenuPage()));

    // Memverifikasi teks judul 'Tani Mart' muncul
    expect(find.textContaining('Tani Mart'), findsWidgets);

    // Memverifikasi kartu navigasi bagian Anggota 5 muncul
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.text('Kelola Produk (CRUD)'), findsOneWidget);
  });
}
