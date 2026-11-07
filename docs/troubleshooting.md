# Tani Mart (Tani Mart) Troubleshooting Guide

Panduan pemecahan masalah dan solusi kendala teknis yang umum ditemui selama integrasi antara Laravel REST API dan Flutter Mobile Application.

---

## 1. Kendala Jaringan & Koneksi (Connection Issues)

### Gejala: `SocketException: OS Error: Connection refused` atau `Sambungan ke server gagal`

#### Penyebab 1: Menggunakan `localhost` atau `127.0.0.1` di dalam Emulator Android
- **Penjelasan:** Di dalam emulator Android, alamat `localhost` atau `127.0.0.1` merujuk ke mesin virtual emulator itu sendiri, BUKAN komputer/laptop pengembang tempat Laravel berjalan.
- **Solusi:**
  Gunakan alamat loopback khusus emulator:
  ```
  http://10.0.2.2:8000/api
  ```
  File `lib/core/config/api_config.dart` sudah secara otomatis menyetel alamat ini saat mendeteksi platform Android.

#### Penyebab 2: Server Laravel hanya terikat pada `127.0.0.1`
- **Penjelasan:** Jika Laravel dijalankan dengan `php artisan serve` tanpa parameter `--host=0.0.0.0`, server hanya menerima koneksi internal lokal dan menolak koneksi dari emulator atau HP fisik.
- **Solusi:**
  Jalankan server Laravel dengan mengikat seluruh antarmuka jaringan:
  ```bash
  php artisan serve --host=0.0.0.0 --port=8000
  ```

#### Penyebab 3: Pengujian di Perangkat Fisik (HP Android via Wi-Fi) Gagal Terhubung
- **Penjelasan:** Komputer dan HP berada di jaringan Wi-Fi yang berbeda, atau port 8000 diblokir oleh Windows Firewall.
- **Solusi:**
  1. Pastikan laptop dan HP tersambung ke jaringan Wi-Fi yang sama (atau tethering dari HP ke laptop).
  2. Buka Command Prompt pada laptop, ketik `ipconfig`, cari *IPv4 Address* Wi-Fi Anda (misal `192.168.1.15`).
  3. Buka `lib/core/config/api_config.dart` dan set:
     ```dart
     static String physicalDeviceBaseUrl = 'http://192.168.1.15:8000/api';
     ```
  4. Berikan izin akses *Private Network* pada Windows Firewall untuk `php.exe` atau port 8000:
     ```powershell
     netsh advfirewall firewall add rule name="Laravel Dev Server" dir=in action=allow protocol=TCP localport=8000
     ```

---

## 2. Kendala Status HTTP 409 (Conflict)

### Gejala 1: `Stok tidak mencukupi untuk jumlah yang diminta`
- **Penyebab:** Pengguna mencoba menambah item ke keranjang atau melakukan checkout dengan jumlah yang melampaui sisa stok di database.
- **Solusi Sistem:**
  Frontend menampilkan peringatan interaktif kepada pengguna. Di sisi admin Filament (`http://localhost:8000/admin`), stok produk dapat ditambah kembali melalui menu *Products*.

### Gejala 2: `Produk tidak dapat dihapus karena masih terpakai pada pesanan aktif`
- **Penyebab:** Upaya menghapus produk yang masih berada dalam pesanan berstatus `menunggu_pembayaran`, `diproses`, atau `dikirim`.
- **Solusi Sistem:**
  Aturan integritas basis data menolak operasi ini untuk mencegah data pesanan menjadi *corrupt*. Selesaikan pesanan terlebih dahulu atau batalkan pesanan sebelum menghapus produk.

---

## 3. Kendala Status HTTP 422 (Unprocessable Entity)

### Gejala 1: Pesan galat validasi formulir produk (misal: *Nama produk wajib diisi*, *Harga minimal 0*)
- **Penyebab:** Payload JSON yang dikirim ke `POST /api/produk` atau `PUT /api/produk/{id}` tidak memenuhi aturan validasi.
- **Solusi:**
  Periksa respons JSON pada kunci `errors`. Flutter `ApiException.fieldErrors` secara otomatis memetakan pesan galat ini ke bawah kolom teks input bersangkutan.

### Gejala 2: `Produk mudah rusak wajib dikirim pada hari yang sama`
- **Penyebab:** Pada halaman checkout, keranjang berisi produk berlabel `mudah_rusak = true` (seperti cabai segar, tomat, atau bayam), namun tanggal pengantaran yang dipilih bukan hari ini.
- **Solusi:**
  Pilih tanggal pengantaran hari ini (*Same-day delivery*) pada *date picker* halaman checkout.

---

## 4. Kendala Status HTTP 500 (Internal Server Error)

### Gejala 1: `SQLSTATE[HY000] [2002] Connection refused`
- **Penyebab:** Layanan MySQL (pada XAMPP / Laragon / MySQL Service) belum diaktifkan.
- **Solusi:**
  1. Buka XAMPP Control Panel / Laragon.
  2. Klik tombol **Start** pada modul MySQL.
  3. Pastikan port 3306 aktif dan database `Tani Mart` sudah dibuat.

### Gejala 2: `Table 'Tani Mart.carts' doesn't exist`
- **Penyebab:** Migrasi tabel keranjang belum dijalankan di database MySQL.
- **Solusi:**
  Jalankan perintah migrasi pada terminal:
  ```bash
  cd TaniMart_Backend
  php artisan migrate
  ```

---

## 5. Kendala Idempotensi Checkout

### Gejala: Tombol pesan ditekan dua kali berturut-turut
- **Perilaku Sistem:**
  Aplikasi mengirimkan header `X-Idempotency-Key` yang sama. Server mendeteksi pesanan dengan kunci tersebut telah berhasil dibuat dan mengembalikan status **HTTP 200 OK** beserta rincian pesanan yang ada tanpa memotong stok kembali atau membuat pesanan ganda (*Double Charging Protection*).

---

## 6. Panel Admin Filament

### Mengganti Kata Sandi / Akun Admin
Jika lupa kata sandi admin untuk mengakses `http://localhost:8000/admin`:
Jalankan perintah interaktif CLI pada folder backend:
```bash
php artisan app:admin-password
```
Perintah ini memungkinkan Anda memperbarui username atau menyetel kata sandi baru secara aman.

