# Spesifikasi Checkout TokoTani

Dokumen ini merinci kontrak `POST /api/checkout`, aturan domain, strategi
idempotensi, dan strategi transaksi. Rancangan ini melengkapi ERD transaksi pada
`docs/ERD_TRANSAKSI.md`.

## 1. Kontrak Request

### 1.1 Header wajib

| Header             | Wajib | Keterangan                                      |
|--------------------|-------|-------------------------------------------------|
| `X-Kunci-Idempoten`| Ya    | Kunci unik satu percobaan checkout dari Flutter |
| `X-Pelanggan-Id`   | Tidak | Fallback `1` bila tidak dikirim                 |
| `Content-Type`     | Ya    | `application/json`                              |

Alias kunci yang tetap diterima untuk kompatibilitas: `X-Idempotency-Key`,
`Idempotency-Key`, atau field body `idempotency_key`. Header
`X-Kunci-Idempoten` menjadi sumber utama.

### 1.2 Body

```json
{
  "nama_penerima": "Budi",
  "alamat_penerima": "Jl. Raya No. 10",
  "kurir_id": 1,
  "payment_method_id": 1,
  "tanggal_pengantaran": "2026-11-08",
  "slot_pengantaran": "pagi",
  "items": [
    { "product_id": 2, "quantity": 2 }
  ]
}
```

Alias yang diterima:

| Field utama           | Alias                                      |
|-----------------------|--------------------------------------------|
| `kurir_id`            | `courier_id`, `wilayah_id`, `wilayah_antar_id` |
| `payment_method_id`   | `metode_pembayaran_id`, `payment_method`   |
| `tanggal_pengantaran` | `tanggal_antar`                            |
| `slot_pengantaran`    | `slot`                                     |
| `items.*.product_id`  | `items.*.produk_id`                        |
| `items.*.quantity`    | `items.*.jumlah`, `items.*.qty`            |

Jika `items` tidak dikirim, backend memakai isi `keranjang` milik pelanggan.
Subtotal, ongkir, dan total yang dikirim Flutter **diabaikan**. Semua nilai
transaksi dihitung ulang di server.

### 1.3 Slot pengantaran

Nilai yang sah: `pagi`, `siang`, `sore` (lihat `config/checkout.php`).

## 2. Tabel Keputusan Domain

Batas maksimum produk mudah rusak per pesanan bersifat konfigurasi:
`config('checkout.max_mudah_rusak_per_pesanan')`, default **5** satuan per
produk per pesanan.

| Produk         | Kuantitas        | Tanggal pengantaran          | Stok        | Keputusan | HTTP | Pesan / kode                   | Efek database |
|----------------|------------------|------------------------------|-------------|-----------|------|--------------------------------|---------------|
| Mudah rusak    | <= batas         | Hari ini                     | Cukup       | Terima    | 201  | Checkout berhasil             | Pesanan + detail dibuat, stok berkurang, keranjang dikosongkan |
| Mudah rusak    | <= batas         | Hari ini                     | Tidak cukup | Tolak     | 422  | Stok tidak mencukupi           | Rollback utuh |
| Mudah rusak    | <= batas         | Bukan hari ini (besok/lusa)  | Cukup       | Tolak     | 422  | Wajib dikirim hari yang sama   | Rollback utuh |
| Mudah rusak    | <= batas         | Tanggal lampau / tidak sah   | Cukup       | Tolak     | 422  | Tanggal tidak sah              | Tidak ada perubahan |
| Mudah rusak    | > batas          | Hari ini                     | Cukup       | Tolak     | 422  | Melebihi batas mudah rusak     | Rollback utuh |
| Mudah rusak    | > batas          | Bukan hari ini               | Cukup       | Tolak     | 422  | Melebihi batas / bukan hari ini| Rollback utuh |
| Tidak mudah rusak | Berapa pun    | Hari ini atau tanggal >= hari ini | Cukup  | Terima    | 201  | Checkout berhasil             | Pesanan + detail dibuat, stok berkurang, keranjang dikosongkan |
| Tidak mudah rusak | Berapa pun    | Tanggal lampau / tidak sah   | Cukup       | Tolak     | 422  | Tanggal tidak sah              | Tidak ada perubahan |
| Apa pun        | Berapa pun       | Apa pun                      | Produk habis/tidak tersedia | Tolak | 409 | Produk habis/tidak tersedia | Tidak ada perubahan |
| Apa pun        | Berapa pun       | Apa pun                      | Cukup       | Terima    | 201  | Checkout berhasil             | Transaksi commit |

