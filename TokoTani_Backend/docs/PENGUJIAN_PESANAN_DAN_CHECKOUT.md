# Pengujian Pesanan dan Checkout

Dokumen ini menjelaskan objektif pengujian:

- Endpoint kurir/wilayah dan penghapusan kurir tanpa merusak pesanan lama.
- Riwayat pesanan.
- Rincian pesanan.
- Perubahan status pesanan, termasuk matriks seluruh kombinasi status.
- Revalidasi stok/ketersediaan saat update keranjang.
- Demonstrasi checkout berhasil, kuantitas, tanggal, dan retry idempoten.
- Dua metode pembayaran tersimpan.
- Simulasi status berurutan dan penolakan transisi ilegal.
- Checkout konkuren pada stok terbatas.
- Idempotensi kunci yang sama dan kunci berbeda.
- Stok tidak cukup dan kegagalan di tengah transaksi.
- Pemeriksaan langsung database untuk pesanan ganda serta stok/keranjang
  setengah berubah.

Dokumen ini melengkapi:

- `docs/PESANAN_DAN_STATUS.md`
- `docs/CHECKOUT_SPESIFIKASI.md`
- `docs/ERD_TRANSAKSI.md`

---

## 1. File Pengujian

| File | Peran |
|------|-------|
| `tests/Feature/PesananAcceptanceTest.php` | Pengujian acceptance endpoint, status, pembayaran, dan checkout sekuensial |
| `tests/Feature/PesananStatusTransitionTest.php` | Pengujian matriks seluruh kombinasi transisi status |
| `tests/Feature/CheckoutDemoTest.php` | Demonstrasi empat skenario checkout |
| `tests/Feature/KeranjangTest.php` | Pengujian keranjang dan revalidasi stok/ketersediaan |
| `tests/Feature/KurirTest.php` | Pengujian kurir/wilayah, tarif, dan penghapusan |
| `tests/Feature/CheckoutConcurrencyTest.php` | Pengujian dua checkout hampir bersamaan |
| `tests/Support/CheckoutFixtures.php` | Fixture bersama untuk produk, kurir, pembayaran, pelanggan, dan payload |
| `tests/Support/checkout_request.php` | Proses anak untuk mengirim request checkout secara paralel |
| `app/Http/Controllers/CheckoutController.php` | Perbaikan idempotensi untuk request konkuren dengan kunci sama |

---

## 2. Endpoint Kurir/Wilayah

### Skenario

- Membuat tiga kurir aktif dengan tarif berbeda.
- Membuat satu kurir nonaktif.
- Memanggil `GET /api/kurir` dan alias `GET /api/couriers`.

### Asersi

- Respons `200` dan `status = sukses`.
- Hanya kurir aktif yang dikembalikan.
- Data terurut berdasarkan `tarif` naik.
- Setiap data memuat `nama`, `wilayah`, `tarif`, dan `aktif`.
- Kurir nonaktif tidak muncul.
- Tiga tarif berbeda tampil dan terurut naik.
- Kurir yang dihapus hilang dari daftar, tetapi detail pesanan lama tetap
  memuat nama, wilayah, dan tarifnya.
- Checkout baru dengan kurir yang sudah dihapus ditolak `422`.
- Alias `GET /api/wilayah` dan `DELETE /api/wilayah/{id}` berfungsi sama.

### Alur

```text
GET /api/kurir
  |
  v
WilayahAntar::where(aktif, true)->orderBy(tarif)->get()
  |
  v
200 + daftar wilayah + tarif
```

---

## 3. Dua Metode Pembayaran

### Skenario

- Menjalankan `DatabaseSeeder`.
- Memanggil `GET /api/metode-pembayaran` dan alias
  `GET /api/payment-methods`.

### Asersi

- Tabel `payment_methods` berisi tepat dua baris.
- Kedua baris aktif:
  - `Transfer Bank`
  - `Bayar di Tempat`
- Kedua endpoint mengembalikan dua metode tersebut.

---

## 4. Riwayat dan Rincian Pesanan

### Riwayat

Skenario:

1. Membuat dua pesanan melalui checkout.
2. Mengubah `created_at` pesanan pertama menjadi kemarin.
3. Memanggil `GET /api/pesanan`.

Asersi:

- Pesanan dengan `created_at` terbaru muncul lebih dahulu.
- Jika timestamp sama, `id` lebih besar menjadi penentu.

### Rincian

Skenario:

1. Checkout produk dengan nama `Bayam Awal` dan harga `5000`.
2. Mengubah nama dan harga produk di katalog.
3. Memanggil `GET /api/pesanan/{id}`.

Asersi:

- `nama_produk` tetap `Bayam Awal`.
- `harga_satuan` tetap `5000`.
- `subtotal` tetap hasil transaksi awal.
- Pesanan tidak ditemukan menghasilkan `404`.

```text
GET /api/pesanan/{id}
  |
  v
Ambil order + items + kurir + metode pembayaran
  |
  |-- tidak ada ----> 404
  |
  v
200 + snapshot nama, harga, dan subtotal
```

