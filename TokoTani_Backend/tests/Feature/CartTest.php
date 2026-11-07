<?php

namespace Tests\Feature;

use App\Models\Cart;
use App\Models\Courier;
use App\Models\PaymentMethod;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CartTest extends TestCase
{
    use RefreshDatabase;

    private function createProduct(array $overrides = []): Product
    {
        return Product::create(array_merge([
            'nama'        => 'Bayam Organik',
            'harga'       => 5000,
            'kategori'    => 'Sayuran',
            'stok'        => 10,
            'tersedia'    => true,
            'deskripsi'   => 'Bayam segar langsung dari kebun.',
            'satuan_jual' => 'ikat',
            'mudah_rusak' => true,
        ], $overrides));
    }

    public function test_get_cart_empty_returns_empty_items_and_zero_subtotal(): void
    {
        $response = $this->getJson('/api/keranjang', ['X-Pelanggan-Id' => '1'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.subtotal', 0)
            ->assertJsonCount(0, 'data.items');
    }

    public function test_can_add_product_to_cart_and_calculate_authoritative_subtotal(): void
    {
        $p1 = $this->createProduct(['nama' => 'Bayam', 'harga' => 5000, 'stok' => 10]);
        $p2 = $this->createProduct(['nama' => 'Beras', 'harga' => 20000, 'stok' => 5]);

        // Tambah Bayam (2 ikat x 5.000 = 10.000)
        $this->postJson('/api/keranjang', [
            'produk_id' => $p1->id,
            'jumlah'    => 2,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('status', 'sukses');

        // Tambah Beras (1 sak x 20.000 = 20.000)
        $this->postJson('/api/keranjang', [
            'produk_id' => $p2->id,
            'jumlah'    => 1,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertCreated();

        // Cek isi keranjang dan subtotal otoritatif dari server (harus 30.000)
        $response = $this->getJson('/api/keranjang', ['X-Pelanggan-Id' => '1'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.subtotal', 30000)
            ->assertJsonCount(2, 'data.items');

        $this->assertEquals(2, $response->json('data.items.0.jumlah'));
        $this->assertEquals(5000, $response->json('data.items.0.harga'));
    }

    public function test_add_to_cart_increments_existing_quantity(): void
    {
        $product = $this->createProduct(['harga' => 10000, 'stok' => 10]);

        $this->postJson('/api/keranjang', [
            'produk_id' => $product->id,
            'jumlah'    => 2,
        ], ['X-Pelanggan-Id' => '1'])->assertCreated();

        $this->postJson('/api/keranjang', [
            'produk_id' => $product->id,
            'jumlah'    => 3,
        ], ['X-Pelanggan-Id' => '1'])->assertCreated();

        $this->assertDatabaseHas('carts', [
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 5,
        ]);
    }

    public function test_add_to_cart_rejects_exceeding_stock_with_409(): void
    {
        $product = $this->createProduct(['stok' => 3]);

        $this->postJson('/api/keranjang', [
            'produk_id' => $product->id,
            'jumlah'    => 5,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertStatus(409)
            ->assertJsonPath('success', false)
            ->assertJsonPath('status', 'gagal');
    }

    public function test_add_to_cart_rejects_out_of_stock_or_unavailable_product_with_409(): void
    {
        $product = $this->createProduct(['stok' => 0, 'tersedia' => false]);

        $this->postJson('/api/keranjang', [
            'produk_id' => $product->id,
            'jumlah'    => 1,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertStatus(409)
            ->assertJsonPath('success', false);
    }

    public function test_can_update_cart_quantity(): void
    {
        $product = $this->createProduct(['stok' => 10]);
        $cart = Cart::create([
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 2,
        ]);

        $this->putJson("/api/keranjang/{$cart->id}", [
            'jumlah' => 4,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.jumlah', 4);

        $this->assertDatabaseHas('carts', [
            'id'       => $cart->id,
            'quantity' => 4,
        ]);
    }

    public function test_update_cart_quantity_with_exceeding_stock_returns_409(): void
    {
        $product = $this->createProduct(['stok' => 5]);
        $cart = Cart::create([
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 2,
        ]);

        $this->putJson("/api/keranjang/{$cart->id}", [
            'jumlah' => 10,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertStatus(409)
            ->assertJsonPath('success', false);
    }

    public function test_update_cart_quantity_with_zero_or_negative_returns_422(): void
    {
        $product = $this->createProduct(['stok' => 5]);
        $cart = Cart::create([
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 2,
        ]);

        $this->putJson("/api/keranjang/{$cart->id}", [
            'jumlah' => 0,
        ], ['X-Pelanggan-Id' => '1'])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_can_delete_cart_item(): void
    {
        $product = $this->createProduct(['stok' => 10]);
        $cart = Cart::create([
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 2,
        ]);

        $this->deleteJson("/api/keranjang/{$cart->id}", [], ['X-Pelanggan-Id' => '1'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('carts', [
            'id' => $cart->id,
        ]);
    }

    public function test_checkout_clears_purchased_items_from_cart(): void
    {
        $product = $this->createProduct(['stok' => 10]);
        $courier = Courier::create(['nama' => 'Kurir Cepat', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'QRIS']);

        // Item masuk ke keranjang
        Cart::create([
            'customer_id' => 1,
            'product_id'  => $product->id,
            'quantity'    => 2,
        ]);

        $this->assertDatabaseHas('carts', [
            'customer_id' => 1,
            'product_id'  => $product->id,
        ]);

        // Melakukan checkout
        $this->postJson('/api/checkout', [
            'nama_penerima'     => 'Budi Santoso',
            'alamat_penerima'   => 'Jl. Agribisnis No. 12, Sleman, Yogyakarta',
            'kurir_id'          => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar'     => now()->toDateString(),
            'items'             => [
                [
                    'product_id' => $product->id,
                    'quantity'   => 2,
                ],
            ],
        ], ['X-Pelanggan-Id' => '1'])
            ->assertCreated()
            ->assertJsonPath('success', true);

        // Pastikan item yang sudah dibeli telah terhapus dari keranjang pelanggan
        $this->assertDatabaseMissing('carts', [
            'customer_id' => 1,
            'product_id'  => $product->id,
        ]);
    }
}

