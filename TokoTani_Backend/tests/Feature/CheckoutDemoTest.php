<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CheckoutFixtures;
use Tests\TestCase;

class CheckoutDemoTest extends TestCase
{
    use CheckoutFixtures;
    use RefreshDatabase;

    public function test_demo_checkout_berhasil(): void
    {
        $product = $this->createProduct([
            'nama' => 'Bayam Demo',
            'harga' => 5000,
            'stok' => 10,
            'mudah_rusak' => true,
        ]);
        $courier = $this->createCourier(['tarif' => 10000]);
        $paymentMethod = $this->createPaymentMethod();

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            2
        ), ['X-Kunci-Idempoten' => 'demo-sukses'])
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '201')
            ->assertJsonPath('data.subtotal', 10000)
            ->assertJsonPath('data.ongkir', 10000)
            ->assertJsonPath('data.total_harga', 20000)
            ->assertJsonPath('data.items.0.nama_produk', 'Bayam Demo')
            ->assertJsonPath('data.items.0.harga_satuan', 5000)
            ->assertJsonPath('data.items.0.subtotal', 10000);

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 8]);
    }

    public function test_demo_checkout_ditolak_karena_kuantitas(): void
    {
        $product = $this->createProduct([
            'nama' => 'Bayam Demo',
            'harga' => 5000,
            'stok' => 10,
            'mudah_rusak' => true,
        ]);
        $courier = $this->createCourier(['tarif' => 10000]);
        $paymentMethod = $this->createPaymentMethod();

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            6
        ), ['X-Kunci-Idempoten' => 'demo-kuantitas'])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422')
            ->assertJsonPath('errors.checkout.0', "Kuantitas maksimal 5 untuk produk 'Bayam Demo'");

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 10]);
    }

    public function test_demo_checkout_ditolak_karena_tanggal(): void
    {
        $product = $this->createProduct([
            'nama' => 'Bayam Demo',
            'harga' => 5000,
            'stok' => 10,
            'mudah_rusak' => true,
        ]);
        $courier = $this->createCourier(['tarif' => 10000]);
        $paymentMethod = $this->createPaymentMethod();

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->addDay()->toDateString(),
            2
        ), ['X-Kunci-Idempoten' => 'demo-tanggal'])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422')
            ->assertJsonPath('errors.checkout.0', "Produk 'Bayam Demo' wajib dikirim pada hari yang sama");

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 10]);
    }

    public function test_demo_stok_kurang_menghasilkan_conflict(): void
    {
        $product = $this->createProduct(['stok' => 1]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            2
        ), ['X-Kunci-Idempoten' => 'demo-stok-kurang'])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409')
            ->assertJsonPath('message', "Stok untuk produk '{$product->nama}' tidak mencukupi");

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 1]);
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_demo_checkout_gagal_di_rollback_seluruh_item(): void
    {
        $firstProduct = $this->createProduct(['nama' => 'Produk Rollback Pertama', 'stok' => 10]);
        $outOfStockProduct = $this->createProduct([
            'nama' => 'Produk Rollback Habis',
            'stok' => 0,
            'tersedia' => false,
        ]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $payload = $this->checkoutPayload(
            $firstProduct,
            $courier,
            $paymentMethod,
            now()->toDateString()
        );
        $payload['items'][] = [
            'product_id' => $outOfStockProduct->id,
            'quantity' => 1,
        ];

        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'demo-rollback'])
            ->assertStatus(409)
            ->assertJsonPath('code', '409');

        $this->assertDatabaseHas('products', ['id' => $firstProduct->id, 'stok' => 10]);
        $this->assertDatabaseHas('products', ['id' => $outOfStockProduct->id, 'stok' => 0]);
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
    }

    public function test_demo_retry_tidak_membuat_pesanan_ganda(): void
    {
        $product = $this->createProduct([
            'nama' => 'Bayam Demo',
            'harga' => 5000,
            'stok' => 10,
            'mudah_rusak' => true,
        ]);
        $courier = $this->createCourier(['tarif' => 10000]);
        $paymentMethod = $this->createPaymentMethod();
        $payload = $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            2
        );

        $orderId = $this->postJson('/api/checkout', $payload, [
            'X-Kunci-Idempoten' => 'demo-retry',
        ])
            ->assertCreated()
            ->assertJsonPath('code', '201')
            ->json('data.id');

        $this->postJson('/api/checkout', $payload, [
            'X-Kunci-Idempoten' => 'demo-retry',
        ])
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '200')
            ->assertJsonPath('data.id', $orderId);

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 8]);
    }
}
