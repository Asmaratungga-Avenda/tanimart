# 🌾 TokoTani / TaniMart

Sistem jual beli kebutuhan pertanian dan harian yang terdiri dari **Backend Laravel** (API REST) dan **Frontend Flutter** (aplikasi pelanggan).

---

## 📁 Struktur Repositori

```
TokoTani/
├── README.md
├── TokoTani_Backend/     # Laravel API (Sanctum, Filament admin panel)
└── TokoTani_Frontend/    # Flutter aplikasi pelanggan
```

---

## 🚀 Backend (Laravel)

Lokasi: `TokoTani_Backend/`

### Teknologi
- PHP + Laravel Framework
- Laravel Sanctum (Autentikasi Token)
- Filament (Panel Admin)
- MySQL / SQLite (Database)
- Storage Public (Foto Produk)

### Persyaratan
- PHP 8.2+
- Composer
- Node.js & NPM (opsional, untuk build asset)

### Instalasi

```powershell
# Masuk ke folder backend
cd TokoTani_Backend

# Install dependensi PHP
composer install

# Salin contoh environment
cp .env.example .env

# Generate application key
php artisan key:generate

# Jalankan migrasi database
php artisan migrate

# Buat symlink storage agar foto produk bisa diakses (WAJIB)
php artisan storage:link
```

### Buat Akun Admin

```powershell
php artisan admin:password
```

Ikuti petunjuk di terminal untuk menetapkan email dan password admin. Hanya akun dengan role `admin` yang dapat menambahkan, mengedit, dan menghapus produk.

### Jalankan Server

```powershell
php artisan serve
```

Server akan berjalan di `http://127.0.0.1:8000` (default).

---

## 📱 Frontend (Flutter)

Lokasi: `TokoTani_Frontend/`

### Teknologi
- Flutter SDK
- Provider (State Management)
- HTTP (Komunikasi API)
- cached_network_image (Tampilkan Foto Produk)
- flutter_secure_storage (Simpan Token Aman)
- shared_preferences

### Instalasi

```powershell
# Masuk ke folder frontend
cd TokoTani_Frontend

# Install dependensi
flutter pub get

# Jalankan aplikasi
flutter run
```

### Konfigurasi Alamat Server

Atur `API_BASE_URL` saat menjalankan Flutter:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Untuk emulator Android, gunakan biasanya:
```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

---

## 🔌 Endpoint API (Backend)

### Autentikasi (Publik)

| Metode | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/auth/register` | Daftar akun pelanggan (role otomatis `customer`) |
| POST | `/api/auth/login` | Masuk, menerima token Sanctum |
| GET | `/api/auth/me` | Data profil pengguna (butuh token) |
| POST | `/api/auth/logout` | Keluar / hapus token (butuh token) |

### Produk

| Metode | Endpoint | Akses | Deskripsi |
|--------|----------|-------|-----------|
| GET | `/api/produk` | Publik | Daftar produk (dengan foto) |
| GET | `/api/produk/{id}` | Publik | Detail produk (dengan foto) |
| GET | `/api/kategori` | Publik | Daftar kategori |
| POST | `/api/produk` | Admin | Tambah produk baru (dengan foto via multipart) |
| PUT | `/api/produk/{id}` | Admin | Edit produk (termasuk ganti foto) |
| DELETE | `/api/produk/{id}` | Admin | Hapus produk |

### Keranjang (Butuh Login)

| Metode | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/keranjang` | Lihat isi keranjang pelanggan |
| POST | `/api/keranjang` | Tambah produk ke keranjang |
| PUT | `/api/keranjang/{id}` | Ubah jumlah item |
| DELETE | `/api/keranjang/{id}` | Hapus item |
| DELETE | `/api/keranjang` | Kosongkan keranjang |

### Checkout & Pesanan (Butuh Login)

| Metode | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/checkout` | Buat pesanan dari keranjang |
| GET | `/api/pesanan` | Riwayat pesanan pelanggan |
| GET | `/api/pesanan/{id}` | Detail pesanan |
| POST | `/api/pesanan/{id}/pembayaran` | Konfirmasi pembayaran (pelanggan) |
| POST | `/api/pesanan/{id}/selesai` | Tandai pesanan selesai (pelanggan) |

### Admin Only (Middleware `admin`)

| Metode | Endpoint | Deskripsi |
|--------|----------|-----------|
| PATCH | `/api/pesanan/{id}/status` | Ubah status pesanan |
| POST | `/api/pesanan/{id}/kirim` | Tandai pesanan sudah dikirim |

---

## 🖼️ Manajemen Foto Produk

- Foto disimpan di `storage/app/public/products/`.
- Akses publik via symlink `public/storage` → `storage/app/public`.
- URL foto disertakan dalam respons JSON sebagai `gambar_url` dan `image_url`.
- Frontend membaca field `foto` / `gambar_url` / `image_url` untuk menampilkan gambar.

> **Penting:** Jalankan `php artisan storage:link` agar foto produk dapat diakses oleh Flutter.

---

## 👥 Alur Kerja

### Pelanggan (Aplikasi Flutter)

```
Daftar / Masuk
    ↓
Lihat Katalog Produk (dengan foto, pencarian, filter kategori)
    ↓
Detail Produk (foto, harga, stok, deskripsi)
    ↓
Tambah ke Keranjang
    ↓
Checkout (alamat penerima, kurir, metode pembayaran, tanggal pengiriman)
    ↓
Konfirmasi Pembayaran
    ↓
Riwayat Pesanan
```

### Admin (Backend / Panel Filament)

```
Masuk (Role Admin)
    ↓
Kelola Produk (Tambah / Edit / Hapus dengan foto)
    ↓
Kelola Pesanan (Ubah status, tandai sudah dikirim)
```

> Aplikasi Flutter **tidak memiliki halaman admin** untuk menambahkan atau mengedit produk. Fitur manajemen produk hanya dapat diakses melalui backend Laravel (dilindungi middleware `admin`) atau panel Filament.

---

## 🔒 Keamanan

| Aspek | Implementasi |
|-------|-------------|
| Autentikasi | Laravel Sanctum (Bearer Token) |
| Penyimpanan Token | `flutter_secure_storage` (Flender) |
| Manajemen Produk | Middleware `admin` (hanya role admin) |
| Status Pesanan | Middleware `admin` (hanya role admin) |
| Data Keranjang | Difilter berdasarkan `customer_id` |
| Data Pesanan | Difilter berdasarkan `customer_id` |
| Konfirmasi Pembayaran | Dicek kepemilikan pesanan (`customer_id`) |
| Password | Tidak dikirim dalam response JSON (`#[Hidden]`) |

---

## 🛠️ Troubleshooting

### Foto produk tidak muncul di Flutter

Pastikan telah menjalankan:
```powershell
php artisan storage:link
```
dan server Laravel sedang berjalan. Periksa juga `API_BASE_URL` sudah benar.

### Error 403 pada endpoint produk

Endpoint `POST/PUT/DELETE /produk` hanya untuk admin. Pastikan login dengan akun yang memiliki role `admin`.

### Dependensi Flutter error

Jalankan:
```powershell
flutter pub get
flutter clean
flutter pub get
```

---

## 📄 Lisensi

Projek ini dikembangkan untuk keperluan pendidikan / UTS mata kuliah PAPB.