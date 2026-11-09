<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 0. Pelanggan demo untuk mengisi foreign key keranjang/pesanan
        DB::table('users')->upsert([
            [
                'id' => 1,
                'name' => 'Pelanggan Demo 1',
                'email' => 'pelanggan1@tokotani.local',
                'password' => bcrypt('password'),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 2,
                'name' => 'Pelanggan Demo 2',
                'email' => 'pelanggan2@tokotani.local',
                'password' => bcrypt('password'),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 3,
                'name' => 'Pelanggan Demo 3',
                'email' => 'pelanggan3@tokotani.local',
                'password' => bcrypt('password'),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ], ['id'], ['name', 'email', 'password', 'updated_at']);

        // 1. Data Kategori (2 Kategori)
        DB::table('categories')->upsert([
            ['id' => 1, 'nama_kategori' => 'Sayuran dan Buah Segar', 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama_kategori' => 'Sembako dan Kebutuhan Harian', 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama_kategori', 'updated_at']);

        // 2. Data Produk (12 Produk, mencakup 2 stok nol dan atribut khas pertanian)
        DB::table('products')->upsert([
            // Kategori 1: Sayuran & Buah Segar
            [
                'id' => 1,
                'nama' => 'Bayam Hijau Segar',
                'harga' => 5000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 20,
                'tersedia' => true,
                'deskripsi' => 'Bayam hijau segar dipetik langsung dari kebun lokal.',
                'satuan_jual' => 'ikat',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 2,
                'nama' => 'Kangkung Darat',
                'harga' => 4000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 25,
                'tersedia' => true,
                'deskripsi' => 'Kangkung segar pilihan untuk ditumis.',
                'satuan_jual' => 'ikat',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 3,
                'nama' => 'Tomat Merah Organik',
                'harga' => 12000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 0, // Produk berstok nol untuk uji penolakan keranjang
                'tersedia' => false,
                'deskripsi' => 'Tomat merah segar tanpa pestisida buatan.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 4,
                'nama' => 'Cabai Rawit Merah',
                'harga' => 35000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 15,
                'tersedia' => true,
                'deskripsi' => 'Cabai rawit super pedas pilihan petani.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 5,
                'nama' => 'Kentang Dieng',
                'harga' => 18000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 30,
                'tersedia' => true,
                'deskripsi' => 'Kentang kualitas dataran tinggi Dieng.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 6,
                'nama' => 'Wortel Lokal Segar',
                'harga' => 10000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 0, // Produk berstok nol kedua
                'tersedia' => false,
                'deskripsi' => 'Wortel segar kaya vitamin A.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 7,
                'nama' => 'Bawang Merah Brebes',
                'harga' => 32000,
                'kategori' => 'Sayuran dan Buah Segar',
                'stok' => 18,
                'tersedia' => true,
                'deskripsi' => 'Bawang merah berkualitas tinggi khas Brebes.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],

            // Kategori 2: Sembako & Kebutuhan Harian
            [
                'id' => 8,
                'nama' => 'Beras Putih Premium',
                'harga' => 75000,
                'kategori' => 'Sembako dan Kebutuhan Harian',
                'stok' => 40,
                'tersedia' => true,
                'deskripsi' => 'Beras putih pulen kualitas super kemasan 5 kg.',
                'satuan_jual' => 'pak',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 9,
                'nama' => 'Minyak Goreng Sawit',
                'harga' => 18000,
                'kategori' => 'Sembako dan Kebutuhan Harian',
                'stok' => 50,
                'tersedia' => true,
                'deskripsi' => 'Minyak goreng jernih kemasan 1 liter.',
                'satuan_jual' => 'liter',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 10,
                'nama' => 'Telur Ayam Ras Segar',
                'harga' => 28000,
                'kategori' => 'Sembako dan Kebutuhan Harian',
                'stok' => 25,
                'tersedia' => true,
                'deskripsi' => 'Telur ayam negeri segar setiap hari.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => true,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 11,
                'nama' => 'Gula Pasir Putih',
                'harga' => 16000,
                'kategori' => 'Sembako dan Kebutuhan Harian',
                'stok' => 35,
                'tersedia' => true,
                'deskripsi' => 'Gula pasir manis higienis.',
                'satuan_jual' => 'kg',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 12,
                'nama' => 'Tepung Terigu Serbaguna',
                'harga' => 12000,
                'kategori' => 'Sembako dan Kebutuhan Harian',
                'stok' => 20,
                'tersedia' => true,
                'deskripsi' => 'Tepung terigu kualitas bagus untuk aneka masakan.',
                'satuan_jual' => 'pak',
                'mudah_rusak' => false,
                'created_at' => now(), 'updated_at' => now(),
            ],
        ], ['id'], [
            'nama',
            'harga',
            'kategori',
            'stok',
            'tersedia',
            'deskripsi',
            'satuan_jual',
            'mudah_rusak',
            'updated_at',
        ]);

        DB::table('couriers')->upsert([
            ['id' => 1, 'nama' => 'Kurir Toko Area Dekat', 'wilayah' => 'Dalam Kota (0-5 km)', 'tarif' => 10000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Kurir Toko Area Sedang', 'wilayah' => 'Kecamatan Sekitar (5-15 km)', 'tarif' => 20000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'nama' => 'Kurir Toko Area Jauh', 'wilayah' => 'Luar Kota (>15 km)', 'tarif' => 35000, 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'wilayah', 'tarif', 'aktif', 'updated_at']);

        DB::table('payment_methods')->upsert([
            ['id' => 1, 'nama' => 'Transfer Bank', 'deskripsi' => 'Simulasi pembayaran melalui transfer bank.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'nama' => 'Bayar di Tempat', 'deskripsi' => 'Simulasi pembayaran saat pesanan diterima.', 'aktif' => true, 'created_at' => now(), 'updated_at' => now()],
        ], ['id'], ['nama', 'deskripsi', 'aktif', 'updated_at']);

        DB::table('orders')->upsert([
            [
                'pelanggan_id' => 1,
                'nama_penerima' => 'Contoh Penerima',
                'alamat_penerima' => 'Jl. Tani No. 1',
                'kurir_id' => 1,
                'payment_method_id' => 1,
                'subtotal' => 75000,
                'ongkir' => 10000,
                'total_harga' => 85000,
                'status' => 'menunggu_pembayaran',
                'tanggal_antar' => now()->toDateString(),
                'tanggal_pengantaran' => now()->toDateString(),
                'slot_pengantaran' => 'pagi',
                'idempotency_key' => 'contoh-pesanan-seeder',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ], ['idempotency_key'], [
            'pelanggan_id',
            'nama_penerima',
            'alamat_penerima',
            'kurir_id',
            'payment_method_id',
            'subtotal',
            'ongkir',
            'total_harga',
            'status',
            'tanggal_antar',
            'tanggal_pengantaran',
            'slot_pengantaran',
            'updated_at',
        ]);

        $sampleOrderId = DB::table('orders')
            ->where('idempotency_key', 'contoh-pesanan-seeder')
            ->value('id');

        DB::table('order_items')->upsert([
            [
                'order_id' => $sampleOrderId,
                'product_id' => 8,
                'nama_produk' => 'Beras Putih Premium',
                'quantity' => 1,
                'harga_satuan' => 75000,
                'subtotal' => 75000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ], ['order_id', 'product_id'], [
            'nama_produk',
            'quantity',
            'harga_satuan',
            'subtotal',
            'updated_at',
        ]);
    }
}
