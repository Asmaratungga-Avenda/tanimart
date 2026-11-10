# TaniMart

TaniMart adalah aplikasi toko online untuk produk pertanian dan kebutuhan harian. Repositori ini berisi backend Laravel sebagai REST API dan panel admin, serta aplikasi pelanggan berbasis Flutter. Proyek dibuat untuk keperluan pendidikan mata kuliah PAPB.

## Fitur

### Pelanggan

- Registrasi, login, dan logout menggunakan Laravel Sanctum.
- Katalog produk dengan pencarian, filter kategori, pengurutan, dan pagination.
- Detail produk, keranjang, checkout, konfirmasi pembayaran, dan riwayat pesanan.
- Tema terang, gelap, dan mengikuti sistem.
- Cache produk dan kategori serta antrean permintaan offline di aplikasi Flutter.

### Admin

- Mengelola produk, termasuk unggah gambar.
- Mengelola status pesanan melalui API dan panel Filament.
- Operasi admin hanya tersedia bagi akun dengan peran administrator.

## Teknologi dan Struktur

| Bagian | Teknologi |
|---|---|
| Backend | PHP 8.3+, Laravel, Laravel Sanctum, Filament |
| Database | MySQL atau SQLite |
| Frontend | Flutter, Provider, Hive |

```text
TaniMart/
├── README.md
├── TokoTani_Backend/     # REST API dan panel admin Laravel
└── TokoTani_Frontend/    # Aplikasi pelanggan Flutter
```

## Menjalankan Backend

Prasyarat: PHP 8.3 atau lebih baru, Composer, dan MySQL atau SQLite.

Setelah clone repository:

```powershell
git clone URL_REPOSITORY TaniMart
cd TaniMart
```

Saat mengambil pembaruan di clone yang sudah ada, jalankan `git pull` dari root repository. Perubahan kode dan berkas gambar yang terlacak akan ikut diperbarui; data database lokal tidak otomatis dihapus atau diganti.

```powershell
cd TokoTani_Backend
composer install
Copy-Item .env.example .env
php artisan key:generate
```

Atur koneksi database pada `.env`, lalu jalankan migrasi dan data awal:

```powershell
php artisan migrate --seed
php artisan serve
```

API tersedia di `http://127.0.0.1:8000`. Gambar publik disimpan pada `storage/app/public/` dan disajikan melalui route Laravel `/storage`.

Akun demo yang dibuat oleh seeder:

| Peran | Email | Password |
|---|---|---|
| Admin | `admin@tokotani.test` | `password` |
| Pelanggan | `user@tokotani.test` | `password` |

Akun ini dibuat dengan kredensial yang sama pada database baru melalui `php artisan migrate --seed` atau `php artisan db:seed`. Seeder hanya membuat akun demo di luar environment production. Jika akun sudah ada, seeder tidak mengubah password yang tersimpan; karena itu pull atau seed ulang tidak mereset password lokal yang sudah diganti. Akun demo hanya untuk pengembangan lokal. Ganti password sebelum penggunaan selain pengujian lokal. Administrator juga dapat dibuat atau diatur ulang secara interaktif dengan:

```powershell
php artisan admin:password
```

Registrasi pelanggan selalu memberikan peran `customer`; endpoint registrasi tidak membuat akun admin. Jalankan migrasi sebelum memakai API. Panel Filament dan operasi admin memerlukan peran administrator.

## Menjalankan Frontend

Prasyarat: Flutter SDK versi stabil dan Android Studio/emulator atau Chrome.

```powershell
cd TokoTani_Frontend
flutter pub get
flutter analyze
flutter test
```

Jalankan aplikasi dengan URL API yang sesuai:

```powershell
# Chrome / desktop
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

# Emulator Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Perangkat Android fisik (ganti dengan IP komputer)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Jika `API_BASE_URL` tidak ditentukan, aplikasi menggunakan `10.0.2.2` untuk emulator Android dan `127.0.0.1` untuk Web/platform lain. Gunakan host yang konsisten. URL media dari backend diselesaikan oleh `ApiConfig.resolveMedia()`; path relatif Laravel mendapat awalan `storage/`. Gambar yang URL-nya kosong atau gagal dimuat tidak diganti placeholder.

Build APK produksi:

```powershell
flutter build apk --dart-define=API_BASE_URL=https://api.tanimart.id/api
```

## API

Base URL lokal: `http://127.0.0.1:8000/api`. Endpoint bertanda **Login** memerlukan token Sanctum pada header `Authorization: Bearer <token>`. Endpoint bertanda **Admin** juga memerlukan peran administrator.