---

## 5. Status Pesanan

### Simulasi urutan legal

```text
menunggu_pembayaran
  -> menunggu_konfirmasi
  -> dibayar
  -> diproses
  -> dikirim
  -> selesai
```

Setiap langkah diuji dengan `PATCH /api/pesanan/{id}/status` dan diperiksa
langsung pada tabel `orders`.

### Transisi yang ditolak

- Melompati tahap:
  - `menunggu_pembayaran -> dibayar`
  - `menunggu_pembayaran -> diproses`
  - `menunggu_pembayaran -> dikirim`
  - `menunggu_pembayaran -> selesai`
  - `menunggu_konfirmasi -> dikirim`
- Mengubah ke status yang sama.
- Menghidupkan kembali pesanan `selesai`.
- Menghidupkan kembali pesanan `dibatalkan`.

Semua transisi tersebut menghasilkan `409 Conflict` dan status di database
tidak berubah.

```text
PATCH /api/pesanan/{id}/status
  |
  v
Validasi status
  |
  |-- tidak valid ----> 422
  |
  v
DB::transaction + lockForUpdate
  |
  |-- tidak ditemukan ----> 404
  |-- canTransitionTo() false ----> 409
  |
  v
Simpan status baru -> 200
```

---

## 6. Checkout Sekuensial

### Kunci idempoten sama

- Request pertama menghasilkan `201`.
- Request ulang dengan kunci dan payload sama menghasilkan `200` dengan
  pesanan lama.
- Tabel `orders` tetap satu baris.
- Tabel `order_items` tetap satu baris.
- Stok hanya berkurang sekali.

### Kunci berbeda

- Dua request dengan payload sama tetapi kunci berbeda menghasilkan dua
  pesanan.
- Stok berkurang sebanyak dua kali.
- Tidak ada penggabungan pesanan.

### Stok tidak cukup

- Keranjang berisi tiga unit, stok hanya dua.
- Checkout menghasilkan `422`.
- Tidak ada pesanan atau detail pesanan.
- Stok tetap dua.
- Keranjang tetap berisi tiga unit.

### Kegagalan di tengah transaksi

- Produk pertama cukup stok.
- Produk kedua tidak cukup stok.
- Checkout menghasilkan `422`.
- Stok kedua produk tidak berubah.
- Keranjang tidak berubah.
- Tidak ada pesanan atau detail pesanan yang tersimpan.

---

## 7. Checkout Konkuren

Pengujian konkuren memakai dua proses PHP terpisah yang mengirim request ke
kernel Laravel secara hampir bersamaan.

### Mekanisme

```text
Parent test
  |
  |-- buat data + keranjang
  |-- jalankan proses A dan B
  |-- sentuh file barrier
  |
  +---- Proses A menunggu barrier -> kirim POST /api/checkout
  |
  +---- Proses B menunggu barrier -> kirim POST /api/checkout
  |
  v
Kedua proses selesai -> parent memeriksa respons dan database
```

File barrier memastikan kedua proses sudah selesai boot sebelum salah satu
mengirim request. Dengan begitu, keduanya benar-benar berkompetisi pada baris
database yang sama.

### Skenario 1: stok terbatas, pelanggan berbeda

- Stok produk: `1`.
- Dua pelanggan masing-masing memiliki keranjang berisi `1`.
- Dua request dengan kunci idempoten berbeda.
- `lockForUpdate` pada produk membuat satu request menunggu request lain.

Hasil yang diharapkan:

- Tepat satu request `201`.
- Satu request lain `409` atau `422`.
- Tabel `orders` berisi satu baris.
- Tabel `order_items` berisi satu baris.
- Stok akhir `0` dan produk menjadi tidak tersedia.
- Keranjang pemenang kosong.
- Keranjang pihak yang gagal tetap utuh.

### Skenario 2: kunci idempoten sama

- Stok produk: `5`.
- Keranjang pelanggan berisi `2`.
- Dua request paralel memakai kunci idempoten yang sama.

Hasil yang diharapkan:

- Satu request `201`.
- Satu request `200` dengan `id` pesanan yang sama.
- Tabel `orders` berisi satu baris.
- Tabel `order_items` berisi satu baris dengan kuantitas `2`.
- Stok akhir `3`.
- Keranjang kosong.

---

## 8. Temuan dan Perbaikan Idempotensi

### Masalah

Pengecekan kunci idempoten sebelum transaksi dapat dilewati oleh dua request
yang berjalan hampir bersamaan:

```text
Request A dan B sama-sama cek orders -> belum ada
Request A lock produk -> validasi -> simpan order -> commit
Request B menunggu lock produk
Request B mendapat lock -> stok sudah 0 atau keranjang sudah kosong
Request B gagal 409/422, padahal harus mengembalikan pesanan A
```

### Perbaikan

Saat transaksi gagal dengan `HttpResponseException`, controller memeriksa ulang
apakah kunci idempoten sudah menghasilkan pesanan. Jika ada:

- Payload sama: kembalikan pesanan lama dengan `200`.
- Payload berbeda: kembalikan `409`.

