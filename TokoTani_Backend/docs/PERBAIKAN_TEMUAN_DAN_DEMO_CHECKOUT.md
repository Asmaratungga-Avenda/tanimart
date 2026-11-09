# Perbaikan Temuan dan Demo Checkout

Dokumen ini menjelaskan objektif:

- Perbaikan temuan endpoint keranjang, kurir/wilayah, dan pesanan.
- Verifikasi tiga tarif berbeda.
- Verifikasi snapshot harga, riwayat, detail, dan seluruh transisi status.
- Penghapusan kurir/wilayah yang tidak merusak data pesanan lama.
- Finalisasi validasi checkout, batas kuantitas, same-day, transaksi,
  `lockForUpdate`, dan idempotensi.
- Demonstrasi empat skenario checkout.

---

## 1. Ringkasan Perubahan

| Area | Temuan | Perbaikan |
|------|--------|-----------|
| Keranjang | `PUT /api/keranjang/{id}` membaca produk tanpa lock dan tanpa transaksi | Transaksi + `lockForUpdate` produk lalu baris keranjang, validasi ulang stok/ketersediaan |
| Kurir/wilayah | Belum ada operasi hapus dan hard delete berisiko merusak relasi pesanan | Soft delete `couriers.deleted_at`, endpoint hapus, relasi pesanan memakai `withTrashed()` |
| Pesanan | Perlu verifikasi menyeluruh riwayat, detail, snapshot, dan status | Pengujian matriks status dan pengujian snapshot |
| Checkout | Perlu finalisasi validasi, batas kuantitas, same-day, lock, dan idempotensi | Dipertahankan dan diverifikasi dengan tes, termasuk request paralel |
| Demonstrasi | Belum ada skenario presentasi yang ringkas | `tests/Feature/CheckoutDemoTest.php` dengan empat skenario |

File yang berubah:

- `app/Http/Controllers/KeranjangController.php`
- `app/Http/Controllers/KurirController.php`
- `app/Http/Controllers/CheckoutController.php`
- `app/Models/Courier.php`
- `app/Models/WilayahAntar.php`
- `app/Models/Order.php`
- `app/Models/Pesanan.php`
- `routes/api.php`
- `database/migrations/2026_11_09_000001_add_soft_deletes_to_couriers_table.php`
- `tests/Feature/KeranjangTest.php`
- `tests/Feature/KurirTest.php`
- `tests/Feature/CheckoutDemoTest.php`
- `tests/Feature/PesananStatusTransitionTest.php`

---

## 2. Perbaikan Keranjang

### Masalah

`PUT /api/keranjang/{id}` sebelumnya:

1. Mengambil baris keranjang.
2. Mengambil produk tanpa `lockForUpdate`.
3. Memeriksa stok.
4. Menyimpan jumlah baru.

Akibatnya, stok atau ketersediaan produk dapat berubah di antara pembacaan dan
penyimpanan. Tidak ada transaksi yang menjamin validasi dan penyimpanan berada
dalam satu unit kerja.

### Perbaikan

```text
PUT /api/keranjang/{id}
  |
  v
Validasi jumlah minimal 1
  |
  v
DB::transaction
  |
  |-- lockForUpdate produk
  |-- lockForUpdate baris keranjang
  |-- produk tidak ada / tidak tersedia ----> 404 / 409
  |-- jumlah > stok ----> 409
  |
  v
Simpan jumlah baru -> 200
```

Urutan lock disamakan dengan alur checkout: produk lebih dahulu, lalu baris
keranjang. Tujuannya mencegah deadlock antara update keranjang dan checkout.

Jika validasi gagal, jumlah di keranjang tidak berubah.

---

## 3. Perbaikan Kurir/Wilayah

### Masalah

- Belum ada endpoint hapus kurir/wilayah.
- Tabel `orders` memiliki foreign key `kurir_id`. Hard delete kurir yang sudah
  dipakai pesanan akan melanggar foreign key atau, jika foreign key dilonggarkan,
  membuat detail pesanan kehilangan data kurir.

### Perbaikan

1. Menambahkan kolom `couriers.deleted_at`.
2. Model `Courier` dan `WilayahAntar` memakai `SoftDeletes`.
3. Endpoint hapus:

```text
DELETE /api/kurir/{id}
DELETE /api/couriers/{id}
DELETE /api/wilayah/{id}
```

