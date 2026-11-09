<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\AuthenticatedApiRequests;
use Tests\TestCase;

class KeranjangTest extends TestCase
{
    use RefreshDatabase;
    use AuthenticatedApiRequests;

    public function test_adding_same_product_merges_quantity_instead_of_creating_duplicate_row(): void
    {
        $product = $this->createProduct(['harga' => 5000, 'stok' => 10]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 2])
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.produk_id', $product->id)
            ->assertJsonPath('data.jumlah', 2);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 3])
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.jumlah', 5);

        $this->assertDatabaseCount('keranjang', 1);
        $this->assertDatabaseHas('keranjang', [
            'pelanggan_id' => $this->apiUser->id,
            'product_id' => $product->id,
            'jumlah' => 5,
        ]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->getJson('/api/keranjang')
            ->assertOk()
            ->assertJsonPath('data.subtotal', 25000)
            ->assertJsonPath('data.jumlah_item', 1)
            ->assertJsonCount(1, 'data.items');
    }

    public function test_cart_rejects_quantity_above_stock_with_conflict_status(): void
    {
        $product = $this->createProduct(['stok' => 3]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 2])
            ->assertCreated();

        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 2])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal');

        $this->assertDatabaseHas('keranjang', [
            'product_id' => $product->id,
            'jumlah' => 2,
        ]);
    }

    public function test_cart_rejects_unavailable_product(): void
    {
        $product = $this->createProduct(['stok' => 0, 'tersedia' => false]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 1])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal');

        $this->assertDatabaseCount('keranjang', 0);
    }

    public function test_can_update_and_delete_cart_item(): void
    {
        $product = $this->createProduct(['harga' => 4000, 'stok' => 10]);

        $cartId = $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 1])
            ->assertCreated()
            ->json('data.id');

        $this->withHeader('X-Pelanggan-Id', '1')
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 4])
            ->assertOk()
            ->assertJsonPath('data.jumlah', 4);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 0])
            ->assertUnprocessable();

        $this->withHeader('X-Pelanggan-Id', '1')
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 11])
            ->assertStatus(409);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->deleteJson("/api/keranjang/{$cartId}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertDatabaseCount('keranjang', 0);
    }

    public function test_update_cart_item_revalidates_stock_and_availability_under_lock(): void
    {
        $product = $this->createProduct(['harga' => 4000, 'stok' => 5]);

        $cartId = $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 2])
            ->assertCreated()
            ->json('data.id');

        $product->update(['stok' => 1]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 3])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal');

        $this->assertDatabaseHas('keranjang', [
            'id' => $cartId,
            'jumlah' => 2,
        ]);

        $product->update(['tersedia' => false]);

        $this->withHeader('X-Pelanggan-Id', '1')
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 1])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal');

        $this->assertDatabaseHas('keranjang', [
            'id' => $cartId,
            'jumlah' => 2,
        ]);
    }

    public function test_cart_is_isolated_per_pelanggan(): void
    {
        $product = $this->createProduct();

        $cartId = $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => $product->id, 'jumlah' => 1])
            ->assertCreated()
            ->json('data.id');

        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $this->authenticateAs($otherCustomer);

        $this->withHeader('X-Pelanggan-Id', (string) $this->apiUser->id)
            ->getJson('/api/keranjang')
            ->assertOk()
            ->assertJsonCount(0, 'data.items');

        $this->withHeader('X-Pelanggan-Id', (string) ($this->apiUser->id + 1))
            ->putJson("/api/keranjang/{$cartId}", ['jumlah' => 2])
            ->assertNotFound();

        $this->withHeader('X-Pelanggan-Id', (string) ($this->apiUser->id + 1))
            ->deleteJson("/api/keranjang/{$cartId}")
            ->assertNotFound();
    }

    public function test_cart_rejects_unknown_product(): void
    {
        $this->withHeader('X-Pelanggan-Id', '1')
            ->postJson('/api/keranjang', ['produk_id' => 9999, 'jumlah' => 1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['produk_id']);
    }

    private function createProduct(array $overrides = []): Product
    {
        return Product::create(array_merge([
            'nama' => 'Bayam Keranjang',
            'harga' => 5000,
            'kategori' => 'Sayuran',
            'stok' => 10,
            'tersedia' => true,
            'deskripsi' => 'Produk untuk pengujian keranjang.',
            'satuan_jual' => 'ikat',
            'mudah_rusak' => true,
        ], $overrides));
    }
}
