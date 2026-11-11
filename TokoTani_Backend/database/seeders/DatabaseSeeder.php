<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->isProduction()) {
            User::firstOrCreate(
                ['email' => 'admin@tokotani.test'],
                [
                    'name' => 'Admin TaniMart',
                    'password' => 'password',
                    'role' => 'admin',
                ],
            );

            User::firstOrCreate(
                ['email' => 'user@tokotani.test'],
                [
                    'name' => 'Pelanggan TaniMart',
                    'password' => 'password',
                    'role' => 'customer',
                ],
            );
        }

        $categories = [
            ['nama_kategori' => 'Sayuran Segar', 'gambar' => 'categories/sayuranSegar/sayuran.jpg'],
            ['nama_kategori' => 'Buah Segar', 'gambar' => 'categories/kebutuhanDapur/buah.jpeg'],
            ['nama_kategori' => 'Umbi', 'gambar' => 'categories/sayuranSegar/kentang.jpeg'],
            ['nama_kategori' => 'Bumbu Dapur', 'gambar' => 'categories/kebutuhanDapur/cabai_rawit.jpg'],
            ['nama_kategori' => 'Biji-Bijian', 'gambar' => 'categories/kebutuhanDapur/beras.jpeg'],
            ['nama_kategori' => 'Hasil Tani Lainnya', 'gambar' => 'categories/kebutuhanTani/pupuk.jpeg'],
        ];

        DB::table('categories')->upsert(
            array_map(fn (array $category) => [...$category, 'created_at' => now(), 'updated_at' => now()], $categories),
            ['nama_kategori'],
            ['gambar', 'updated_at'],
        );

        $categoryIds = DB::table('categories')
            ->whereIn('nama_kategori', array_column($categories, 'nama_kategori'))
            ->pluck('id', 'nama_kategori');

        DB::table('banners')->upsert([
            [
                'id' => 1,
                'judul' => 'Belanja Hasil Pertanian',
                'gambar' => 'banners/NpEye2Lzn1xZUkFiGYZ3vomb3syYaMDu6g6SSFmq.png',
                'urutan' => 1,
                'aktif' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ], ['id'], ['judul', 'gambar', 'urutan', 'aktif', 'updated_at']);

        DB::table('couriers')->upsert([
            ['id' => 1, 'nama' => 'Kurir Toko Area Dekat', 'tarif' => 10000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Kurir Toko Area Jauh', 'tarif' => 20000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'nama' => 'Kurir Toko Area Sedang', 'tarif' => 15000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'tarif', 'aktif', 'updated_at']);

        DB::table('payment_methods')->upsert([
            ['id' => 1, 'nama' => 'Transfer Bank', 'deskripsi' => 'Simulasi pembayaran melalui transfer bank.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Bayar di Tempat', 'deskripsi' => 'Simulasi pembayaran saat pesanan diterima.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'deskripsi', 'aktif', 'updated_at']);

        $products = [
            ['nama' => 'Bayam Hijau', 'harga' => 5000, 'kategori' => 'Sayuran Segar', 'stok' => 40, 'satuan_jual' => 'ikat', 'mudah_rusak' => true, 'deskripsi' => 'Bayam hijau segar, cocok untuk sayur bening.'],
            ['nama' => 'Kangkung', 'harga' => 4000, 'kategori' => 'Sayuran Segar', 'stok' => 35, 'satuan_jual' => 'ikat', 'mudah_rusak' => true, 'deskripsi' => 'Kangkung segar untuk tumisan dan sayur berkuah.'],
            ['nama' => 'Wortel', 'harga' => 12000, 'kategori' => 'Sayuran Segar', 'stok' => 25, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Wortel segar dengan rasa manis alami.', 'gambar' => 'products/jQS0GGgcWELLwmkCU2wfLZVziB5TTclNK4uZVqhw.jpg'],
            ['nama' => 'Tomat Merah', 'harga' => 10000, 'kategori' => 'Sayuran Segar', 'stok' => 30, 'satuan_jual' => 'kg', 'mudah_rusak' => true, 'deskripsi' => 'Tomat merah matang untuk masakan dan sambal.'],
            ['nama' => 'Pisang Ambon', 'harga' => 18000, 'kategori' => 'Buah Segar', 'stok' => 20, 'satuan_jual' => 'sisir', 'mudah_rusak' => true, 'deskripsi' => 'Pisang Ambon matang dengan rasa manis.'],
            ['nama' => 'Jeruk Manis', 'harga' => 16000, 'kategori' => 'Buah Segar', 'stok' => 30, 'satuan_jual' => 'kg', 'mudah_rusak' => true, 'deskripsi' => 'Jeruk manis segar dan kaya vitamin C.'],
            ['nama' => 'Mangga Harum Manis', 'harga' => 22000, 'kategori' => 'Buah Segar', 'stok' => 18, 'satuan_jual' => 'kg', 'mudah_rusak' => true, 'deskripsi' => 'Mangga harum manis dengan daging buah lembut.'],
            ['nama' => 'Kentang Dieng', 'harga' => 17000, 'kategori' => 'Umbi', 'stok' => 28, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Kentang pilihan untuk aneka hidangan.'],
            ['nama' => 'Singkong', 'harga' => 8000, 'kategori' => 'Umbi', 'stok' => 25, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Singkong segar untuk direbus atau diolah.'],
            ['nama' => 'Cabai Rawit Merah', 'harga' => 45000, 'kategori' => 'Bumbu Dapur', 'stok' => 15, 'satuan_jual' => 'kg', 'mudah_rusak' => true, 'deskripsi' => 'Cabai rawit merah segar dengan rasa pedas.', 'gambar' => 'products/LjqymlDRlhrzxAxKha3FoaEOYfvCABS3rKC345DI.jpg'],
            ['nama' => 'Bawang Merah', 'harga' => 32000, 'kategori' => 'Bumbu Dapur', 'stok' => 22, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Bawang merah pilihan untuk bumbu masakan.'],
            ['nama' => 'Bawang Putih', 'harga' => 30000, 'kategori' => 'Bumbu Dapur', 'stok' => 24, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Bawang putih kering untuk kebutuhan dapur.'],
            ['nama' => 'Beras Pandan Wangi', 'harga' => 68000, 'kategori' => 'Biji-Bijian', 'stok' => 40, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Beras pandan wangi pulen dengan aroma harum.'],
            ['nama' => 'Jagung Pipil', 'harga' => 14000, 'kategori' => 'Biji-Bijian', 'stok' => 30, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Jagung pipil kering untuk bahan pangan dan pakan.'],
            ['nama' => 'Pupuk Kompos Organik', 'harga' => 15000, 'kategori' => 'Hasil Tani Lainnya', 'stok' => 50, 'satuan_jual' => 'kg', 'mudah_rusak' => false, 'deskripsi' => 'Pupuk kompos organik untuk membantu menyuburkan tanah.'],
        ];

        foreach ($products as $product) {
            Product::updateOrCreate(
                ['nama' => $product['nama']],
                [...$product, 'category_id' => $categoryIds[$product['kategori']], 'tersedia' => true],
            );
        }
    }
}
