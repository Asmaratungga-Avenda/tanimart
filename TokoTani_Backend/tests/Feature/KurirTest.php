<?php

namespace Tests\Feature;

use App\Models\Courier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CheckoutFixtures;
use Tests\TestCase;

class KurirTest extends TestCase
{
    use CheckoutFixtures;
    use RefreshDatabase;

    public function test_can_fetch_at_least_three_active_couriers_with_different_tariffs(): void
    {
        Courier::create(['nama' => 'Kurir Dekat', 'wilayah' => '0-5 km', 'tarif' => 10000, 'aktif' => true]);
        Courier::create(['nama' => 'Kurir Sedang', 'wilayah' => '5-15 km', 'tarif' => 20000, 'aktif' => true]);
        Courier::create(['nama' => 'Kurir Jauh', 'wilayah' => '>15 km', 'tarif' => 35000, 'aktif' => true]);
        Courier::create(['nama' => 'Kurir Nonaktif', 'wilayah' => '>15 km', 'tarif' => 40000, 'aktif' => false]);

        $response = $this->getJson('/api/kurir')
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.0.wilayah', '0-5 km')
            ->assertJsonPath('data.0.tarif', 10000);

        $data = collect($response->json('data'));

        $this->assertCount(3, $data);
        $this->assertCount(3, $data->pluck('tarif')->unique());
        $this->assertSame([10000, 20000, 35000], $data->pluck('tarif')->all());
    }

    public function test_deleting_courier_used_by_order_keeps_old_order_history_intact(): void
    {
        $product = $this->createProduct(['stok' => 5]);
        $courier = $this->createCourier([
            'nama' => 'Kurir Lama',
            'wilayah' => '0-5 km',
            'tarif' => 10000,
        ]);
        $paymentMethod = $this->createPaymentMethod();

        $orderId = $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            null,
            2
        ), ['X-Kunci-Idempoten' => 'hapus-kurir-riwayat'])->assertCreated()->json('data.id');

        $this->deleteJson("/api/kurir/{$courier->id}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.id', $courier->id)
            ->assertJsonPath('data.dipakai_pada_pesanan', true);

        $this->assertSoftDeleted('couriers', ['id' => $courier->id]);
        $this->assertDatabaseHas('orders', [
            'id' => $orderId,
            'kurir_id' => $courier->id,
            'ongkir' => 10000,
        ]);
        $this->assertDatabaseHas('order_items', ['order_id' => $orderId]);

        $this->getJson("/api/pesanan/{$orderId}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.courier.id', $courier->id)
            ->assertJsonPath('data.courier.nama', 'Kurir Lama')
            ->assertJsonPath('data.courier.wilayah', '0-5 km')
            ->assertJsonPath('data.courier.tarif', 10000);

        $active = collect($this->getJson('/api/kurir')->assertOk()->json('data'));

        $this->assertFalse($active->contains('id', $courier->id));

        $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            null,
            1
        ), ['X-Kunci-Idempoten' => 'hapus-kurir-checkout-baru'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['kurir_id']);
    }

    public function test_deleting_unused_courier_and_wilayah_alias(): void
    {
        $courier = $this->createCourier(['nama' => 'Kurir Tanpa Pesanan']);
        $wilayah = $this->createCourier(['nama' => 'Wilayah Tanpa Pesanan']);

        $this->getJson('/api/wilayah')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->deleteJson("/api/couriers/{$courier->id}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.dipakai_pada_pesanan', false);

        $this->deleteJson("/api/wilayah/{$wilayah->id}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertSoftDeleted('couriers', ['id' => $courier->id]);
        $this->assertSoftDeleted('couriers', ['id' => $wilayah->id]);

        $this->deleteJson("/api/kurir/{$courier->id}")
            ->assertNotFound()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '404');
    }
}
