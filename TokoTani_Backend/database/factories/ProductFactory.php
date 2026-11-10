<?php

namespace Database\Factories;

use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProductFactory extends Factory
{
    protected $model = Product::class;

    public function definition(): array
    {
        return [
            'nama' => $this->faker->words(2, true),
            'harga' => $this->faker->numberBetween(1000, 100000),
            'kategori' => 'Sayuran',
            'stok' => $this->faker->numberBetween(0, 100),
            'tersedia' => true,
            'satuan_jual' => 'kg',
            'mudah_rusak' => $this->faker->boolean(),
            'deskripsi' => $this->faker->sentence(),
            'gambar' => null,
        ];
    }
}
