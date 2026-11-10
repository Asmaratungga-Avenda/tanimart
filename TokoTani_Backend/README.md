# TaniMart - Toko Online Produk Pertanian

## 1. Deskripsi Project

<<<<<<< HEAD
## TokoTani API authentication

Run database migrations before using the API:

```bash
php artisan migrate
```

Customer accounts use Laravel Sanctum. Register at `POST /api/auth/register` or log
in at `POST /api/auth/login`; the Flutter client stores the returned token in
secure storage and uses it for cart, checkout, and order requests. Customer
registration always assigns the `customer` role. It does not create administrator
accounts.

Create or promote an administrator interactively with:

```bash
php artisan admin:password
```

The command sets the account's password and administrator role. Admin-only API
operations and the Filament panel require that role. Payment confirmation from
the customer only records a request for review; an administrator must verify it
before the order can progress to paid.

## About Laravel
=======
TaniMart merupakan aplikasi toko online yang menyediakan berbagai produk pertanian dan kebutuhan sehari-hari. Aplikasi ini dibuat untuk membantu pengguna melihat produk, mengelola keranjang belanja, melakukan checkout, serta memantau pesanan.
>>>>>>> 7905d6ff47137baa55e5b41b63709a2a36015363

Project ini menggunakan Laravel sebagai backend dan Flutter sebagai frontend.

## 2. Teknologi yang Digunakan

- PHP 8.3 atau lebih baru
- Laravel 13
- MySQL
- Composer
- Postman
- Flutter

## 3. Fitur Aplikasi

1. Menampilkan daftar produk.
2. Menampilkan detail produk.
3. Mengelola kategori produk.
4. Menambahkan produk ke keranjang.
5. Mengubah dan menghapus isi keranjang.
6. Melakukan checkout.
7. Menampilkan riwayat pesanan.
8. Menampilkan informasi kurir.
9. Menampilkan metode pembayaran.
10. Mengelola status pesanan.

## 4. Instalasi Project

### Langkah 1
Clone repository project:

```bash
git clone URL_REPOSITORY
```

### Langkah 2
Masuk ke folder backend:

```bash
cd TokoTani_Backend
```

### Langkah 3
Instal dependency:

```bash
composer install
```

### Langkah 4
Salin file `.env.example` menjadi `.env`, kemudian atur konfigurasi database MySQL.

### Langkah 5
Generate application key:

```bash
php artisan key:generate
```

### Langkah 6
Jalankan migration:

```bash
php artisan migrate
```

### Langkah 7
Masukkan data awal:

```bash
php artisan db:seed
```

### Langkah 8
Jalankan server Laravel:

```bash
php artisan serve
```

Server berjalan melalui:

`http://127.0.0.1:8000`

## 5. Struktur Database

Database TaniMart memiliki beberapa tabel utama:

- users
- categories
- products
- couriers
- payment_methods
- orders
- order_items
- carts
- keranjang

## 6. Data Awal

Seeder menyediakan:

- 3 akun pelanggan demo
- 2 kategori produk
- 12 produk pertanian dan kebutuhan harian
- 3 data kurir
- 2 metode pembayaran
- 1 contoh pesanan

Terdapat 2 produk dengan stok nol untuk pengujian ketersediaan stok.

## 7. API

API digunakan untuk menghubungkan aplikasi Flutter dengan backend Laravel.

Daftar endpoint dapat dilihat pada dokumentasi API TaniMart.

## 8. Pengujian

Pengujian dilakukan menggunakan Postman untuk memastikan endpoint dapat menerima permintaan dan memberikan respons sesuai kebutuhan aplikasi.

## 9. Anggota Tim

Project TaniMart dikerjakan secara berkelompok dengan pembagian tugas backend, frontend, integrasi data, dokumentasi, dan pengujian.
