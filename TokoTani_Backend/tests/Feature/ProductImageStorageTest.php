<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProductImageStorageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_it_can_upload_a_product_image_securely()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $file = UploadedFile::fake()->image('cabe.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/produk', [
                'nama' => 'Cabai Rawit',
                'harga' => 60000,
                'kategori' => 'Sayuran',
                'stok' => 10,
                'tersedia' => true,
                'satuan_jual' => 'kg',
                'mudah_rusak' => true,
                'gambar' => $file,
            ]);

        $response->assertStatus(201);
        
        $product = Product::first();
        $this->assertNotNull($product->gambar);
        
        // Assert file exists in storage
        Storage::disk('public')->assertExists($product->gambar);
        
        // Assert naming convention (timestamp_random.extension)
        $this->assertMatchesRegularExpression('/^products\/\d+_[\w]{10}\.jpg$/', $product->gambar);
    }

    public function test_it_deletes_old_image_when_updated_with_new_one()
    {
        $user = User::factory()->create(['role' => 'admin']);
        
        // Initial upload
        $oldFile = UploadedFile::fake()->image('old.jpg');
        $product = Product::factory()->create(['gambar' => 'products/old.jpg']);
        Storage::disk('public')->put('products/old.jpg', 'content');

        $newFile = UploadedFile::fake()->image('new.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/produk/{$product->id}", [
                '_method' => 'PUT', // For multipart/form-data support in Laravel
                'gambar' => $newFile,
            ]);

        $response->assertStatus(200);
        
        $product->refresh();
        Storage::disk('public')->assertMissing('products/old.jpg');
        Storage::disk('public')->assertExists($product->gambar);
    }

    public function test_it_deletes_image_from_storage_when_product_is_deleted()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $product = Product::factory()->create(['gambar' => 'products/to_delete.jpg']);
        Storage::disk('public')->put('products/to_delete.jpg', 'content');

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/produk/{$product->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('products', ['id' => $product->id]);
        
        // Assert file is removed from storage
        Storage::disk('public')->assertMissing('products/to_delete.jpg');
    }
}