Catatan:

- Kuantitas `0`, negatif, atau bukan bilangan bulat ditolak `422`.
- Produk duplikat dalam satu payload ditolak `422`.
- `kurir_id` atau `payment_method_id` yang tidak ada/nonaktif ditolak `422`.
- Tanggal wajib format `YYYY-MM-DD` dan tidak boleh sebelum hari ini.
- Jika keranjang kosong dan `items` tidak dikirim, checkout ditolak `422`.

## 3. Respons

### 3.1 Sukses membuat pesanan (201)

```json
{
  "status": "sukses",
  "code": "201",
  "message": "Checkout berhasil diproses",
  "data": {
    "id": 10,
    "pelanggan_id": 1,
    "nama_penerima": "Budi",
    "alamat_penerima": "Jl. Raya No. 10",
    "kurir_id": 1,
    "payment_method_id": 1,
    "subtotal": 10000,
    "ongkir": 10000,
    "total_harga": 20000,
    "status": "menunggu_pembayaran",
    "tanggal_pengantaran": "2026-11-08",
    "slot_pengantaran": "pagi",
    "idempotency_key": "checkout-001",
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

### 3.2 Replay idempoten (200)

Kunci dan payload yang sama dikirim ulang:

```json
{
  "status": "sukses",
  "code": "200",
  "message": "Pesanan sudah diproses sebelumnya",
  "data": { "...pesanan yang sama..." }
}
```

### 3.3 Validasi gagal (422)

```json
{
  "status": "gagal",
  "code": "422",
  "message": "Validasi checkout gagal",
  "errors": {
    "slot_pengantaran": ["Slot pengantaran tidak valid."]
  }
}
```

### 3.4 Konflik (409)

Dipakai untuk:

- kunci idempoten sama dengan payload berbeda;
- produk habis/tidak tersedia;
- benturan kunci idempoten saat dua request bersamaan.

```json
{
  "status": "gagal",
  "code": "409",
  "message": "Kunci idempoten sudah digunakan untuk permintaan checkout yang berbeda",
  "errors": {
    "idempotency_key": ["Gunakan kunci baru untuk payload checkout yang berbeda."]
  }
}
```

## 4. Strategi Idempotensi

- Kunci disimpan pada `orders.idempotency_key` dengan constraint `UNIQUE`.
- Sidik jari request disimpan pada `orders.idempotency_request_hash` (SHA-256).
- Sidik jari dihitung dari payload yang sudah dinormalisasi, **tanpa** kunci
  idempoten, dengan urutan item berdasarkan `product_id`.
- Alur:
  1. Ambil kunci dari header/body. Kunci wajib ada.
  2. Normalisasi payload dan hitung sidik jari.
  3. Cari pesanan dengan kunci tersebut.
     - Ada dan hash sama -> kembalikan pesanan lama dengan **200**.
     - Ada dan hash berbeda -> **409**.
     - Belum ada -> lanjut validasi dan transaksi.
  4. Jika dua request bersamaan memakai kunci sama, constraint `UNIQUE`
     memastikan hanya satu pesanan yang dibuat. Request yang kalah menangkap
     `QueryException`, lalu membaca pesanan pemenang dan mengembalikannya.
- Kunci yang gagal validasi/transaksi tidak disimpan, sehingga percobaan ulang
  dengan kunci yang sama tetap dapat dilakukan setelah penyebab kegagalan
  diperbaiki.

## 5. Strategi Transaksi dan Locking

`POST /api/checkout` menjalankan seluruh perubahan dalam `DB::transaction`.

Urutan di dalam transaksi:

1. Kunci baris keranjang pelanggan dengan `lockForUpdate` (semua baris bila
   checkout dari keranjang, atau baris produk yang dipakai bila payload
   `items` dikirim).
2. Urutkan item berdasarkan `product_id` untuk mencegah deadlock.
3. Kunci setiap baris produk dengan `lockForUpdate`.
4. Validasi ulang ketersediaan, stok, aturan mudah rusak, dan batas maksimum.
5. Kunci baris kurir dan hitung ongkir dari `couriers.tarif`.
6. Hitung subtotal dari `products.harga * quantity`.
7. Buat `orders` dan `order_items` dengan snapshot `nama_produk` dan
   `harga_satuan`.
8. Kurangi stok; set `tersedia = false` jika stok menjadi 0.
9. Hapus baris keranjang yang sudah di-checkout.
10. Commit.

Jika salah satu langkah melempar error atau validasi domain gagal, seluruh
transaksi di-rollback. Tidak ada stok, keranjang, pesanan, atau detail pesanan
yang berubah sebagian.

## 6. Skenario Pengujian Wajib

| Skenario | Ekspektasi |
|----------|------------|
| Checkout valid | 201, satu pesanan, stok berkurang, snapshot tersimpan |
| Kunci idempoten sama + payload sama | 200, tidak ada pesanan/stok tambahan |
| Kunci idempoten sama + payload berbeda | 409 |
| Kunci idempoten tidak dikirim | 422 |
| Batas mudah rusak dilanggar | 422, rollback |
| Mudah rusak dikirim bukan hari ini | 422, rollback |
| Tanggal lampau/tidak sah | 422, tidak ada perubahan |
| Slot tidak valid | 422 |
| Stok tidak cukup | 422, rollback |
| Produk tidak tersedia | 409 |
| Kegagalan pada item kedua | Item pertama tidak mengurangi stok, tidak ada pesanan |
| Client mengirim subtotal/ongkir/total palsu | Nilai server yang dipakai |
| Checkout dari keranjang | Keranjang terkunci, pesanan dibuat, keranjang kosong |

## 7. Ringkasan Implementasi

### 7.1 File yang ditambahkan/diubah

| File | Peran |
|------|-------|
| `config/checkout.php` | Batas maksimum produk mudah rusak dan daftar slot sah |
| `database/migrations/2026_11_08_000005_add_idempotency_hash_to_orders_table.php` | Kolom `idempotency_request_hash` pada `orders` |
| `app/Models/Order.php` | Fillable + hidden `idempotency_request_hash` |
| `app/Models/Pesanan.php` | Fillable + hidden `idempotency_request_hash` |
| `app/Http/Controllers/CheckoutController.php` | Validasi, idempotensi, transaksi, locking, perhitungan server |
| `tests/Feature/CheckoutTest.php` | Feature test kerangka dan aturan domain |
| `docs/CHECKOUT_SPESIFIKASI.md` | Dokumen ini |
| `docs/ERD_TRANSAKSI.md` | Rujukan ke spesifikasi checkout dan hash idempoten |
| `.env.example` | Contoh `CHECKOUT_MAX_MUDAH_RUSAK=5` |

### 7.2 Alur eksekusi `POST /api/checkout`

```text
Request
  |
  v
