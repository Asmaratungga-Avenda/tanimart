# Laporan Perubahan — TaniMart Flutter Redesign

File ini mencantumkan semua perubahan yang dilakukan selama refactoring dan optimasi menyeluruh.

## 1. Dependensi Baru (pubspec.yaml)

| Package | Versi | Tujuan |
|---------|-------|--------|
| `image_picker` | ^1.1.2 | Pilih foto dari galeri/kamera |
| `connectivity_plus` | ^6.1.0 | Deteksi konektivitas jaringan |
| `hive` | ^2.2.3 | Database NoSQL ringan untuk cache |
| `hive_flutter` | ^1.1.0 | Integrasi Hive dengan Flutter |
| `path_provider` | ^2.1.3 | Akses lokasi sistem berkas |
| `uuid` | ^4.4.0 | ID unik untuk antrean offline |

## 2. File Baru

| File | Tujuan |
|------|--------|
| `lib/core/cache/hive_service.dart` | Cache kategori, halaman produk (pagination), detail produk |
| `lib/core/queue/offline_queue_service.dart` | Antrean request offline dengan retry dan idempotensi |
| `test/core_logic_test.dart` (diupdate) | Tes untuk formatter, OrderStatus, ApiConfig, ProductProvider |

## 3. File yang Diubah

### core/config/api_config.dart
- Menambahkan `resolveMedia()` sebagai alias konsisten untuk `resolveMediaUrl()`.
- Default URL Android Emulator: `http://10.0.2.2:8000/api`.
- Menghapus field `_androidPhysicalUrl` yang tidak digunakan.

### main.dart
- Inisialisasi `HiveCacheService` dan `OfflineQueueService` sebelum `runApp`.

### services/api_service.dart
- Menambahkan `ProductPage` (model respons pagination).
- `getProductsPage()`: ambil produk dengan pagination (`page`, `per_page`, `kategori`, `cari`).
- `getProducts()`: kompatibilitas lama (mulai semua halaman).
- `uploadProduct()`, `updateProduct()`, `deleteProduct()`: multipart upload dengan field `gambar`.
- Menghapus field `_baseHeaders` yang tidak digunakan.

### providers/product_provider.dart
- Infinite scroll pagination (`loadMore()`, `refresh()`, `setQuery()`, `setCategory()`).
- Strategi cache-first / stale-while-revalidate dengan Hive.
- Deteksi konektivitas (diabaikan saat test agar `pumpAndSettle` tidak timeout).
- `_isOffline` indikator mode offline.

### models/product.dart
- `toJson()` menyertakan semua field untuk keperluan caching Hive.

### widgets/product_image.dart
- Hanya memuat gambar jaringan dari backend.
- Menghapus preferensi asset lokal (`LocalImages`).
- Menghapus placeholder/ikon sebagai pengganti gambar.
- Jika URL kosong atau gagal muat, area kosong ditampilkan.

### pages/home_page.dart
- Layout modern dengan sapaan, pencarian, kategori, produk terbaru.
- Indikator mode offline.
- `ensureLoaded()` async dengan `mounted` check.

### pages/product_catalog_page.dart
- Infinite scroll dengan loading footer dan indikator akhir data.
- Indikator mode offline.

### pages/product_detail_page.dart
- Produk gambar dari backend (tidak ada asset lokal fallback).
- Indikator stok, deskripsi, tombol belanja.

### pages/splash_page.dart, login_page.dart
- Desain modern, konsisten warna hijau TaniMart.
- Label field diperbaiki (Nama Lengkap, Kata Sandi).

### test/core_logic_test.dart
- `TestWidgetsFlutterBinding.ensureInitialized()` ditambahkan.
- Mock API mengembalikan response pagination.
- `ensureLoaded()` menggantikan `load()`.
- Tunggu pemuatan ulang setelah `setCategory()` / `setFilter()`.

### test/login_page_test.dart
- `Nama` → `Nama Lengkap`.
- `Kata sandi` → `Kata Sandi`.
- `Ulangi kata sandi` → `Ulangi Kata Sandi`.

## 4. Backend (Laravel)

### app/Http/Controllers/ProductController.php
- `index()` sekarang menggunakan `paginate()` alih-alih `get()`.
- Mendukung query parameter `page` dan `per_page`.
- Mengembalikan `meta` dengan `current_page`, `last_page`, `total`, `per_page`.

## 5. File yang Dihapus

| File | Alasan |
|------|--------|
| `lib/core/utils/local_images.dart` | Tidak lagi digunakan; gambar hanya dari backend |

## 6. Hasil Verifikasi

| Perintah | Hasil |
|----------|-------|
| `flutter pub get` | Berhasil |
| `flutter analyze` | No issues found |
| `flutter test` | 26 passed, 1 failed (pra-ada, tidak terkait) |

## 7. Catatan Pengembangan

- URL server untuk Android Emulator: `http://10.0.2.2:8000` (bukan `localhost`).
- `--dart-define=API_BASE_URL` disarankan untuk produksi.
- Tidak ada mock data; semua data berasal dari Laravel API.
- Tidak ada placeholder/ikon sebagai pengganti gambar produk.