| Metode | Endpoint | Akses | Fungsi |
|---|---|---|---|
| `POST` | `/auth/register` | Publik | Daftar pelanggan |
| `POST` | `/auth/login` | Publik | Login dan memperoleh token |
| `GET` | `/auth/me` | Login | Profil pengguna |
| `POST` | `/auth/logout` | Login | Logout dan menghapus token |
| `GET` | `/produk` | Publik | Daftar produk; mendukung pagination |
| `GET` | `/produk/{id}` | Publik | Detail produk |
| `GET` | `/kategori` | Publik | Daftar kategori |
| `GET` | `/banners` | Publik | Daftar banner |
| `POST` | `/produk` | Admin | Membuat produk, unggah multipart melalui field `gambar` |
| `PUT` | `/produk/{id}` | Admin | Mengubah produk |
| `DELETE` | `/produk/{id}` | Admin | Menghapus produk |
| `GET` / `POST` | `/keranjang` | Login | Melihat atau menambah item keranjang |
| `PUT` / `DELETE` | `/keranjang/{id}` | Login | Mengubah atau menghapus item |
| `DELETE` | `/keranjang` | Login | Mengosongkan keranjang |
| `GET` | `/kurir` | Publik | Daftar kurir/wilayah aktif dan tarif |
| `GET` | `/metode-pembayaran` | Publik | Daftar metode pembayaran |
| `POST` | `/checkout` | Login | Membuat pesanan |
| `GET` | `/pesanan` | Login | Riwayat pesanan terbaru lebih dahulu |
| `GET` | `/pesanan/{id}` | Login | Detail pesanan |
| `POST` | `/pesanan/{id}/pembayaran` | Login | Mengajukan konfirmasi pembayaran |
| `POST` | `/pesanan/{id}/selesai` | Login | Mengonfirmasi pesanan diterima |
| `PATCH` | `/pesanan/{id}/status` | Admin | Mengubah status sesuai transisi yang diizinkan |
| `POST` | `/pesanan/{id}/kirim` | Admin | Menandai pesanan dikirim |

Alias kurir yang tersedia: `/couriers` dan `/wilayah`. Endpoint penghapusan kurir menggunakan soft delete agar data pesanan lama tetap utuh.

