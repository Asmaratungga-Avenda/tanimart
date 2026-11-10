<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\Support\CheckoutFixtures;
use Tests\TestCase;

class PesananAcceptanceTest extends TestCase
{
    use CheckoutFixtures;
    use RefreshDatabase;

    public function test_kurir_wilayah_endpoint_returns_active_tariffs(): void
    {
        $this->createCourier(['nama' => 'Kurir Dekat', 'wilayah' => '0-5 km', 'tarif' => 10000]);
        $this->createCourier(['nama' => 'Kurir Sedang', 'wilayah' => '5-15 km', 'tarif' => 20000]);
        $this->createCourier(['nama' => 'Kurir Jauh', 'wilayah' => '>15 km', 'tarif' => 35000]);
        $nonaktif = $this->createCourier([
            'nama' => 'Kurir Nonaktif',
            'wilayah' => '>15 km',
            'tarif' => 40000,
            'aktif' => false,
        ]);

        foreach (['/api/kurir', '/api/couriers'] as $uri) {
            $response = $this->getJson($uri)
                ->assertOk()
                ->assertJsonPath('status', 'sukses');

            $data = collect($response->json('data'));

            $this->assertSame([10000, 20000, 35000], $data->pluck('tarif')->all());
            $this->assertSame(['0-5 km', '5-15 km', '>15 km'], $data->pluck('wilayah')->all());
            $this->assertFalse($data->contains('id', $nonaktif->id));
        }
    }

    public function test_two_payment_methods_are_stored_and_exposed(): void
    {
        $this->seed();

        $this->assertDatabaseCount('payment_methods', 2);
        $this->assertDatabaseHas('payment_methods', ['nama' => 'Transfer Bank', 'aktif' => true]);
        $this->assertDatabaseHas('payment_methods', ['nama' => 'Bayar di Tempat', 'aktif' => true]);

        foreach (['/api/metode-pembayaran', '/api/payment-methods'] as $uri) {
            $response = $this->getJson($uri)
                ->assertOk()
                ->assertJsonPath('status', 'sukses');

            $names = collect($response->json('data'))->pluck('nama')->sort()->values()->all();

            $this->assertSame(['Bayar di Tempat', 'Transfer Bank'], $names);
        }
    }

    public function test_history_is_newest_first_and_detail_uses_price_snapshot(): void
    {
        $product = $this->createProduct(['nama' => 'Bayam Awal', 'harga' => 5000]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();

        $firstId = $this->checkout(
            $this->checkoutPayload($product, $courier, $paymentMethod, null, 2),
            'acceptance-history-first'
        )->assertCreated()->json('data.id');

        $secondId = $this->checkout(
            $this->checkoutPayload($product, $courier, $paymentMethod, null, 1),
            'acceptance-history-second'
        )->assertCreated()->json('data.id');

        DB::table('orders')->where('id', $firstId)->update(['created_at' => now()->subDay()]);
        DB::table('orders')->where('id', $secondId)->update(['created_at' => now()]);

        $history = $this->getJson('/api/pesanan')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertSame(
            [(int) $secondId, (int) $firstId],
            collect($history->json('data'))->pluck('id')->map(fn ($id) => (int) $id)->all()
        );

        $product->update(['nama' => 'Bayam Nama Baru', 'harga' => 9000]);

        $this->getJson("/api/pesanan/{$firstId}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.items.0.nama_produk', 'Bayam Awal')
            ->assertJsonPath('data.items.0.harga_satuan', 5000)
            ->assertJsonPath('data.items.0.subtotal', 10000);

        $this->getJson('/api/pesanan/999999')
            ->assertNotFound()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '404');
    }

    public function test_status_simulation_follows_defined_sequence(): void
    {
        $orderId = $this->createOrder('acceptance-status-sequence');

        foreach ([
            'menunggu_konfirmasi',
            'dibayar',
            'diproses',
            'dikirim',
            'selesai',
        ] as $status) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $status])
                ->assertOk()
                ->assertJsonPath('status', 'sukses')
                ->assertJsonPath('data.status', $status);