4. Relasi pesanan memakai `withTrashed()`:

```php
public function courier(): BelongsTo
{
    return $this->belongsTo(Courier::class, 'kurir_id')->withTrashed();
}
```

5. `GET /api/kurir` hanya menampilkan kurir yang belum dihapus.
6. Checkout baru menolak kurir yang sudah dihapus karena global scope
   `SoftDeletes` aktif pada model `Courier`.

### Alur hapus

```text
DELETE /api/kurir/{id}
  |
  |-- tidak ditemukan ----> 404
  |
  v
Cek apakah kurir dipakai orders
  |
  v
Set deleted_at (soft delete)
  |
  v
200 + id + dipakai_pada_pesanan
```

### Mengapa pesanan lama tetap aman

- Baris `couriers` tidak benar-benar dihapus.
- `orders.kurir_id` tetap menunjuk baris yang sama.
- Detail pesanan memakai relasi `withTrashed()` sehingga nama, wilayah, dan
  tarif kurir lama tetap tampil.
- `orders.ongkir` juga sudah menyimpan tarif saat checkout, sehingga nilai
  ongkir historis tidak berubah.

### Tiga tarif berbeda

`GET /api/kurir`, `GET /api/couriers`, dan `GET /api/wilayah` mengembalikan
kurir aktif terurut berdasarkan tarif. Pengujian memakai tiga tarif:

```text
10000
20000
35000
```

Kurir nonaktif dan kurir yang sudah dihapus tidak ikut dikembalikan.

---

## 4. Verifikasi Pesanan

### Riwayat

`GET /api/pesanan` memakai urutan:

```sql
ORDER BY created_at DESC, id DESC
```

Pesanan terbaru selalu muncul lebih dahulu.

### Detail dan snapshot harga

`GET /api/pesanan/{id}` mengembalikan item dari `order_items`:

- `nama_produk`
- `harga_satuan`
- `subtotal`

Nilai tersebut adalah snapshot saat transaksi. Jika nama atau harga produk di
katalog berubah setelah checkout, detail pesanan lama tidak berubah.

### Seluruh transisi status

Peta transisi:

```text
menunggu_pembayaran -> menunggu_konfirmasi, dibatalkan
menunggu_konfirmasi -> dibayar, dibatalkan
dibayar             -> diproses
diproses            -> dikirim
dikirim             -> selesai
selesai             -> tidak ada
dibatalkan          -> tidak ada
```

Status di luar peta tersebut, termasuk status yang sama, ditolak `409`.
Pesanan `selesai` dan `dibatalkan` tidak dapat dihidupkan kembali.

Pengujian `PesananStatusTransitionTest` memeriksa seluruh kombinasi status awal
dan status tujuan, baik yang legal maupun ilegal.

---

## 5. Finalisasi Checkout

### Validasi

- `nama_penerima`, `alamat_penerima` wajib.
- `kurir_id` wajib, harus ada, dan aktif.
- `payment_method_id` wajib, harus ada, dan aktif.
- Minimal satu item.
- Produk tidak boleh duplikat dalam satu payload.
- `quantity` minimal 1.
- `tanggal_antar` wajib, format `YYYY-MM-DD`, tidak boleh lampau.
- `slot_pengantaran` wajib dan harus salah satu dari `pagi`, `siang`, `sore`.
- Kunci idempoten wajib.

### Batas kuantitas produk mudah rusak

Produk dengan `mudah_rusak = true`:

- Wajib dikirim pada hari yang sama.
- Kuantitas maksimum per produk per pesanan mengikuti
  `config('checkout.max_mudah_rusak_per_pesanan')`, default `5`.

Pelanggaran menghasilkan `422` dan seluruh transaksi di-rollback.

### Transaksi dan lock

```text
DB::transaction
  |
  |-- lock produk berurutan berdasarkan product_id
  |-- lock baris keranjang pelanggan
  |-- validasi ulang ketersediaan, stok, mudah rusak, batas kuantitas
  |-- lock kurir aktif dan ambil tarif
  |-- validasi metode pembayaran aktif
  |-- subtotal = SUM(harga produk x quantity)
  |-- ongkir = tarif kurir
  |-- total = subtotal + ongkir
  |-- simpan orders
  |-- simpan order_items (snapshot)
  |-- kurangi stok
  |-- hapus item keranjang yang di-checkout
  |
  v
commit
```

