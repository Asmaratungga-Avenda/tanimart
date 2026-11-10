# TokoTani / TaniMart

Sistem jual beli kebutuhan pertanian dan kebutuhan harian. Terdiri dari **Backend Laravel** (REST API + panel admin Filament) dan **Frontend Flutter** (aplikasi pelanggan).

> Proyek ini dikembangkan untuk keperluan pendidikan (UTS mata kuliah PAPB).

## Daftar Isi

1. [Deskripsi Proyek](#1-deskripsi-proyek)
2. [Anggota Kelompok dan Pembagian Tugas](#2-anggota-kelompok-dan-pembagian-tugas)
3. [Fitur Utama](#3-fitur-utama)
4. [Teknologi](#4-teknologi)
5. [Struktur Repositori](#5-struktur-repositori)
6. [Instalasi dan Menjalankan Aplikasi](#6-instalasi-dan-menjalankan-aplikasi)
7. [Akun Uji (Hasil Seeder)](#7-akun-uji-hasil-seeder)
8. [Dokumentasi Endpoint API](#8-dokumentasi-endpoint-api)
9. [Video Demonstrasi](#9-video-demonstrasi)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Deskripsi Proyek

TaniMart adalah aplikasi e-commerce untuk produk pertanian dan kebutuhan harian. Pelanggan dapat melihat katalog, mencari dan memfilter produk, memasukkan produk ke keranjang, melakukan checkout, dan memantau pesanan. Admin mengelola produk dan pesanan melalui panel Filament dan endpoint API khusus admin.

Aplikasi Flutter hanya untuk pelanggan. Tidak ada halaman admin di aplikasi Flutter.

## 2. Anggota Kelompok dan Pembagian Tugas



Setiap anggota memiliki sekurang-kurangnya lima commit bermakna. Kontribusi dapat dilihat di tab **Commits** atau **Insights > Contributors** pada repositori ini.

## 3. Fitur Utama

**Pelanggan (Flutter)**
- Registrasi, login, dan logout (token Sanctum)
- Katalog produk dengan foto, pencarian, filter kategori, pengurutan, dan infinite scroll
- Detail produk, keranjang, checkout, konfirmasi pembayaran, dan riwayat pesanan
- Tema terang, gelap, dan ikut sistem

**Admin (Backend)**
- Kelola produk (tambah, ubah, hapus, unggah foto)
- Kelola pesanan (ubah status, tandai terkirim)

## 4. Teknologi

| Bagian | Teknologi |
|--------|-----------|
| Backend | PHP 8.2+, Laravel, Laravel Sanctum, Filament, MySQL/SQLite |
| Frontend | Flutter, Provider, http, cached_network_image, flutter_secure_storage, shared_preferences |

## 5. Struktur Repositori

```
TokoTani/
├── README.md
├── TokoTani_Backend/     # Laravel API (Sanctum, Filament)
└── TokoTani_Frontend/    # Flutter aplikasi pelanggan
```

## 6. Instalasi dan Menjalankan Aplikasi

### 6.1 Prasyarat

- PHP 8.2+ dan Composer
- MySQL atau SQLite
- Flutter SDK (versi stabil terbaru) dan Android Studio/emulator atau Chrome
- Node.js dan NPM (opsional, hanya untuk build asset)

### 6.2 Backend

```powershell
cd TokoTani_Backend
composer install
cp .env.example .env
php artisan key:generate
```

Atur koneksi database di `.env` (`DB_*`), lalu pastikan `APP_URL=http://127.0.0.1:8000`.

Jalankan migrasi **dan seeder dalam satu perintah**:

```powershell
php artisan migrate:fresh --seed
php artisan serve
```

Seeder mengisi akun admin, akun pelanggan uji, kategori, dan produk contoh. Server berjalan di `http://127.0.0.1:8000`.

Gambar publik disimpan di `TokoTani_Backend/storage/app/public/` dan disertakan di Git. Berkas di `TokoTani_Backend/public/` juga tidak diabaikan Git. Backend menyajikan gambar melalui route `/storage`, jadi tidak perlu menjalankan `php artisan storage:link`.

### 6.3 Frontend

```powershell
cd TokoTani_Frontend
flutter pub get
```

Jalankan dengan menyebut alamat backend:

```powershell
# Chrome / desktop
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

# Emulator Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Gunakan satu jenis host secara konsisten (`127.0.0.1` atau `localhost`, jangan dicampur).

## 7. Akun Uji (Hasil Seeder)

| Peran | Email | Password |
|-------|-------|----------|
| Admin | `admin@tokotani.test` | `password` |
| Pelanggan | `user@tokotani.test` | `password` |

Akun demo hanya dibuat di luar environment production. Ganti password demo sebelum memakai data tersebut untuk keperluan selain development lokal.
Admin juga dapat dibuat atau diatur ulang dengan `php artisan admin:password`.

## 8. Dokumentasi Endpoint API

Base URL: `http://127.0.0.1:8000/api`. Endpoint bertanda "Login" memerlukan header `Authorization: Bearer <token>`.

### Autentikasi

| Metode | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/auth/register` | Publik | Daftar akun pelanggan |
| POST | `/auth/login` | Publik | Masuk dan menerima token |
| GET | `/auth/me` | Login | Profil pengguna |
| POST | `/auth/logout` | Login | Keluar dan hapus token |

### Produk dan Kategori

| Metode | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/produk` | Publik | Daftar produk |
| GET | `/produk/{id}` | Publik | Detail produk |
| GET | `/kategori` | Publik | Daftar kategori |
| POST | `/produk` | Admin | Tambah produk (multipart, dengan foto) |
| PUT | `/produk/{id}` | Admin | Ubah produk |
| DELETE | `/produk/{id}` | Admin | Hapus produk |

### Keranjang

| Metode | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/keranjang` | Login | Isi keranjang |
| POST | `/keranjang` | Login | Tambah produk |
| PUT | `/keranjang/{id}` | Login | Ubah jumlah |
| DELETE | `/keranjang/{id}` | Login | Hapus item |
| DELETE | `/keranjang` | Login | Kosongkan keranjang |

### Checkout dan Pesanan

| Metode | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| POST | `/checkout` | Login | Buat pesanan dari keranjang |
| GET | `/pesanan` | Login | Riwayat pesanan |
| GET | `/pesanan/{id}` | Login | Detail pesanan |
| POST | `/pesanan/{id}/pembayaran` | Login | Konfirmasi pembayaran |
| POST | `/pesanan/{id}/selesai` | Login | Tandai selesai |
| PATCH | `/pesanan/{id}/status` | Admin | Ubah status pesanan |
| POST | `/pesanan/{id}/kirim` | Admin | Tandai dikirim |

### Foto Produk

Foto disimpan di `storage/app/public/products/` dan diakses melalui route Laravel `/storage`. Respons JSON memuat `gambar_url` / `image_url`. Aplikasi Flutter membaca field `foto`, `gambar_url`, atau `image_url`.

### Keamanan

| Aspek | Implementasi |
|-------|--------------|
| Autentikasi | Laravel Sanctum (Bearer token) |
| Penyimpanan token | `flutter_secure_storage` |
| Manajemen produk dan status pesanan | Middleware `admin` |
| Data keranjang dan pesanan | Difilter per `customer_id` |
| Password | Tidak dikirim di respons JSON (`#[Hidden]`) |

## 9. Video Demonstrasi

Tautan video (maksimal 5 menit): **[isi tautan video]**

Isi video:
1. Menjalankan backend (`migrate:fresh --seed`) dan aplikasi Flutter
2. Registrasi dan login pelanggan
3. Katalog: pencarian, filter, dan detail produk
4. Keranjang, checkout, dan konfirmasi pembayaran
5. Riwayat pesanan
6. **Demonstrasi galat**: contoh login dengan password salah, validasi form, atau stok tidak cukup, beserta pesan galat yang tampil
7. Panel admin: kelola produk dan ubah status pesanan

## 10. Troubleshooting

| Masalah | Penyebab dan solusi |
|---------|---------------------|
| Foto produk tidak muncul | Pastikan gambar tersedia di `storage/app/public/`, server hidup, dan `API_BASE_URL` serta `APP_URL` mengarah ke backend |
| Foto diblokir CORS di Flutter web (`No 'Access-Control-Allow-Origin'`) | Pastikan gambar disajikan melalui route Laravel `/storage` dengan header CORS. Jangan buat symlink `public/storage`, karena file statis dapat melewati route tersebut. Setelah mengubah konfigurasi CORS, jalankan `php artisan config:clear` |
| Aplikasi di emulator tidak terhubung | Gunakan `10.0.2.2` sebagai ganti `127.0.0.1` |
| HTTP diblokir di Android | Tambahkan `android:usesCleartextTraffic="true"` pada `AndroidManifest.xml` untuk pengembangan |
| Error 403 pada `/produk` (POST/PUT/DELETE) | Endpoint ini khusus admin. Masuk dengan akun berperan `admin` |
| Dependensi Flutter bermasalah | `flutter clean`, lalu `flutter pub get` |
| Seeder gagal | Pastikan database terkoneksi dan jalankan `php artisan migrate:fresh --seed` dari folder `TokoTani_Backend` |

## Lisensi

Dikembangkan untuk keperluan pendidikan (UTS mata kuliah PAPB).