# Pesanan, Status, Kurir, dan Penyelesaian Checkout

Dokumen ini menjelaskan objektif:

- `GET /api/pesanan`
- `GET /api/pesanan/{id}`
- `PATCH /api/pesanan/{id}/status`
- `POST /api/pesanan/{id}/selesai` (konfirmasi pelanggan)
- `GET /api/kurir` (kurir/wilayah + tarif)
- Penyelesaian `POST /api/checkout`

Dokumen ini melengkapi `docs/CHECKOUT_SPESIFIKASI.md`,
`docs/ERD_TRANSAKSI.md`, dan `docs/PERBAIKAN_TEMUAN_DAN_DEMO_CHECKOUT.md`.

---

## 1. Ringkasan Endpoint

| Method | Path | Fungsi |
|--------|------|--------|
| `GET` | `/api/pesanan` | Daftar riwayat pesanan, terbaru lebih dahulu |
| `GET` | `/api/pesanan/{id}` | Detail pesanan + snapshot nama/harga produk |
| `PATCH` | `/api/pesanan/{id}/status` | Mengubah status dengan aturan transisi (admin) |
| `POST` | `/api/pesanan/{id}/selesai` | Pelanggan menandai pesanan diterima |
| `GET` | `/api/kurir` | Daftar kurir/wilayah aktif beserta tarif |
| `GET` | `/api/couriers` | Alias `/api/kurir` |
| `GET` | `/api/wilayah` | Alias `/api/kurir` |
| `DELETE` | `/api/kurir/{id}` | Soft delete kurir tanpa merusak pesanan lama |
| `DELETE` | `/api/couriers/{id}` | Alias `/api/kurir/{id}` |
| `DELETE` | `/api/wilayah/{id}` | Soft delete wilayah tanpa merusak pesanan lama |
| `POST` | `/api/checkout` | Membuat pesanan secara transaksional |

Semua respons memakai format konsisten:

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Pesan",
  "data": {}
}
```

Respons gagal menambahkan `errors` bila berkaitan dengan validasi.

---

## 2. `GET /api/pesanan`

### Perilaku

- Mengambil seluruh pesanan dari tabel `orders`.
- Relasi yang dimuat: `items.product`, `courier`, dan `paymentMethod`.
- Urutan: `created_at DESC`, lalu `id DESC` sebagai penentu jika timestamp sama.
- Tidak mengubah data apa pun.

### Alur

```text
Request GET /api/pesanan
  |
  v
Order::with(items.product, courier, paymentMethod)
  |
  v
ORDER BY created_at DESC, id DESC
  |
  v
200 + daftar pesanan
```

### Contoh respons

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Daftar pesanan berhasil diambil",
  "data": [
    {
      "id": 12,
      "pelanggan_id": 1,
      "nama_penerima": "Budi",
      "alamat_penerima": "Jl. Raya No. 10",
      "subtotal": 10000,
      "ongkir": 10000,
      "total_harga": 20000,
      "status": "menunggu_pembayaran",
      "items": [
        {
          "product_id": 2,
          "nama_produk": "Bayam Hijau",
          "quantity": 2,
          "harga_satuan": 5000,
          "subtotal": 10000
        }
      ]
    }
  ]
}
```

---

## 3. `GET /api/pesanan/{id}`

### Perilaku

- Mengambil satu pesanan beserta item dan relasi pendukung.
- Jika pesanan tidak ditemukan: `404` dengan `status = gagal`.
- Detail item memakai **snapshot transaksi**, bukan data katalog terbaru:
  - `order_items.nama_produk`
  - `order_items.harga_satuan`
  - `order_items.subtotal`
- Relasi `items.product` tetap dimuat untuk referensi, tetapi tampilan riwayat
  harus memakai kolom snapshot.

### Alur

```text
Request GET /api/pesanan/{id}
  |
  v
Cari order + items.product + courier + paymentMethod
  |
  |-- tidak ada ----> 404
  |
  v
200 + detail pesanan (snapshot tetap)
```

### Contoh respons

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Rincian pesanan berhasil diambil",
  "data": {
    "id": 12,
    "status": "menunggu_pembayaran",
    "subtotal": 10000,
    "ongkir": 10000,
    "total_harga": 20000,
    "items": [
      {
        "product_id": 2,
        "nama_produk": "Bayam Hijau",
        "quantity": 2,
        "harga_satuan": 5000,
        "subtotal": 10000
      }
    ]
  }
}
```

Jika nama atau harga produk di katalog diubah setelah checkout, nilai
`nama_produk`, `harga_satuan`, dan `subtotal` pada respons detail tidak berubah.

---

## 4. `PATCH /api/pesanan/{id}/status`

### Request

```json
{
  "status": "diproses"
}
```

### Status yang dikenal

```text
menunggu_pembayaran
menunggu_konfirmasi
dibayar
diproses
dikirim
tiba
selesai
dibatalkan
```

### Peta transisi legal

```text
menunggu_pembayaran -> menunggu_konfirmasi
menunggu_pembayaran -> dibatalkan