Normalisasi alias payload
  |
  v
Ambil X-Kunci-Idempoten (wajib)
  |
  v
Tentukan pelanggan (header/fallback 1)
  |
  v
Hitung fingerprint request
  |
  v
Pesanan dengan kunci yang sama sudah ada?
  |-- ya, fingerprint sama ----> 200 pesanan lama
  |-- ya, fingerprint beda ----> 409
  |
  v
Validasi payload, kurir, metode bayar, tanggal, slot
  |
  v
DB::transaction
  |-- lock produk (urut product_id)
  |-- lock keranjang
  |-- validasi stok + mudah rusak + batas maksimum
  |-- lock kurir, hitung ongkir server
  |-- buat orders + order_items (snapshot)
  |-- kurangi stok
  |-- hapus item keranjang yang di-checkout
  |-- commit
  |
  v
201 + data pesanan
```

Jika ada langkah yang gagal setelah stok berubah, transaksi di-rollback. Jika
dua request memakai kunci yang sama secara bersamaan, constraint `UNIQUE`
memastikan hanya satu pesanan yang tersimpan; request lain mengembalikan pesanan
yang sama.

Urutan lock produk lalu keranjang disamakan dengan alur keranjang untuk
mencegah deadlock. Jika isi keranjang berubah di tengah checkout, server
mengembalikan `409` agar klien mengulangi checkout dengan data terbaru.

### 7.3 Hasil pengujian

Pengujian dijalankan dengan MySQL (`tokotani_testing`):

```text
php artisan test --filter=CheckoutTest
32 tests, 181 assertions, passed

php artisan test
47 tests, 256 assertions, passed
```

Skenario yang sudah dicakup antara lain: kunci idempoten wajib, retry dengan
kunci sama, kunci sama dengan payload berbeda, batas mudah rusak, penolakan
baris item duplikat, tanggal bukan hari ini, tanggal lampau, slot tidak valid,
stok tidak cukup, produk tidak tersedia, rollback saat item kedua gagal,
perhitungan server, alias payload, checkout dari keranjang, daftar pesanan
terbaru lebih dahulu, detail snapshot, dan transisi status pesanan. Detail
endpoint pesanan dan status dibahas di `docs/PESANAN_DAN_STATUS.md`.
