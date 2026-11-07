# Tani Mart API Contract — Single Source of Truth

Dokumen ini mendefinisikan kontrak REST API resmi antara Laravel Backend dan Flutter Mobile Client untuk aplikasi **Tani Mart** (Tani Mart). Kontrak ini berfungsi sebagai **Sumber Kebenaran Tunggal (Single Source of Truth)**.

---

## 1. Standar Konvensi Global

### Base URL
- **Emulator Android:** `http://10.0.2.2:8000/api`
- **Perangkat Fisik (LAN Wi-Fi):** `http://<IP_KOMPUTER>:8000/api` (misal: `http://192.168.1.10:8000/api`)
- **Web / Desktop (Localhost):** `http://127.0.0.1:8000/api`

### Request Headers
Semua permintaan client ke server wajib menyertakan header:
```http
Accept: application/json
Content-Type: application/json
X-Pelanggan-Id: 1
```
Untuk operasi checkout dengan proteksi idempotensi, sertakan:
```http
X-Idempotency-Key: <unique-uuid-or-string>
```
*(Backend juga mendukung alias `X-Kunci-Idempoten`, `Idempotency-Key`, atau kolom JSON `idempotency_key`)*.

---

## 2. Struktur Standar Respons API

Semua endpoint mengembalikan struktur envelope yang seragam dan konsisten.

### Respons Berhasil (Single Item / Objek)
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Pesan deskriptif keberhasilan",
  "data": { ... },
  "meta": null
}
```

### Respons Berhasil (Collection / Daftar)
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Daftar data berhasil diambil",
  "data": [
    { ... },
    { ... }
  ],
  "meta": null
}
```

### Respons Galat Validasi (HTTP 422)
```json
{
  "success": false,
  "status": "gagal",
  "code": "422",
  "message": "Validasi gagal",
  "data": null,
  "meta": null,
  "errors": {
    "nama_kolom": [
      "Pesan spesifik kegagalan validasi."
    ]
  }
}
```

### Respons Galat Bentrok / Konflik Keadaan (HTTP 409)
```json
{
  "success": false,
  "status": "gagal",
  "code": "409",
  "message": "Stok tidak mencukupi atau produk masih terikat dengan pesanan aktif.",
  "data": null,
  "meta": null,
  "errors": null
}
```

### Respons Galat Tidak Ditemukan (HTTP 404)
```json
{
  "success": false,
  "status": "gagal",
  "code": "404",
  "message": "Data tidak ditemukan",
  "data": null,
  "meta": null,
  "errors": null
}
```

---

## 3. Rincian Endpoint API

### A. Kategori & Produk

#### 1. `GET /api/kategori`
- **Tujuan:** Mengambil daftar seluruh kategori produk yang tersedia.
- **Respons (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Daftar kategori berhasil diambil",
  "data": [
    { "id": 1, "nama_kategori": "Sayuran" },
    { "id": 2, "nama_kategori": "Sembako" }
  ],
  "meta": null
}
```

#### 2. `GET /api/produk`
- **Tujuan:** Mengambil katalog produk dengan dukungan filter.
- **Query Parameters:**
  - `kategori` *(string, opsional)*: Nama kategori (misal: `Sayuran`). Abaikan jika bernilai `'Semua'`.
  - `cari` *(string, opsional)*: Kata kunci pencarian nama produk (misal: `Beras`).
- **Respons (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Daftar produk berhasil diambil",
  "data": [
    {
      "id": 1,
      "nama": "Beras Pandan Wangi",
      "harga": 75000,
      "kategori": "Sembako",
      "category_id": 2,
      "stok": 20,
      "tersedia": true,
      "deskripsi": "Beras pulen berkualitas tinggi.",
      "satuan_jual": "pak 5kg",
      "mudah_rusak": false,
      "created_at": "2026-11-05T10:00:00.000000Z",
      "updated_at": "2026-11-05T10:00:00.000000Z"
    }
  ],
  "meta": null
}
```

#### 3. `GET /api/produk/{id}`
- **Tujuan:** Mengambil detail satu produk.
- **Respons Berhasil (200 OK):** Mengembalikan objek produk tunggal.
- **Respons Galat (404 Not Found):** Jika ID produk tidak ditemukan di database.

