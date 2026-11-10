# TaniMart — Fresh Redesign

Folder project Flutter: `TokoTani_Frontend/`

## Perubahan utama
- Beranda dibangun ulang dengan gaya fresh-market: identitas brand, headline, pencarian, hero promo, kategori dinamis dari produk API, dan grid produk dua kolom.
- Navigasi utama disederhanakan menjadi Beranda, Produk, Keranjang, Pesanan, dan Akun.
- Sistem warna Light/Dark diperbarui ke botanical green dan surface yang lebih bersih.
- Kartu produk pada beranda memakai data produk Laravel, tombol tambah keranjang memanggil CartProvider, dan detail tetap membuka ProductDetailPage.
- Kategori katalog disusun dari kategori produk yang benar-benar diterima dari API, bukan daftar kategori contoh yang dikunci di frontend.
- ProductImage sekarang mengubah path relatif Laravel (`storage/...`, `/storage/...`) menjadi URL pada host API aktif dan menormalisasi URL localhost untuk Android emulator.
- URL API dapat ditentukan saat build melalui `--dart-define=API_BASE_URL=...`.
- Halaman admin/CRUD dan halaman duplikat yang tidak dipakai di alur customer dihapus dari paket frontend.

## Menjalankan
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

Untuk perangkat Android fisik, gunakan IP LAN komputer yang menjalankan Laravel:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```
Ganti alamat contoh dengan IP komputer Anda. Pastikan Laravel dapat diakses dari perangkat dan `php artisan storage:link` sudah dijalankan.

## Catatan validasi
Flutter SDK tidak tersedia pada lingkungan pembuatan paket ini. Karena itu, `flutter analyze`, test, dan runtime Android belum dapat diklaim lulus. Project perlu diverifikasi pada komputer pengembang.