Jika salah satu langkah gagal, seluruh perubahan di-rollback.

### Idempotensi

- Kunci dibaca dari `X-Kunci-Idempoten`, `X-Idempotency-Key`,
  `Idempotency-Key`, atau body `idempotency_key`.
- Kunci yang sama + payload sama: `200` dengan pesanan lama.
- Kunci yang sama + payload berbeda: `409`.
- Dua request paralel dengan kunci sama: satu membuat pesanan, satu menerima
  respons idempoten dengan `id` yang sama.
- `orders.idempotency_key` memiliki constraint unik.

---

## 6. Demonstrasi Checkout

Demonstrasi otomatis tersedia di `tests/Feature/CheckoutDemoTest.php`.

### Skenario 1: checkout berhasil

Input:

```json
{
  "nama_penerima": "Penerima Uji",
  "alamat_penerima": "Jl. Pengujian No. 1",
  "kurir_id": 1,
  "payment_method_id": 1,
  "tanggal_antar": "HARI_INI",
  "slot_pengantaran": "pagi",
  "items": [
    { "product_id": 1, "quantity": 2 }
  ]
}
```

Hasil:

- HTTP `201`.
- `subtotal = 10000`, `ongkir = 10000`, `total_harga = 20000`.
- Snapshot item tersimpan.
- Stok berkurang dari `10` menjadi `8`.
- Satu pesanan dan satu detail pesanan.

### Skenario 2: ditolak karena kuantitas

Input sama, tetapi `quantity = 6` untuk produk mudah rusak dengan batas `5`.

Hasil:

- HTTP `422`.
- Pesan: `Kuantitas maksimal 5 untuk produk 'Bayam Demo'`.
- Tidak ada pesanan.
- Tidak ada detail pesanan.
- Stok tetap `10`.

### Skenario 3: ditolak karena tanggal

Input sama, tetapi `tanggal_antar` adalah besok untuk produk mudah rusak.

Hasil:

- HTTP `422`.
- Pesan: `Produk 'Bayam Demo' wajib dikirim pada hari yang sama`.
- Tidak ada pesanan.
- Tidak ada detail pesanan.
- Stok tetap `10`.

### Skenario 4: retry tidak membuat pesanan ganda

1. Checkout pertama dengan kunci `demo-retry` menghasilkan `201`.
2. Checkout ulang dengan payload dan kunci sama menghasilkan `200`.
3. `data.id` pada respons kedua sama dengan respons pertama.

Hasil akhir:

- Tabel `orders` berisi satu baris.
- Tabel `order_items` berisi satu baris.
- Stok hanya berkurang sekali, dari `10` menjadi `8`.

### Menjalankan demonstrasi

```shell
php artisan test --filter=CheckoutDemoTest
```

Hasil:

```text
4 tests, 35 assertions, passed
```

---

## 7. Pengujian

```shell
php artisan test --filter=KeranjangTest
php artisan test --filter=KurirTest
php artisan test --filter=PesananStatusTransitionTest
php artisan test --filter=CheckoutDemoTest
php artisan test
```

Hasil terakhir:

```text
KeranjangTest              : 7 tests, 43 assertions, passed
KurirTest                  : 3 tests, 38 assertions, passed
PesananStatusTransitionTest: 1 test, 251 assertions, passed
CheckoutDemoTest           : 4 tests, 35 assertions, passed
Semua test                 : 69 tests, 745 assertions, passed
```

Pint untuk seluruh file yang diubah dan ditambah: passed.

---

## 8. Saran Nama Commit

Jika seluruh perubahan ini dijadikan satu commit:

```text
fix(pesanan): amankan keranjang, hapus kurir, dan finalisasi checkout
```

Body commit yang disarankan:

```text
- kunci produk dan baris keranjang saat update jumlah keranjang
- tambah soft delete kurir/wilayah agar riwayat pesanan tetap utuh
- tampilkan relasi kurir lama melalui withTrashed pada pesanan
- verifikasi tiga tarif, snapshot harga, riwayat, detail, dan matriks status
- finalisasi validasi checkout, batas kuantitas, same-day, lock, dan idempotensi
- tambah demonstrasi checkout berhasil, kuantitas, tanggal, dan retry
```

Alternatif:

```text
fix(checkout): perkuat transaksi, kurir, dan validasi pesanan
```

Nama branch yang disarankan:

```text
fix/keranjang-kurir-pesanan-checkout
```
