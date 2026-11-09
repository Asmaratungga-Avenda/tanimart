import 'package:flutter_test/flutter_test.dart';
import 'package:tokotani/main.dart';

void main() {
  testWidgets('Memverifikasi judul dan navigasi utama TokoTani', (WidgetTester tester) async {
    // Membangun aplikasi TokoTani
    await tester.pumpWidget(const TokoTaniApp());

    // Memverifikasi teks judul 'TokoTani' muncul di AppBar
    expect(find.text('TokoTani'), findsWidgets);

    // Memverifikasi dua tab navigasi utama tugas Anggota 5
    expect(find.text('Keranjang Belanja'), findsWidgets);
    expect(find.text('Kelola Produk'), findsWidgets);
  });

  testWidgets('Memverifikasi menu navigasi evaluasi TokoTani', (WidgetTester tester) async {
    // Membangun menu ringkasan tugas
    await tester.pumpWidget(const TokoTaniApp(home: MenuPage()));

    // Memverifikasi teks judul 'TokoTani' muncul
    expect(find.textContaining('TokoTani'), findsWidgets);

    // Memverifikasi kartu navigasi bagian Anggota 5 muncul
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.text('Kelola Produk (CRUD)'), findsOneWidget);
  });
}
