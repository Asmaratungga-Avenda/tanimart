<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('categories')->upsert([
            ['id' => 1, 'nama_kategori' => 'Sayuran Segar', 'gambar' => 'categories/sayuran.jpg', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama_kategori' => 'Buah Segar', 'gambar' => 'categories/buah.jpg', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'nama_kategori' => 'Umbi', 'gambar' => 'categories/kentang.jpg', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 4, 'nama_kategori' => 'Bumbu Dapur', 'gambar' => 'categories/cabai_rawit.jpg', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 5, 'nama_kategori' => 'Biji-Bijian', 'gambar' => 'categories/beras.jpg', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 6, 'nama_kategori' => 'Hasil Tani Lainnya', 'gambar' => 'categories/pupuk.jpg', 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama_kategori', 'gambar', 'updated_at']);

        DB::table('couriers')->upsert([
            ['id' => 1, 'nama' => 'Kurir Toko Area Dekat', 'tarif' => 10000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Kurir Toko Area Jauh', 'tarif' => 20000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'tarif', 'aktif', 'updated_at']);

        DB::table('payment_methods')->upsert([
            ['id' => 1, 'nama' => 'Transfer Bank', 'deskripsi' => 'Simulasi pembayaran melalui transfer bank.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Bayar di Tempat', 'deskripsi' => 'Simulasi pembayaran saat pesanan diterima.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'deskripsi', 'aktif', 'updated_at']);
    }
}
