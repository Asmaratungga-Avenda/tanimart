import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/main.dart';

void main() {
  testWidgets('Memverifikasi judul dan navigasi utama terfokus Anggota 5', (WidgetTester tester) async {
    // Membangun aplikasi TokoTani / AgriMart
    await tester.pumpWidget(const TokoTaniApp());

    // Memverifikasi teks judul 'AgriMart' muncul di AppBar
    expect(find.text('AgriMart'), findsWidgets);

    // Memverifikasi dua tab navigasi utama tugas Anggota 5
    expect(find.text('Keranjang Belanja'), findsWidgets);
    expect(find.text('Kelola Produk'), findsWidgets);
  });

  testWidgets('Memverifikasi menu navigasi evaluasi Anggota 5', (WidgetTester tester) async {
    // Membangun menu ringkasan tugas
    await tester.pumpWidget(const TokoTaniApp(home: MenuPage()));

    // Memverifikasi teks judul 'TokoTani' muncul
    expect(find.textContaining('TokoTani'), findsWidgets);

    // Memverifikasi kartu navigasi bagian Anggota 5 muncul
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.text('Kelola Produk (CRUD)'), findsOneWidget);
  });
}