```text
catch (HttpResponseException)
  |
  |-- kunci idempoten tidak ada ----> teruskan error asli
  |
  v
Cari order berdasarkan idempotency_key
  |
  |-- tidak ada ----> teruskan error asli
  |
  |-- payload sama ----> 200 + pesanan lama
  |
  v
  payload berbeda ----> 409
```

Perbaikan ini diverifikasi dengan menghapus sementara blok tersebut: tes
konkurensi gagal dengan hasil `201` dan `422`. Setelah blok dikembalikan, tes
lulus dengan hasil `201` dan `200`.

---

## 9. Pemeriksaan Database

Setiap skenario memakai asersi database langsung, bukan hanya status HTTP:

- `assertDatabaseCount('orders', ...)`
- `assertDatabaseCount('order_items', ...)`
- `assertDatabaseHas('products', ['stok' => ...])`
- `assertDatabaseHas('keranjang', ...)`
- `assertDatabaseMissing('keranjang', ...)`
- `assertDatabaseHas('orders', ['idempotency_key' => ...])`

Dengan demikian, tes membuktikan:

- Tidak ada pesanan ganda.
- Tidak ada stok yang berkurang sebagian.
- Tidak ada keranjang yang terhapus sebagian.
- Tidak ada detail pesanan yatim saat transaksi gagal.

---

## 10. Menjalankan Pengujian

```shell
php artisan test --filter=PesananAcceptanceTest
php artisan test --filter=CheckoutConcurrencyTest
php artisan test
vendor/bin/pint --test
```

Hasil terakhir:

```text
PesananAcceptanceTest       : 12 tests, 141 assertions, passed
PesananStatusTransitionTest : 1 test, 251 assertions, passed
CheckoutDemoTest            : 4 tests, 35 assertions, passed
KeranjangTest               : 7 tests, 43 assertions, passed
KurirTest                   : 3 tests, 38 assertions, passed
CheckoutConcurrencyTest     : 2 tests, 24 assertions, passed
Semua test                  : 69 tests, 745 assertions, passed
Pint                        : passed
```

---

## 11. Matriks Kasus Uji

| Kasus | Hasil yang diharapkan |
|-------|------------------------|
| GET kurir/wilayah | Hanya aktif, urut tarif, memuat wilayah dan tarif |
| DELETE kurir | Soft delete, hilang dari daftar, riwayat pesanan tetap utuh |
| Checkout dengan kurir terhapus | `422`, tidak ada pesanan baru |
| GET metode pembayaran | Dua metode tersimpan dan tampil |
| GET riwayat | Terbaru lebih dahulu |
| GET rincian | Snapshot nama/harga/subtotal |
| GET rincian tidak ada | `404` |
| Simulasi status legal | `200` setiap tahap |
| Matriks seluruh transisi | Legal `200`, ilegal `409`, status tidak berubah |
| Lompat tahap | `409`, status tidak berubah |
| Status sama | `409` |
| Hidupkan pesanan selesai | `409`, status tetap `selesai` |
| Hidupkan pesanan dibatalkan | `409`, status tetap `dibatalkan` |
| Update keranjang stok habis | `409`, jumlah keranjang tidak berubah |
| Checkout kunci sama | Satu pesanan, stok berkurang sekali |
| Checkout kunci berbeda | Dua pesanan, stok berkurang dua kali |
| Checkout kuantitas melebihi batas | `422`, tanpa pesanan, stok tetap |
| Checkout mudah rusak beda hari | `422`, tanpa pesanan, stok tetap |
| Retry kunci sama | `200`, id pesanan sama, tanpa pesanan ganda |
| Stok tidak cukup | `422`, stok/keranjang tidak berubah |
| Gagal di tengah transaksi | Rollback penuh |
| Dua checkout stok terbatas | Satu pesanan, tanpa oversell |
| Dua retry kunci sama paralel | Satu pesanan, satu respons idempoten |

---

## 12. Saran Nama Commit

Jika seluruh perubahan pengujian dan perbaikan ini dijadikan satu commit,
gunakan pesan berikut.

### Opsi utama

```text
test(pesanan): uji alur pesanan dan konkurensi checkout
```

Body commit yang disarankan:

```text
- uji endpoint kurir/wilayah beserta tarif
- pastikan dua metode pembayaran tersimpan dan tampil
- uji riwayat terbaru lebih dahulu dan rincian snapshot harga
- uji simulasi status berurutan, lompat tahap, dan pesanan selesai/dibatalkan
- uji checkout dengan kunci sama, kunci berbeda, stok kurang, dan rollback
- tambah tes konkuren dua proses untuk stok terbatas dan kunci idempoten sama
- perbaiki idempotensi request paralel dengan kunci sama
- periksa database untuk pesanan ganda dan perubahan stok/keranjang sebagian
```

### Alternatif

```text
test(checkout): tambah pengujian acceptance dan konkurensi pesanan
```

Nama branch yang disarankan:

```text
test/pesanan-dan-checkout-konkuren
```