menunggu_konfirmasi -> dibayar
menunggu_konfirmasi -> dibatalkan

dibayar  -> diproses
diproses -> dikirim
dikirim  -> tiba
dikirim  -> selesai (konfirmasi pelanggan)
tiba     -> selesai

selesai    -> (tidak ada)
dibatalkan -> (tidak ada)
```

Transisi di luar peta tersebut, termasuk mengubah ke status yang sama,
dianggap ilegal dan dibalas `409 Conflict`.

### Alur

```text
Request PATCH /api/pesanan/{id}/status
  |
  v
Validasi field status
  |
  |-- tidak valid / kosong ----> 422
  |
  v
DB::transaction
  |-- SELECT ... FOR UPDATE pada orders
  |
  |-- pesanan tidak ada ----> 404
  |
  |-- canTransitionTo(status) false ----> 409
  |
  |-- simpan status baru
  |-- commit
  |
  v
200 + data pesanan terbaru
```

### Respons sukses

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Status pesanan berhasil diperbarui",
  "data": {
    "id": 12,
    "status": "diproses"
  }
}
```

### Respons transisi ilegal

```json
{
  "status": "gagal",
  "code": "409",
  "message": "Transisi status dari 'menunggu_pembayaran' ke 'dikirim' tidak diizinkan",
  "errors": {
    "status": ["Transisi status pesanan tidak diizinkan."]
  }
}
```

### Penyelesaian oleh pelanggan: `POST /api/pesanan/{id}/selesai`

Pelanggan pemilik pesanan dapat menandai pesanan diterima ketika status
`dikirim` atau `tiba`. Endpoint ini memakai transaksi dan `lockForUpdate`,
lalu mengubah status menjadi `selesai`, mengisi `selesai_at`, dan mengisi
`tiba_at` bila masih kosong.

| Kondisi | HTTP |
|---------|------|
| Status berhasil diubah menjadi `selesai` | `200` |
| Bukan pemilik pesanan | `403` |
| Pesanan belum dikirim atau sudah selesai/dibatalkan | `409` |
| Pesanan tidak ditemukan | `404` |

### Ringkasan status code

| Kondisi | HTTP |
|---------|------|
| Status berhasil diubah | `200` |
| Field status tidak dikirim / nilai tidak dikenal | `422` |
| Pesanan tidak ditemukan | `404` |
| Transisi ilegal | `409` |

---

## 5. `GET /api/kurir`

### Perilaku

- Mengambil kurir/wilayah aktif dari tabel `couriers`.
- Diurutkan berdasarkan `tarif` naik.
- Setiap data memuat `nama`, `wilayah`, `tarif`, dan `aktif`.

### Contoh respons

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Daftar kurir/wilayah antar berhasil diambil",
  "data": [
    {
      "id": 1,
      "nama": "Kurir Toko Area Dekat",
      "wilayah": "Dalam Kota (0-5 km)",
      "tarif": 10000,
      "aktif": true
    },
    {
      "id": 2,
      "nama": "Kurir Toko Area Sedang",
      "wilayah": "Kecamatan Sekitar (5-15 km)",
      "tarif": 20000,
      "aktif": true
    },
    {
      "id": 3,
      "nama": "Kurir Toko Area Jauh",
      "wilayah": "Luar Kota (>15 km)",
      "tarif": 35000,
      "aktif": true
    }
  ]
}
```

Tarif inilah yang dipakai server saat menghitung `ongkir` pada checkout.

### Penghapusan kurir/wilayah

`DELETE /api/kurir/{id}`, `DELETE /api/couriers/{id}`, dan
`DELETE /api/wilayah/{id}` melakukan soft delete dengan mengisi
`couriers.deleted_at`.

- Kurir yang tidak ditemukan menghasilkan `404`.
- Respons `200` memuat `id` dan `dipakai_pada_pesanan`.
- Kurir yang sudah dihapus tidak muncul pada `GET /api/kurir`.
- Checkout baru dengan kurir yang sudah dihapus ditolak `422`.
- Pesanan lama tetap menampilkan nama, wilayah, dan tarif kurir karena relasi
  `courier` memakai `withTrashed()`.
- Nilai `orders.ongkir` tetap menjadi snapshot tarif saat checkout.

---

## 6. Penyelesaian `POST /api/checkout`

Endpoint checkout sudah memenuhi objektif transaksi berikut.

### Validasi dan aturan domain

- Kunci idempoten wajib dikirim melalui:
  - `X-Kunci-Idempoten`
  - `X-Idempotency-Key`
  - `Idempotency-Key`
  - atau body `idempotency_key`
- Payload wajib memuat penerima, alamat, kurir, metode pembayaran, tanggal,
  slot, dan minimal satu item.
- `items` boleh tidak dikirim; server memakai isi keranjang pelanggan.
- Produk mudah rusak:
  - wajib dikirim pada hari yang sama;
  - kuantitas per produk per pesanan dibatasi
    `config('checkout.max_mudah_rusak_per_pesanan')` (default `5`).
- Slot sah: `pagi`, `siang`, `sore`.
- Baris item duplikat untuk produk yang sama ditolak `422`.

### Transaksi dan locking

```text
DB::transaction
  |-- lock produk dengan urutan product_id (FOR UPDATE)
  |-- lock baris keranjang (FOR UPDATE)
  |-- validasi ulang stok, ketersediaan, mudah rusak, dan batas maksimum
  |-- lock kurir + hitung ongkir dari tarif
  |-- hitung subtotal dari harga produk
  |-- simpan orders
  |-- simpan order_items (snapshot nama, harga, subtotal)
  |-- kurangi stok produk
  |-- hapus item keranjang yang di-checkout
  |-- commit
