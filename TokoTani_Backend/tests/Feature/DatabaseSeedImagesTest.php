<?php

namespace Tests\Feature;

use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DatabaseSeedImagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeded_image_references_exist_in_the_public_storage_disk(): void
    {
        $this->seed(DatabaseSeeder::class);

        $images = [
            'categories' => [
                ['nama_kategori' => 'Sayuran Segar', 'gambar' => 'categories/sayuranSegar/sayuran.jpg'],
                ['nama_kategori' => 'Buah Segar', 'gambar' => 'categories/kebutuhanDapur/buah.jpeg'],
                ['nama_kategori' => 'Umbi', 'gambar' => 'categories/sayuranSegar/kentang.jpeg'],
                ['nama_kategori' => 'Bumbu Dapur', 'gambar' => 'categories/kebutuhanDapur/cabai_rawit.jpg'],
                ['nama_kategori' => 'Biji-Bijian', 'gambar' => 'categories/kebutuhanDapur/beras.jpeg'],
                ['nama_kategori' => 'Hasil Tani Lainnya', 'gambar' => 'categories/kebutuhanTani/pupuk.jpeg'],
            ],
            'products' => [
                ['nama' => 'Wortel', 'gambar' => 'products/jQS0GGgcWELLwmkCU2wfLZVziB5TTclNK4uZVqhw.jpg'],
                ['nama' => 'Cabai Rawit Merah', 'gambar' => 'products/LjqymlDRlhrzxAxKha3FoaEOYfvCABS3rKC345DI.jpg'],
            ],
            'banners' => [
                ['judul' => 'Belanja Hasil Pertanian', 'gambar' => 'banners/NpEye2Lzn1xZUkFiGYZ3vomb3syYaMDu6g6SSFmq.png'],
            ],
        ];

        foreach ($images as $table => $records) {
            foreach ($records as $record) {
                $this->assertDatabaseHas($table, $record);
                $this->assertTrue(
                    Storage::disk('public')->exists($record['gambar']),
                    "Missing seeded image: {$record['gambar']}",
                );
                $this->get('/storage/'.$record['gambar'])->assertOk();
            }
        }
    }
}