#### 4. `POST /api/produk`
- **Tujuan:** Menambahkan produk pertanian baru.
- **Request Body (JSON):**
```json
{
  "nama": "Tomat Ceri Segar",
  "harga": 15000,
  "kategori": "Sayuran",
  "category_id": 1,
  "stok": 25,
  "tersedia": true,
  "satuan_jual": "kg",
  "mudah_rusak": true,
  "deskripsi": "Tomat ceri merah manis dipetik langsung dari kebun hidroponik."
}
```
- **Aturan Validasi:**
  - `nama`: `required|string|max:255`
  - `harga`: `required|integer|min:0`
  - `stok`: `required|integer|min:0`
  - `tersedia`: `required|boolean`
  - `satuan_jual`: `required|string`
  - `mudah_rusak`: `required|boolean`
  - `category_id`: `nullable|integer|exists:categories,id`
- **Respons Berhasil (201 Created):** Objek produk yang baru disimpan.

#### 5. `PUT /api/produk/{id}`
- **Tujuan:** Memperbarui data produk pertanian.
- **Request Body (JSON):** Bidang opsional atau sebagian yang ingin diubah.
- **Respons:** 200 OK (berhasil) atau 422 Unprocessable Entity (validasi gagal).

#### 6. `DELETE /api/produk/{id}`
- **Tujuan:** Menghapus produk.
- **Aturan Bisnis Integritas:**
  - Jika produk terikat pada pesanan aktif (status bukan `selesai` atau `dibatalkan`), server menolak dengan **HTTP 409 Conflict**: *"Produk tidak dapat dihapus karena masih terpakai pada pesanan aktif"*.
  - Jika produk memiliki riwayat transaksi lampau, server menolak penghapusan fisik demi audit integritas keuangan.
- **Respons Berhasil (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Produk berhasil dihapus",
  "data": null,
  "meta": null
}
```

---

### B. Keranjang Belanja (Cart)

Keranjang belanja dikelola secara terpusat di server database agar menjadi sumber kebenaran tunggal (*Single Source of Truth*). Subtotal selalu dihitung oleh server.

#### 1. `GET /api/keranjang`
- **Header:** `X-Pelanggan-Id: <id>` (default `1`)
- **Respons (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Isi keranjang belanja berhasil diambil",
  "data": {
    "items": [
      {
        "id": 12,
        "customer_id": 1,
        "produk_id": 1,
        "nama": "Beras Pandan Wangi",
        "harga": 75000,
        "jumlah": 2,
        "stok": 20,
        "satuan_jual": "pak 5kg",
        "mudah_rusak": false,
        "foto": null,
        "subtotal": 150000,
        "produk": {
          "id": 1,
          "nama": "Beras Pandan Wangi",
          "harga": 75000,
          "stok": 20,
          "tersedia": true,
          "satuan_jual": "pak 5kg",
          "mudah_rusak": false
        }
      }
    ],
    "subtotal": 150000
  },
  "meta": null
}
```

#### 2. `POST /api/keranjang`
- **Request Body (JSON):**
```json
{
  "produk_id": 1,
  "jumlah": 2
}
```
- **Aturan Bisnis & Validasi:**
  - Jika stok habis atau tidak tersedia: mengembalikan **HTTP 409 Conflict**.
  - Jika jumlah yang diminta melebihi stok yang ada di database: mengembalikan **HTTP 409 Conflict**.
  - Jika item sudah ada di keranjang, kuantitas akan dijumlahkan dan divalidasi terhadap total stok.
- **Respons Berhasil (201 Created):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "201",
  "message": "Produk berhasil ditambahkan ke keranjang",
  "data": {
    "id": 12,
    "produk_id": 1,
    "jumlah": 2
  },
  "meta": null
}
```

#### 3. `PUT /api/keranjang/{id}`
- **Tujuan:** Mengubah jumlah item di keranjang.
- **Request Body (JSON):**
```json
{
  "jumlah": 3
}
```
- **Aturan:**
  - Jika `jumlah <= 0`: mengembalikan **HTTP 422 Unprocessable Entity**.
  - Jika `jumlah > stok`: mengembalikan **HTTP 409 Conflict**.
- **Respons Berhasil (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Jumlah item keranjang berhasil diperbarui",
  "data": {
    "id": 12,
    "produk_id": 1,
    "jumlah": 3
  },
  "meta": null
}
```

#### 4. `DELETE /api/keranjang/{id}`
- **Tujuan:** Menghapus satu item dari keranjang belanja.
- **Respons (200 OK):** Pesan keberhasilan penghapusan.

#### 5. `DELETE /api/keranjang`
- **Tujuan:** Mengosongkan seluruh keranjang belanja pelanggan aktif.
- **Respons (200 OK):** Pesan konfirmasi pengosongan keranjang.