```

Urutan lock produk lalu keranjang disamakan dengan alur keranjang untuk
mencegah deadlock. Jika isi keranjang berubah di tengah checkout, server
mengembalikan `409`.

### Perhitungan server

- `subtotal` = Σ(`products.harga` × `quantity`)
- `ongkir` = `couriers.tarif`
- `total_harga` = `subtotal + ongkir`

Nilai `subtotal`, `ongkir`, atau `total` dari klien diabaikan.

### Idempotensi dan rollback

- `orders.idempotency_key` memiliki constraint `UNIQUE`.
- `orders.idempotency_request_hash` menyimpan SHA-256 payload.
- Kunci sama + payload sama: `200` dengan pesanan lama, tanpa menambah stok
  atau pesanan baru.
- Kunci sama + payload berbeda: `409`.
- Jika terjadi kegagalan di tengah transaksi, seluruh perubahan di-rollback:
  stok, keranjang, pesanan, dan detail pesanan tidak berubah sebagian.

---

## 7. File yang Diubah

| File | Perubahan |
|------|-----------|
| `routes/api.php` | Route daftar, detail, `PATCH` status, dan hapus kurir/wilayah |
| `app/Http/Controllers/CheckoutController.php` | Urutan riwayat, detail, update status, checkout transaksional, idempotensi paralel, eager load snapshot produk |
| `app/Http/Controllers/KeranjangController.php` | Update jumlah keranjang transaksional dengan `lockForUpdate` |
| `app/Http/Controllers/KurirController.php` | Respons kurir/wilayah + tarif dan soft delete kurir |
| `app/Models/Pesanan.php` | Daftar status, peta transisi, relasi kurir `withTrashed()` |
| `app/Models/Order.php` | Fillable/hidden hash idempotensi, relasi kurir `withTrashed()` |
| `app/Models/Courier.php` | `SoftDeletes` |
| `app/Models/WilayahAntar.php` | `SoftDeletes` |
| `app/Models/OrderItem.php` | Snapshot item |
| `database/migrations/2026_11_09_000001_add_soft_deletes_to_couriers_table.php` | Kolom `deleted_at` untuk kurir/wilayah |
| `tests/Feature/CheckoutTest.php` | Pengujian riwayat, detail, status, checkout |
| `tests/Feature/KeranjangTest.php` | Pengujian keranjang, termasuk revalidasi stok/ketersediaan |
| `tests/Feature/KurirTest.php` | Pengujian wilayah, tarif, dan penghapusan kurir |
| `tests/Feature/PesananAcceptanceTest.php` | Pengujian acceptance endpoint, status, pembayaran, dan checkout sekuensial |
| `tests/Feature/PesananCompletionTest.php` | Pengujian konfirmasi pelanggan dari `dikirim`/`tiba` menjadi `selesai` |
| `tests/Feature/PesananStatusTransitionTest.php` | Pengujian matriks seluruh transisi status |
| `tests/Feature/CheckoutDemoTest.php` | Demonstrasi empat skenario checkout |
| `tests/Feature/CheckoutConcurrencyTest.php` | Pengujian dua checkout hampir bersamaan |
| `tests/Support/CheckoutFixtures.php` | Fixture bersama data checkout |
| `tests/Support/checkout_request.php` | Proses anak untuk request checkout paralel |
| `docs/PERBAIKAN_TEMUAN_DAN_DEMO_CHECKOUT.md` | Dokumen perbaikan temuan dan demo |
| `docs/PENGUJIAN_PESANAN_DAN_CHECKOUT.md` | Penjelasan pengujian dan konkurensi |
| `docs/PESANAN_DAN_STATUS.md` | Dokumen ini |
| `docs/CHECKOUT_SPESIFIKASI.md` | Rujukan checkout transaksional |
| `docs/ERD_TRANSAKSI.md` | Rujukan status dan file |

---

## 8. Pengujian

Perintah:

```shell
php artisan test --filter=CheckoutTest
php artisan test --filter=KeranjangTest
php artisan test --filter=KurirTest
php artisan test --filter=PesananAcceptanceTest
php artisan test --filter=PesananStatusTransitionTest
php artisan test --filter=CheckoutDemoTest
php artisan test --filter=CheckoutConcurrencyTest
php artisan test
```

Hasil terakhir:

```text
CheckoutTest               : 32 tests, 181 assertions, passed
KeranjangTest              : 7 tests, 43 assertions, passed
KurirTest                  : 3 tests, 38 assertions, passed
PesananAcceptanceTest      : 12 tests, 141 assertions, passed
PesananStatusTransitionTest: 1 test, 251 assertions, passed
CheckoutDemoTest           : 4 tests, 35 assertions, passed
CheckoutConcurrencyTest    : 2 tests, 24 assertions, passed
PesananCompletionTest      : 5 tests, 25 assertions, passed
Semua test                 : 84 tests, 770 assertions, passed
```

Skenario penting yang diuji:

- Daftar pesanan terbaru lebih dahulu.
- Detail pesanan memakai snapshot setelah nama/harga katalog berubah.
- Detail pesanan tidak ditemukan menghasilkan `404`.
- Transisi status legal mengikuti peta.
- Transisi ilegal menghasilkan `409` dan status tidak berubah.
- Pembatalan hanya boleh dari `menunggu_pembayaran` atau
  `menunggu_konfirmasi`.
- Status tidak dikenal menghasilkan `422`.
- Update status untuk pesanan yang tidak ada menghasilkan `404`.
- Respons kurir memuat `wilayah` dan `tarif`.
- Tiga tarif berbeda tampil dan terurut naik.
- Kurir yang dihapus hilang dari daftar, tetapi detail pesanan lama tetap utuh.
- Checkout baru dengan kurir yang sudah dihapus ditolak `422`.
- Update keranjang memvalidasi ulang stok dan ketersediaan secara transaksional.
- Matriks seluruh kombinasi status awal dan tujuan diuji, legal maupun ilegal.
- Checkout: stok, batas mudah rusak, same-day, total server, idempotensi,
  rollback, dan pembersihan keranjang.
- Demonstrasi checkout sukses, kuantitas ditolak, tanggal ditolak, dan retry
  idempoten tersedia di `docs/PERBAIKAN_TEMUAN_DAN_DEMO_CHECKOUT.md`.
- Dua metode pembayaran tersimpan dan tampil pada endpoint.
- Status tidak dapat melompati tahap atau menghidupkan pesanan
  `selesai`/`dibatalkan`.
- Dua checkout paralel pada stok terbatas hanya menghasilkan satu pesanan.
- Dua request paralel dengan kunci idempoten sama menghasilkan satu pesanan
  dan satu respons idempoten.
- Pemeriksaan database memastikan tidak ada pesanan ganda atau perubahan
  stok/keranjang setengah jadi. Detail lengkap ada di
  `docs/PENGUJIAN_PESANAN_DAN_CHECKOUT.md`.

---

## 9. Saran Nama Commit

Jika seluruh perubahan ini akan dijadikan satu commit, gunakan pesan berikut.

### Opsi utama

```text
feat(pesanan): selesaikan checkout transaksional, riwayat, detail snapshot, dan status
```

Body commit yang disarankan:

```text
- tambah GET /api/pesanan dengan urutan terbaru lebih dahulu
- tambah GET /api/pesanan/{id} dengan snapshot nama dan harga produk
- tambah PATCH /api/pesanan/{id}/status dengan aturan transisi dan 409
- lengkapi GET /api/kurir dengan wilayah dan tarif
- selesaikan checkout dengan DB::transaction, lockForUpdate, idempotensi,
  validasi stok/mudah rusak/same-day, perhitungan server, dan rollback
- tambah pengujian fitur untuk riwayat, detail, status, kurir, dan checkout
```

### Alternatif

```text
feat(checkout): lengkapi transaksi, riwayat pesanan, dan transisi status
```

Nama branch yang disarankan:

```text
feat/pesanan-status-checkout
```
