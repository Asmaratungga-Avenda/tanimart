<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\PaymentMethod;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\AuthenticatedApiRequests;
use Tests\TestCase;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;
    use AuthenticatedApiRequests;

    public function test_checkout_calculates_total_and_decrements_stock(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $response = $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ), ['X-Kunci-Idempoten' => 'checkout-test-001']);

        $response
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '201')
            ->assertJsonPath('data.subtotal', 10000)
            ->assertJsonPath('data.ongkir', 10000)
            ->assertJsonPath('data.total_harga', 20000)
            ->assertJsonPath('data.items.0.quantity', 2);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
        $this->assertDatabaseHas('order_items', [
            'product_id' => $product->id,
            'quantity' => 2,
            'harga_satuan' => 5000,
            'subtotal' => 10000,
        ]);
    }

    public function test_idempotency_key_prevents_duplicate_orders_and_stock_changes(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);
        $payload = $this->checkoutPayload($product, $courier, $paymentMethod, now()->toDateString());

        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'checkout-test-002'])
            ->assertCreated();
        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'checkout-test-002'])
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
    }

    public function test_checkout_accepts_idempotency_key_in_request_body(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $payload = array_merge(
            $this->checkoutPayload($product, $courier, $paymentMethod, now()->toDateString()),
            ['idempotency_key' => 'body-idempoten-001']
        );

        $this->postJson('/api/checkout', $payload)->assertCreated();
        $this->postJson('/api/checkout', $payload)->assertOk()->assertJsonPath('status', 'sukses');

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
    }

    public function test_perishable_product_rejects_delivery_on_another_day(): void
    {
        $product = $this->createProduct(['mudah_rusak' => true]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->addDay()->toDateString()
        ))
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 10,
        ]);
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_non_perishable_product_allows_delivery_on_future_day(): void
    {
        $product = $this->createProduct(['mudah_rusak' => false]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->addDay()->toDateString()
        ))
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '201');

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
        $this->assertDatabaseCount('orders', 1);
    }

    public function test_checkout_rejects_quantity_above_stock(): void
    {
        $product = $this->createProduct(['stok' => 1]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ))
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 1,
        ]);
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_rejects_out_of_stock_or_unavailable_product(): void
    {
        $productHabis = $this->createProduct(['stok' => 0, 'tersedia' => false]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $productHabis,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ))
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409');

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_rejects_inactive_courier_or_payment_method(): void
    {
        $product = $this->createProduct();
        $inactiveCourier = Courier::create(['nama' => 'Kurir Nonaktif', 'tarif' => 10000, 'aktif' => false]);
        $activeCourier = Courier::create(['nama' => 'Kurir Aktif', 'tarif' => 10000, 'aktif' => true]);
        $inactivePayment = PaymentMethod::create(['nama' => 'Nonaktif', 'aktif' => false]);
        $activePayment = PaymentMethod::create(['nama' => 'Aktif', 'aktif' => true]);

        // Inactive Courier
        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $inactiveCourier,
            $activePayment,
            now()->toDateString()
        ))->assertUnprocessable();

        // Inactive Payment Method
        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $activeCourier,
            $inactivePayment,
            now()->toDateString()
        ))->assertUnprocessable();
    }

    public function test_checkout_rejects_duplicate_products_in_payload(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $payload = [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
                ['product_id' => $product->id, 'quantity' => 2],
            ],
        ];

        $this->postJson('/api/checkout', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items.0.product_id', 'items.1.product_id']);
    }

    public function test_can_fetch_active_couriers_and_payment_methods(): void
    {
        Courier::create(['nama' => 'Kurir 1', 'tarif' => 10000, 'aktif' => true]);
        Courier::create(['nama' => 'Kurir 2', 'tarif' => 20000, 'aktif' => false]);

        PaymentMethod::create(['nama' => 'Metode 1', 'aktif' => true]);
        PaymentMethod::create(['nama' => 'Metode 2', 'aktif' => false]);

        $resKurir = $this->getJson('/api/kurir')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');
        $this->assertCount(1, $resKurir->json('data'));

        $resBayar = $this->getJson('/api/metode-pembayaran')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');
        $this->assertCount(1, $resBayar->json('data'));
    }

    public function test_can_fetch_order_detail_and_list(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $resCheckout = $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ))->assertCreated();

        $orderId = $resCheckout->json('data.id');

        $this->getJson("/api/checkout/{$orderId}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.id', $orderId)
            ->assertJsonPath('data.items.0.product.id', $product->id);

        $this->getJson('/api/pesanan')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');
    }

    public function test_database_seeder_does_not_create_dummy_customers_products_or_orders(): void
    {
        $this->apiUser->delete();
        $this->seed();
        $this->seed();

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('categories', 6);
        $this->assertDatabaseCount('products', 0);
        $this->assertDatabaseCount('couriers', 2);
        $this->assertDatabaseCount('payment_methods', 2);
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
    }

    private function createProduct(array $overrides = []): Product
    {
        return Product::create(array_merge([
            'nama' => 'Bayam Tes',
            'harga' => 5000,
            'kategori' => 'Sayuran',
            'stok' => 10,
            'tersedia' => true,
            'deskripsi' => 'Produk untuk pengujian.',
            'satuan_jual' => 'ikat',
            'mudah_rusak' => true,
        ], $overrides));
    }

    private function checkoutPayload(
        Product $product,
        Courier $courier,
        PaymentMethod $paymentMethod,
        string $deliveryDate
    ): array {
        return [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => $deliveryDate,
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => 2,
                ],
            ],
        ];
    }
}
