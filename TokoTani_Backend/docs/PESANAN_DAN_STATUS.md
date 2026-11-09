# Pesanan, Status, Kurir, dan Penyelesaian Checkout

Dokumen ini menjelaskan objektif:

- `GET /api/pesanan`
- `GET /api/pesanan/{id}`
- `PATCH /api/pesanan/{id}/status`
- `GET /api/kurir` (kurir/wilayah + tarif)
- Penyelesaian `POST /api/checkout`

Dokumen ini melengkapi `docs/CHECKOUT_SPESIFIKASI.md` dan
`docs/ERD_TRANSAKSI.md`.

---

## 1. Ringkasan Endpoint

| Method | Path | Fungsi |
|--------|------|--------|
| `GET` | `/api/pesanan` | Daftar riwayat pesanan, terbaru lebih dahulu |
| `GET` | `/api/pesanan/{id}` | Detail pesanan + snapshot nama/harga produk |
| `PATCH` | `/api/pesanan/{id}/status` | Mengubah status dengan aturan transisi |
| `GET` | `/api/kurir` | Daftar kurir/wilayah aktif beserta tarif |
| `GET` | `/api/couriers` | Alias `/api/kurir` |
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
dikirim  -> selesai

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
| `routes/api.php` | Route daftar, detail, dan `PATCH` status pesanan |
| `app/Http/Controllers/CheckoutController.php` | Urutan riwayat, detail, update status, checkout transaksional |
| `app/Models/Pesanan.php` | Daftar status dan peta transisi |
| `app/Models/Order.php` | Fillable/hidden hash idempotensi |
| `app/Models/OrderItem.php` | Snapshot item |
| `app/Http/Controllers/KurirController.php` | Respons kurir/wilayah + tarif |
| `tests/Feature/CheckoutTest.php` | Pengujian riwayat, detail, status, checkout |
| `tests/Feature/KurirTest.php` | Pengujian wilayah dan tarif |
| `docs/PESANAN_DAN_STATUS.md` | Dokumen ini |
| `docs/CHECKOUT_SPESIFIKASI.md` | Rujukan checkout transaksional |
| `docs/ERD_TRANSAKSI.md` | Rujukan status dan file |

---

## 8. Pengujian

Perintah:

```shell
php artisan test --filter=CheckoutTest
php artisan test --filter=KurirTest
php artisan test
```

Hasil terakhir:

```text
CheckoutTest : 32 tests, 181 assertions, passed
KurirTest    : 1 test, 7 assertions, passed
Semua test   : 47 tests, 256 assertions, passed
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
- Checkout: stok, batas mudah rusak, same-day, total server, idempotensi,
  rollback, dan pembersihan keranjang.

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