Respons API mengikuti bentuk umum berikut:

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Pesan",
  "data": {}
}
```

Respons validasi dapat menyertakan properti `errors`.

### Autentikasi dan keamanan data

- Token pelanggan dikelola aplikasi Flutter melalui secure storage.
- Data keranjang dan pesanan dibatasi berdasarkan pemiliknya.
- Password tidak dikirim dalam respons API.
- Konfirmasi pembayaran pelanggan hanya mengajukan pembayaran untuk ditinjau admin; admin harus memverifikasi sebelum pesanan berstatus dibayar.
- Foto produk disimpan di `storage/app/public/products/`; respons dapat memuat `gambar_url` atau `image_url`.

### Keranjang dan transaksi

- Keranjang tersimpan di server. Penambahan produk yang sama menggabungkan jumlah pada baris yang sama.
- Subtotal dihitung server dari harga produk dan jumlah; nilai total kiriman klien tidak dipercaya.
- Pesanan menyimpan snapshot nama dan harga produk di detail pesanan agar riwayat tidak berubah ketika katalog diperbarui.
- Tarif kurir diambil dari data server. Pilihan kurir contoh memiliki tarif 10.000, 20.000, dan 35.000.
- Checkout menggunakan transaksi database dan penguncian data produk/keranjang untuk memvalidasi ulang stok dan mencegah overselling.
- Kunci idempoten wajib dikirim pada header `X-Kunci-Idempoten` (alias yang didukung: `X-Idempotency-Key`, `Idempotency-Key`, atau body `idempotency_key`). Kunci dan payload sama mengembalikan pesanan yang telah dibuat; kunci sama dengan payload berbeda menghasilkan `409`.
- Isi `items` dapat dikirim pada request checkout; jika tidak dikirim, backend memakai keranjang pelanggan.
- Produk mudah rusak wajib dikirim pada hari yang sama. Batas jumlah per produk dikonfigurasi melalui `CHECKOUT_MAX_MUDAH_RUSAK` (default 5). Slot pengantaran yang valid: `pagi`, `siang`, dan `sore`.

### Status pesanan

Transisi yang diizinkan:

```text
menunggu_pembayaran -> menunggu_konfirmasi -> dibayar -> diproses -> dikirim -> tiba -> selesai
menunggu_pembayaran -> dibatalkan
menunggu_konfirmasi -> dibatalkan
dikirim -> selesai
```

Transisi di luar aturan, termasuk mengubah status ke nilai yang sama, ditolak dengan `409 Conflict`. Status `selesai` dan `dibatalkan` bersifat terminal. Pelanggan dapat mengonfirmasi pesanan menjadi `selesai` ketika pesanan berstatus `dikirim` atau `tiba`.

## Database dan Gambar

Tabel transaksi utama:

| Domain | Tabel |
|---|---|
| Pelanggan | `users` |
| Produk | `products` |
| Keranjang | `keranjang` |
| Kurir/wilayah | `couriers` |
| Metode pembayaran | `payment_methods` |
| Pesanan | `orders` |
| Detail pesanan | `order_items` |

`keranjang` memiliki batas unik pada pasangan pelanggan dan produk. `order_items` menyimpan `nama_produk`, `harga_satuan`, serta `subtotal` sebagai snapshot transaksi. `orders` menyimpan ringkasan biaya, status, jadwal pengantaran, dan kunci idempoten unik.

Berkas gambar demo backend disimpan dan dilacak Git di `TokoTani_Backend/storage/app/public/`; seeder menghubungkan gambar kategori, dua foto produk contoh, dan banner ke berkas tersebut. Route Laravel `/storage/{path}` menyajikan berkas secara langsung, sehingga tidak perlu membuat symlink `public/storage`. Aset logo, banner, font, dan ikon Flutter juga disimpan di `TokoTani_Frontend/assets/` serta direktori platform. Jangan menghapus atau mengganti nama berkas yang dirujuk seeder atau `pubspec.yaml`.

Setelah pull yang memuat perubahan data contoh/seeder, jalankan dari folder backend:

```powershell
php artisan db:seed --no-interaction
```

Perintah tersebut memperbarui data contoh, termasuk referensi gambar, tanpa menghapus database. Jangan gunakan `migrate:fresh` pada database yang berisi data yang ingin dipertahankan.

## Pengujian

Jalankan pengujian backend dari `TokoTani_Backend`:

```powershell
php artisan test
```

Pengujian terpilih:

```powershell
php artisan test --filter=CheckoutTest
php artisan test --filter=CheckoutConcurrencyTest
php artisan test --filter=PesananStatusTransitionTest
php artisan test --filter=KeranjangTest
php artisan test --filter=KurirTest
```

Suite backend mencakup validasi checkout, perhitungan server, snapshot transaksi, idempotensi, rollback, keranjang, tarif dan penghapusan kurir, matriks transisi status, serta checkout konkuren. Jalankan pengujian frontend dari `TokoTani_Frontend` dengan `flutter analyze` dan `flutter test`. Hasil yang dicatat pada dokumen terdahulu merupakan snapshot dari waktu berbeda; gunakan hasil perintah terbaru sebagai acuan.

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Emulator Android tidak terhubung ke API | Gunakan `10.0.2.2` alih-alih `127.0.0.1`. |
| HTTP diblokir Android | Untuk pengembangan lokal, aktifkan cleartext traffic di `AndroidManifest.xml`; jangan gunakan konfigurasi ini sebagai pengaturan produksi tanpa pertimbangan keamanan. |
| Foto produk tidak muncul | Pastikan file tersedia di `storage/app/public/`, backend berjalan, dan `API_BASE_URL` serta `APP_URL` menunjuk host backend yang benar. |
| CORS pada Flutter Web | Pastikan route `/storage` disajikan oleh Laravel dengan header CORS. Setelah mengubah konfigurasi, jalankan `php artisan config:clear`. |
| Operasi produk admin mendapat `403` | Login dengan akun berperan `admin`. |
| Dependensi Flutter bermasalah | Jalankan `flutter clean`, lalu `flutter pub get`. |
| Seeder gagal | Periksa koneksi database pada `.env`, lalu jalankan `php artisan migrate --seed`. |

## Catatan Pengembangan

- Ikuti struktur folder, pola, helper, dan gaya kode yang sudah digunakan.
- Gunakan versi API sesuai dependensi yang terpasang dan jangan mengubah dependensi tanpa persetujuan.
- Validasi perubahan dengan linter, build, atau pengujian terpilih yang relevan; tambahkan pengujian untuk perubahan perilaku.
- Jangan memasukkan kredensial atau rahasia ke repositori.
- Gunakan perintah Artisan dengan `--no-interaction` bila menjalankan perintah otomatis.
- Untuk kode PHP, gunakan tipe parameter dan tipe kembalian eksplisit serta kurung kurawal pada struktur kontrol.
- Perubahan dokumentasi saja tidak memerlukan validasi kode.

## Aset Launch Screen Flutter

Aset launch screen dapat diganti dengan berkas gambar yang diinginkan. Di macOS, aset juga dapat dikelola melalui project Xcode pada `ios/Runner.xcworkspace`, di bagian `Runner/Assets.xcassets`. Perintah menjalankan frontend tetap dilakukan dari folder `TokoTani_Frontend`:

```shell
flutter pub get
flutter test
flutter run
```

## Demonstrasi dan Lisensi

Tautan video demonstrasi (maksimal lima menit): 
Demonstrasikan menjalankan backend dan Flutter, registrasi/login, katalog, keranjang, checkout, riwayat pesanan, satu skenario galat, dan panel admin.

Proyek Ini Dikembangkan untuk keperluan pendidikan (UTS mata kuliah PAPB Dan SisTer).


## 👥 Anggota Kelompok

| No | Nama Lengkap | NIM | Peran |
| :---: | :--- | :---: | :---:|
| 1 | **Yudhistira Empi** | 24102023 | Ketua |
| 2 | Asmaratungga Avenda D.P. | 24102006 | Anggota |
| 3 | Eka Yuvita Sari Widya Diningrum | 24102008 | Anggota |
| 4 | Hikmah Nutriana | 24102011 | Anggota |
| 5 | M. Adzahahabi Putra Darmawan | 24102013 | Anggota |
| 6 | Moh Farhan Ali | 24102016 | Anggota |
| 7 | Vera Adelia | 24102032 | Anggota |
