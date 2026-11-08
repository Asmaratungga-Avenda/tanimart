<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Keranjang;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CheckoutTest extends TestCase
{
    use RefreshDatabase;

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
            'nama_produk' => 'Bayam Tes',
            'quantity' => 2,
            'harga_satuan' => 5000,
            'subtotal' => 10000,
        ]);
    }

    public function test_checkout_requires_idempotency_key(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['idempotency_key']);

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 10]);
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
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '200');

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
    }

    public function test_same_idempotency_key_with_different_payload_is_rejected(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            2
        ), ['X-Kunci-Idempoten' => 'checkout-test-payload'])->assertCreated();

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            3
        ), ['X-Kunci-Idempoten' => 'checkout-test-payload'])
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409');

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 8]);
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

    public function test_checkout_accepts_wilayah_and_date_aliases(): void
    {
        $product = $this->createProduct(['mudah_rusak' => false]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $payload = [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'wilayah_id' => $courier->id,
            'metode_pembayaran_id' => $paymentMethod->id,
            'tanggal_pengantaran' => now()->addDay()->toDateString(),
            'slot' => 'Pagi',
            'items' => [
                ['produk_id' => $product->id, 'jumlah' => 2],
            ],
        ];

        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'alias-checkout-001'])
            ->assertCreated()
            ->assertJsonPath('data.slot_pengantaran', 'pagi')
            ->assertJsonPath('data.tanggal_pengantaran', now()->addDay()->toDateString());
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
        ), ['X-Kunci-Idempoten' => 'perishable-future-day'])
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
        ), ['X-Kunci-Idempoten' => 'non-perishable-future-day'])
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('code', '201');

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 8,
        ]);
        $this->assertDatabaseCount('orders', 1);
    }

    public function test_checkout_rejects_delivery_date_in_the_past(): void
    {
        $product = $this->createProduct(['mudah_rusak' => false]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->subDay()->toDateString()
        ), ['X-Kunci-Idempoten' => 'past-date-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['tanggal_antar']);

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 10]);
    }

    public function test_checkout_rejects_invalid_slot(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            2,
            'malam'
        ), ['X-Kunci-Idempoten' => 'invalid-slot-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['slot_pengantaran']);

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_perishable_quantity_above_limit_is_rejected(): void
    {
        config(['checkout.max_mudah_rusak_per_pesanan' => 5]);

        $product = $this->createProduct(['mudah_rusak' => true, 'stok' => 10]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            6
        ), ['X-Kunci-Idempoten' => 'perishable-over-limit'])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 10]);
    }

    public function test_perishable_quantity_at_limit_is_accepted(): void
    {
        config(['checkout.max_mudah_rusak_per_pesanan' => 5]);

        $product = $this->createProduct(['mudah_rusak' => true, 'stok' => 10]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString(),
            5
        ), ['X-Kunci-Idempoten' => 'perishable-at-limit'])
            ->assertCreated();

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 5]);
    }

    public function test_duplicate_item_lines_are_rejected(): void
    {
        $product = $this->createProduct(['mudah_rusak' => true, 'stok' => 20]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
            'items' => [
                ['product_id' => $product->id, 'quantity' => 4],
                ['product_id' => $product->id, 'quantity' => 4],
            ],
        ], ['X-Kunci-Idempoten' => 'duplicate-item-lines'])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422')
            ->assertJsonValidationErrors(['items.1.product_id']);

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 20]);
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
        ), ['X-Kunci-Idempoten' => 'above-stock-checkout'])
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
        ), ['X-Kunci-Idempoten' => 'out-of-stock-checkout'])
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
        ), ['X-Kunci-Idempoten' => 'inactive-courier-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['kurir_id']);

        // Inactive Payment Method
        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $activeCourier,
            $inactivePayment,
            now()->toDateString()
        ), ['X-Kunci-Idempoten' => 'inactive-payment-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['payment_method_id']);

        $this->assertDatabaseCount('orders', 0);
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
            'slot_pengantaran' => 'pagi',
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
                ['product_id' => $product->id, 'quantity' => 2],
            ],
        ];

        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'duplicate-product-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items.0.product_id', 'items.1.product_id']);
    }

    public function test_checkout_requires_items_when_cart_is_empty(): void
    {
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $this->postJson('/api/checkout', [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
        ], ['X-Kunci-Idempoten' => 'empty-cart-checkout'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_checkout_uses_cart_when_items_are_not_sent_and_clears_checked_out_items(): void
    {
        $product = $this->createProduct(['mudah_rusak' => false]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);
        $pelanggan = User::create([
            'name' => 'Pelanggan Keranjang',
            'email' => 'pelanggan-keranjang@tokotani.local',
            'password' => 'password',
        ]);
        $pelangganId = $pelanggan->id;

        Keranjang::create([
            'pelanggan_id' => $pelangganId,
            'product_id' => $product->id,
            'jumlah' => 2,
        ]);

        $this->postJson('/api/checkout', [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
        ], [
            'X-Kunci-Idempoten' => 'cart-checkout-001',
            'X-Pelanggan-Id' => (string) $pelangganId,
        ])
            ->assertCreated()
            ->assertJsonPath('data.pelanggan_id', $pelangganId)
            ->assertJsonPath('data.items.0.quantity', 2);

        $this->assertDatabaseMissing('keranjang', [
            'pelanggan_id' => $pelangganId,
            'product_id' => $product->id,
        ]);
        $this->assertDatabaseHas('orders', ['pelanggan_id' => $pelangganId]);
    }

    public function test_server_ignores_client_supplied_totals(): void
    {
        $product = $this->createProduct();
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $payload = array_merge(
            $this->checkoutPayload($product, $courier, $paymentMethod, now()->toDateString()),
            [
                'subtotal' => 1,
                'ongkir' => 1,
                'total_harga' => 1,
                'total' => 1,
            ]
        );

        $this->postJson('/api/checkout', $payload, ['X-Kunci-Idempoten' => 'server-totals-checkout'])
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 10000)
            ->assertJsonPath('data.ongkir', 10000)
            ->assertJsonPath('data.total_harga', 20000);
    }

    public function test_checkout_rolls_back_all_changes_when_later_item_fails(): void
    {
        $firstProduct = $this->createProduct([
            'nama' => 'Produk Pertama',
            'stok' => 10,
            'mudah_rusak' => false,
        ]);
        $secondProduct = $this->createProduct([
            'nama' => 'Produk Kedua',
            'stok' => 1,
            'mudah_rusak' => false,
        ]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);
        $pelanggan = User::create([
            'name' => 'Pelanggan Rollback',
            'email' => 'pelanggan-rollback@tokotani.local',
            'password' => 'password',
        ]);
        $pelangganId = $pelanggan->id;

        Keranjang::create([
            'pelanggan_id' => $pelangganId,
            'product_id' => $firstProduct->id,
            'jumlah' => 2,
        ]);

        $payload = [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
            'items' => [
                ['product_id' => $firstProduct->id, 'quantity' => 2],
                ['product_id' => $secondProduct->id, 'quantity' => 2],
            ],
        ];

        $this->postJson('/api/checkout', $payload, [
            'X-Kunci-Idempoten' => 'rollback-checkout-001',
            'X-Pelanggan-Id' => (string) $pelangganId,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseHas('products', ['id' => $firstProduct->id, 'stok' => 10]);
        $this->assertDatabaseHas('products', ['id' => $secondProduct->id, 'stok' => 1]);
        $this->assertDatabaseHas('keranjang', [
            'pelanggan_id' => $pelangganId,
            'product_id' => $firstProduct->id,
            'jumlah' => 2,
        ]);
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
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
        ), ['X-Kunci-Idempoten' => 'order-detail-checkout'])->assertCreated();

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

    public function test_database_seeder_creates_checkout_data_and_is_repeatable(): void
    {
        $this->seed();
        $this->seed();

        $this->assertDatabaseCount('categories', 2);
        $this->assertDatabaseCount('products', 12);
        $this->assertDatabaseCount('couriers', 3);
        $this->assertDatabaseCount('payment_methods', 2);
        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
    }

    public function test_order_detail_keeps_product_snapshot_after_catalog_changes(): void
    {
        $product = $this->createProduct(['nama' => 'Bayam Snapshot', 'harga' => 5000]);
        $courier = Courier::create(['nama' => 'Kurir Tes', 'tarif' => 10000]);
        $paymentMethod = PaymentMethod::create(['nama' => 'Transfer Tes']);

        $orderId = $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            now()->toDateString()
        ), ['X-Kunci-Idempoten' => 'snapshot-checkout'])->assertCreated()->json('data.id');

        $product->update(['nama' => 'Bayam Nama Baru', 'harga' => 9000]);

        $this->getJson("/api/pesanan/{$orderId}")
            ->assertOk()
            ->assertJsonPath('data.items.0.nama_produk', 'Bayam Snapshot')
            ->assertJsonPath('data.items.0.harga_satuan', 5000)
            ->assertJsonPath('data.items.0.subtotal', 10000);

        $this->assertDatabaseHas('order_items', [
            'order_id' => $orderId,
            'nama_produk' => 'Bayam Snapshot',
            'harga_satuan' => 5000,
        ]);
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
        string $deliveryDate,
        int $quantity = 2,
        string $slot = 'pagi'
    ): array {
        return [
            'nama_penerima' => 'Penerima Tes',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => $deliveryDate,
            'slot_pengantaran' => $slot,
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                ],
            ],
        ];
    }
}
