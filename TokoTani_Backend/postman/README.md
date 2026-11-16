# Pengujian API TaniMart dengan Postman

## Import

Import `TaniMart.postman_collection.json` ke Postman. URL lokal sudah diisi dengan `http://127.0.0.1:8000/api`; ubah variabel koleksi `baseUrl` hanya jika server berjalan di alamat lain.

## Menjalankan

Di terminal backend, siapkan database dan akun demo lokal:

```powershell
php artisan migrate --seed
php artisan serve
```

Jalankan request secara berurutan dari folder `00` sampai `04`. Skrip Postman akan menyimpan token autentikasi dan ID produk, kurir, metode pembayaran, item keranjang, serta pesanan. Untuk menguji seluruh alur pesanan, jalankan request checkout, konfirmasi pembayaran, login admin, verifikasi pembayaran, proses pesanan, kirim pesanan, lalu penyelesaian oleh pelanggan. Request yang membutuhkan status pesanan sebelumnya akan mengembalikan konflik (`409`) jika dijalankan di luar urutan tersebut.

Akun admin contoh (`admin@tokotani.test` / `password`) hanya tersedia dari seeder pada lingkungan non-production. Jangan gunakan kredensial demo ini di production. Request daftar produk admin membuat produk uji; request setelahnya memperbarui dan menghapus produk uji tersebut.

## Ringkasan endpoint

- **Publik:** `GET /produk`, `GET /produk/{id}`, `GET /kategori`, `GET /banners`, `GET /kurir`, `GET /metode-pembayaran`, `GET /wilayah`.
- **Autentikasi:** `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `POST /auth/logout`.
- **Pelanggan:** operasi keranjang `GET/POST /keranjang`, `PUT/DELETE /keranjang/{id}`, `DELETE /keranjang`; checkout `POST /checkout`; pesanan `GET /pesanan`, `GET /pesanan/{id}`, `POST /pesanan/{id}/pembayaran`, `POST /pesanan/{id}/selesai`.
- **Admin:** `POST/PUT/DELETE /produk`, `PATCH /pesanan/{id}/status`, dan `POST /pesanan/{id}/kirim`.

Alias route yang juga tersedia: `GET /banner`, `GET /categories`, `GET /couriers`, `GET /payment-methods`; prefix `/cart` untuk operasi keranjang; `GET /orders` dan `GET /orders/{id}` untuk pesanan; serta `PATCH /checkout/{id}/status` dan `PATCH /orders/{id}/status` untuk admin. Penghapusan kurir/wilayah tersedia melalui `DELETE /kurir/{id}`, `/couriers/{id}`, atau `/wilayah/{id}`; endpoint penghapusan ini tidak dijalankan otomatis karena mengubah data seed.

Request checkout mengirim `nama_penerima`, `alamat_penerima`, `kurir_id`, `payment_method_id`, `tanggal_antar` (`YYYY-MM-DD`), dan `items` berisi `product_id` serta `quantity`. Header `X-Idempotency-Key` diisi otomatis.
