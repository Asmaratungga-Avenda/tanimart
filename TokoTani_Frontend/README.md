# TaniMart — Flutter Frontend

Aplikasi Flutter untuk TaniMart (Toko Tani), terintegrasi dengan backend Laravel.

## Struktur Folder

```
lib/
  main.dart              # Titik masuk: inisialisasi Hive, antrean offline, tema
  app.dart               # MultiProvider + AuthGate + MaterialApp
  core/
    config/
      api_config.dart    # Konfigurasi API & resolver URL media (resolveMedia)
    theme/
      app_palette.dart   # Warna semantik (Light/Dark) + ThemeExtension
      app_theme.dart     # Tema Material (light/dark, font Poppins)
    cache/
      hive_service.dart  # Cache kategori, halaman produk, detail produk (Hive)
    queue/
      offline_queue_service.dart  # Antrean request offline (Hive)
    utils/
      cart_actions.dart  # Tambah ke keranjang + snackbar
      category_icon.dart # Ikon kategori
      formatters.dart    # Rupiah, tanggal
      order_status.dart  # Pemetaan status pesanan
      ui.dart            # Snackbar & dialog konfirmasi
  models/
    product.dart, category.dart, cart_item.dart, order.dart,
    courier.dart, payment_method.dart
  pages/
    splash_page.dart, login_page.dart, home_page.dart,
    product_catalog_page.dart, product_detail_page.dart,
    cart_page.dart, checkout_page.dart,
    order_history_page.dart, order_detail_page.dart,
    profile_page.dart, main_shell.dart
  providers/
    auth_provider.dart, product_provider.dart, cart_provider.dart,
    order_provider.dart, theme_provider.dart, navigation_provider.dart
  services/
    api_service.dart     # Semua endpoint REST + multipart upload
    address_store.dart   # Alamat checkout tersimpan (SharedPreferences)
  widgets/
    product_image.dart   # Gambar produk (hanya jaringan, tidak ada ikon fallback)
    product_card.dart, app_button.dart, app_card.dart,
    app_bottom_nav.dart, app_search_field.dart, filter_pill.dart,
    inline_banner.dart, option_tile.dart, quantity_selector.dart,
    section_header.dart, state_views.dart, status_badge.dart, app_logo.dart
```

## Dependensi Baru

| Package | Tujuan |
|---------|--------|
| `image_picker` | Pilih foto dari galeri/kamera |
| `connectivity_plus` | Deteksi konektivitas jaringan |
| `hive` / `hive_flutter` | Cache lokal (kategori, halaman produk, detail produk) |
| `path_provider` | Lokasi penyimpanan Hive |
| `uuid` | ID unik untuk item antrean offline |

## Konfigurasi API

URL API diatur melalui `--dart-define` saat build:

```shell
# Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Android Fisik (ganti IP komputer)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api

# Flutter Web
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api

# Build APK
flutter build apk --dart-define=API_BASE_URL=https://api.tanimart.id/api
```

Jika `--dart-define=API_BASE_URL` tidak diatur, default:
- Android Emulator: `http://10.0.2.2:8000/api`
- Web / Lainnya: `http://127.0.0.1:8000/api`

Resolver URL media (`ApiConfig.resolveMedia()`) otomatis:
- Mengganti host loopback (`localhost`/`127.0.0.1`) dengan host API untuk emulator.
- Menerima path relatif Laravel (ditambahkan awalan `storage/`).
- Mengembalikan `null` bila tidak ada URL (tidak ada placeholder/ikon).

## Menjalankan Aplikasi

```shell
# 1. Instal dependensi
flutter pub get

# 2. Jalankan analisis statis
flutter analyze

# 3. Jalankan tes
flutter test

# 4. Jalankan aplikasi (contoh Android Emulator)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Backend Laravel

Pastikan backend Laravel berjalan dan migrasi telah dijalankan:

```shell
cd TokoTani_Backend
php artisan migrate
php artisan serve --host=0.0.0.0 --port=8000
```

Endpoint yang digunakan:
- `POST /api/auth/login`, `POST /api/auth/register`
- `GET /api/auth/me`, `POST /api/auth/logout`
- `GET /api/produk` (dengan pagination: `?page=1&per_page=15`)
- `GET /api/produk/{id}`
- `GET /api/kategori`
- `GET /api/banners`
- `GET /api/keranjang`, `POST /api/keranjang`, `PUT /api/keranjang/{id}`, `DELETE /api/keranjang/{id}`
- `POST /api/checkout` (dengan header `X-Kunci-Idempoten`)
- `GET /api/pesanan`, `GET /api/pesanan/{id}`
- `POST /api/pesanan/{id}/pembayaran`, `PATCH /api/pesanan/{id}/status`
- `GET /api/kurir`, `GET /api/metode-pembayaran`

Upload gambar produk (admin) menggunakan field `gambar` (multipart).

## Fitur Utama

- Splash screen, login/register dengan validasi
- Beranda dengan pencarian, kategori, dan produk terbaru
- Katalog produk dengan infinite scroll, filter kategori, dan urutan
- Detail produk dengan stok dan tombol belanja
- Keranjang belanja (data subtotal dari server)
- Checkout dengan kurir dan metode pembayaran
- Riwayat pesanan dan detail pesanan
- Profil pengguna (tema light/dark, keluar)
- Upload gambar produk (admin)
- Cache-first / stale-while-revalidate dengan Hive
- Antrean offline dengan auto-sync saat koneksi pulih
- Light mode dan dark mode

## Hasil Tes

```
flutter analyze  -> No issues found
flutter test     -> 26 passed, 1 skipped (pre-existing)
```

## Catatan

- Gambar produk dimuat dari backend Laravel melalui `CachedNetworkImage`.
- Tidak ada placeholder/ikon sebagai pengganti gambar; bila URL kosong, area gambar tetap kosong.
- URL media di-resolve secara konsisten melalui `ApiConfig.resolveMedia()`.