            $this->assertDatabaseHas('orders', ['id' => $orderId, 'status' => $status]);
        }
    }

    public function test_status_cannot_skip_a_stage(): void
    {
        $orderId = $this->createOrder('acceptance-status-skip');

        foreach (['dibayar', 'diproses', 'dikirim', 'selesai'] as $status) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $status])
                ->assertStatus(409)
                ->assertJsonPath('status', 'gagal')
                ->assertJsonPath('code', '409');

            $this->assertDatabaseHas('orders', [
                'id' => $orderId,
                'status' => 'menunggu_pembayaran',
            ]);
        }

        $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => 'menunggu_konfirmasi'])
            ->assertOk();

        $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => 'dikirim'])
            ->assertStatus(409);

        $this->assertDatabaseHas('orders', [
            'id' => $orderId,
            'status' => 'menunggu_konfirmasi',
        ]);
    }

    public function test_finished_order_cannot_be_revived(): void
    {
        $orderId = $this->createOrder('acceptance-status-finished');

        foreach (['menunggu_konfirmasi', 'dibayar', 'diproses', 'dikirim', 'selesai'] as $status) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $status])->assertOk();
        }

        foreach ([
            'menunggu_pembayaran',
            'menunggu_konfirmasi',
            'dibayar',
            'diproses',
            'dikirim',
            'selesai',
            'dibatalkan',
        ] as $status) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $status])
                ->assertStatus(409);

            $this->assertDatabaseHas('orders', ['id' => $orderId, 'status' => 'selesai']);
        }
    }

    public function test_cancelled_order_cannot_be_revived(): void
    {
        $orderId = $this->createOrder('acceptance-status-cancelled');

        $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => 'dibatalkan'])
            ->assertOk();

        foreach ([
            'menunggu_pembayaran',
            'menunggu_konfirmasi',
            'dibayar',
            'diproses',
            'dikirim',
            'selesai',
            'dibatalkan',
        ] as $status) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $status])
                ->assertStatus(409);

            $this->assertDatabaseHas('orders', ['id' => $orderId, 'status' => 'dibatalkan']);
        }
    }

    public function test_same_status_is_treated_as_illegal_transition(): void
    {
        $orderId = $this->createOrder('acceptance-status-same');

        $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => 'menunggu_pembayaran'])
            ->assertStatus(409);

        $this->assertDatabaseHas('orders', [
            'id' => $orderId,
            'status' => 'menunggu_pembayaran',
        ]);
    }

    public function test_repeated_checkout_with_same_key_returns_existing_order(): void
    {
        $product = $this->createProduct(['stok' => 10]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $payload = $this->checkoutPayload($product, $courier, $paymentMethod, null, 2);

        $first = $this->checkout($payload, 'acceptance-idempotent-same')
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 10000);

        $orderId = $first->json('data.id');

        $this->checkout($payload, 'acceptance-idempotent-same')
            ->assertOk()
            ->assertJsonPath('code', '200')
            ->assertJsonPath('data.id', $orderId);

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 8]);
    }

    public function test_different_keys_create_separate_orders(): void
    {
        $product = $this->createProduct(['stok' => 10]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $payload = $this->checkoutPayload($product, $courier, $paymentMethod, null, 2);

        $firstId = $this->checkout($payload, 'acceptance-key-pertama')
            ->assertCreated()
            ->json('data.id');

        $secondId = $this->checkout($payload, 'acceptance-key-kedua')
            ->assertCreated()
            ->json('data.id');

        $this->assertNotSame($firstId, $secondId);
        $this->assertDatabaseCount('orders', 2);
        $this->assertDatabaseCount('order_items', 2);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 6]);
    }

    public function test_insufficient_stock_leaves_orders_stock_and_cart_untouched(): void
    {
        $product = $this->createProduct(['stok' => 2]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $pelanggan = $this->createPelanggan();
        $this->addToCart($pelanggan->id, $product->id, 3);

        $this->postJson('/api/checkout', [
            'nama_penerima' => 'Penerima Uji',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
        ], [
            'X-Kunci-Idempoten' => 'acceptance-stock-kurang',
            'X-Pelanggan-Id' => (string) $pelanggan->id,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stok' => 2]);
        $this->assertDatabaseHas('carts', [
            'customer_id' => $pelanggan->id,
            'product_id' => $product->id,
            'quantity' => 3,
        ]);
    }

    public function test_failure_in_the_middle_rolls_back_every_change(): void
    {
        $firstProduct = $this->createProduct(['nama' => 'Produk Pertama', 'stok' => 5]);
        $secondProduct = $this->createProduct(['nama' => 'Produk Kedua', 'stok' => 1]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $pelanggan = $this->createPelanggan();
        $this->addToCart($pelanggan->id, $firstProduct->id, 2);

        $this->postJson('/api/checkout', [
            'nama_penerima' => 'Penerima Uji',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
            'items' => [
                ['product_id' => $firstProduct->id, 'quantity' => 2],
                ['product_id' => $secondProduct->id, 'quantity' => 2],
            ],
        ], [
            'X-Kunci-Idempoten' => 'acceptance-rollback-tengah',
            'X-Pelanggan-Id' => (string) $pelanggan->id,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '422');

        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('order_items', 0);
        $this->assertDatabaseHas('products', ['id' => $firstProduct->id, 'stok' => 5]);
        $this->assertDatabaseHas('products', ['id' => $secondProduct->id, 'stok' => 1]);
        $this->assertDatabaseHas('carts', [
            'customer_id' => $pelanggan->id,
            'product_id' => $firstProduct->id,
            'quantity' => 2,
        ]);
    }

    private function checkout(array $payload, string $idempotencyKey)
    {
        return $this->postJson('/api/checkout', $payload, [
            'X-Kunci-Idempoten' => $idempotencyKey,
        ]);
    }

    private function createOrder(string $idempotencyKey): int
    {
        $product = $this->createProduct();
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();

        return $this->checkout(
            $this->checkoutPayload($product, $courier, $paymentMethod, null, 1),
            $idempotencyKey
        )
            ->assertCreated()
            ->json('data.id');
    }
}