---

### C. Kurir & Metode Pembayaran

#### 1. `GET /api/kurir`
- **Respons (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Daftar kurir berhasil diambil",
  "data": [
    { "id": 1, "nama": "Kurir Toko (Same Day)", "tarif": 15000, "aktif": true },
    { "id": 2, "nama": "JNE Reguler", "tarif": 10000, "aktif": true }
  ],
  "meta": null
}
```

#### 2. `GET /api/metode-pembayaran`
- **Respons (200 OK):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "200",
  "message": "Daftar metode pembayaran berhasil diambil",
  "data": [
    { "id": 1, "nama": "Transfer Bank (BCA)", "deskripsi": "Transfer manual ke rek BCA", "aktif": true },
    { "id": 2, "nama": "QRIS", "deskripsi": "Pembayaran instan via scan QRIS", "aktif": true },
    { "id": 3, "nama": "COD (Bayar di Tempat)", "deskripsi": "Bayar tunai saat kurir tiba", "aktif": true }
  ],
  "meta": null
}
```

---

### D. Checkout & Pesanan (Orders)

#### 1. `POST /api/checkout`
- **Tujuan:** Melakukan transaksi pemesanan secara atomik (*Database Transaction*).
- **Header:**
  - `X-Idempotency-Key`: String unik untuk mencegah pesanan ganda akibat klik berulang atau koneksi terputus.
  - `X-Pelanggan-Id`: ID pelanggan (default `1`).
- **Request Body (JSON):**
```json
{
  "nama_penerima": "Budi Santoso",
  "alamat_penerima": "Jl. Agribisnis No. 12, Sleman, D.I. Yogyakarta",
  "kurir_id": 1,
  "payment_method_id": 2,
  "tanggal_antar": "2026-11-07",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 3, "quantity": 1 }
  ]
}
```
- **Aturan Bisnis & Validasi:**
  1. **Aturan Produk Mudah Rusak (*Perishable*):**
     Jika salah satu produk dalam pesanan berlabel `mudah_rusak = true`, maka `tanggal_antar` **WAJIB** sama dengan hari ini (`isSameDay`). Jika tidak, server mengembalikan **HTTP 422**.
  2. **Pencegahan Deadlock:**
     Item dikunci menggunakan `lockForUpdate()` dengan urutan terurut berdasarkan `product_id` menaik.
  3. **Pengurangan Stok Otomatis:**
     Stok produk langsung dikurangi saat transaksi berhasil. Jika stok mencapai 0, `tersedia` otomatis diubah menjadi `false`.
  4. **Pembersihan Keranjang Otomatis:**
     Setelah pesanan berhasil dibuat, item yang dibeli otomatis dihapus dari tabel keranjang (`carts`) pelanggan.
  5. **Idempotensi:**
     Jika request dengan `idempotency_key` yang sama dikirim ulang, server mengembalikan data pesanan yang telah dibuat sebelumnya dengan **HTTP 200 OK** tanpa memotong stok kembali.
- **Respons Berhasil (201 Created):**
```json
{
  "success": true,
  "status": "sukses",
  "code": "201",
  "message": "Checkout berhasil diproses",
  "data": {
    "id": 101,
    "nama_penerima": "Budi Santoso",
    "alamat_penerima": "Jl. Agribisnis No. 12, Sleman, D.I. Yogyakarta",
    "kurir_id": 1,
    "payment_method_id": 2,
    "subtotal": 165000,
    "ongkir": 15000,
    "total_harga": 180000,
    "status": "menunggu_pembayaran",
    "tanggal_antar": "2026-11-07",
    "idempotency_key": "unique-order-uuid-001",
    "created_at": "2026-11-07T12:00:00.000000Z",
    "items": [
      {
        "id": 201,
        "order_id": 101,
        "product_id": 1,
        "quantity": 2,
        "harga_satuan": 75000,
        "subtotal": 150000
      }
    ]
  },
  "meta": null
}
```

#### 2. `GET /api/pesanan`
- **Tujuan:** Mengambil riwayat daftar seluruh pesanan beserta rincian item, kurir, dan metode pembayaran.
- **Respons (200 OK):** Daftar pesanan berurutan dari yang terbaru (`latest()`).

#### 3. `GET /api/pesanan/{id}`
- **Tujuan:** Mengambil rincian lengkap satu pesanan.
- **Respons (200 OK):** Objek pesanan lengkap beserta relasi `items.product`, `courier`, dan `paymentMethod`.

