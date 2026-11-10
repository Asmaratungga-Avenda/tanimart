<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Order;
use App\Models\PaymentMethod;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\AuthenticatedApiRequests;
use Tests\TestCase;

class PesananCompletionTest extends TestCase
{
    use AuthenticatedApiRequests;
    use RefreshDatabase;

    public function test_customer_can_complete_order_when_status_is_dikirim(): void
    {
        $customer = $this->createCustomer();
        $order = $this->createOrderFor($customer, 'dikirim');

        $this->authenticateAs($customer);

        $this->postJson("/api/pesanan/{$order->id}/selesai")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.status', 'selesai');

        $order->refresh();

        $this->assertSame('selesai', $order->status);
        $this->assertNotNull($order->selesai_at);
        $this->assertNotNull($order->tiba_at);
    }

    public function test_customer_cannot_complete_order_before_it_is_shipped(): void
    {
        $customer = $this->createCustomer();
        $order = $this->createOrderFor($customer, 'diproses');

        $this->authenticateAs($customer);

        $this->postJson("/api/pesanan/{$order->id}/selesai")
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409');

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => 'diproses',
            'selesai_at' => null,
        ]);
    }

    public function test_customer_cannot_complete_another_customers_order(): void
    {
        $owner = $this->createCustomer();
        $other = $this->createCustomer();
        $order = $this->createOrderFor($owner, 'dikirim');

        $this->authenticateAs($other);

        $this->postJson("/api/pesanan/{$order->id}/selesai")
            ->assertStatus(403)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '403');

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => 'dikirim',
            'selesai_at' => null,
        ]);
    }

    public function test_repeated_completion_does_not_change_finished_order(): void
    {
        $customer = $this->createCustomer();
        $order = $this->createOrderFor($customer, 'dikirim');

        $this->authenticateAs($customer);

        $this->postJson("/api/pesanan/{$order->id}/selesai")->assertOk();

        $finishedAt = $order->fresh()->selesai_at;

        $this->postJson("/api/pesanan/{$order->id}/selesai")
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409');

        $order->refresh();

        $this->assertSame('selesai', $order->status);
        $this->assertEquals($finishedAt, $order->selesai_at);
    }

    public function test_unauthenticated_user_cannot_complete_order(): void
    {
        $customer = $this->createCustomer();
        $order = $this->createOrderFor($customer, 'dikirim');

        auth()->forgetGuards();

        $this->withHeader('Authorization', '')
            ->postJson("/api/pesanan/{$order->id}/selesai")
            ->assertUnauthorized();

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => 'dikirim',
        ]);
    }

    private function createCustomer(): User
    {
        return User::factory()->create(['role' => 'customer']);
    }

    private function createOrderFor(User $customer, string $status): Order
    {
        $courier = Courier::create([
            'nama' => 'Kurir Uji '.$customer->id.' '.$status,
            'tarif' => 10000,
            'aktif' => true,
        ]);
        $payment = PaymentMethod::create([
            'nama' => 'Pembayaran Uji '.$customer->id.' '.$status,
            'aktif' => true,
        ]);

        return Order::create([
            'customer_id' => $customer->id,
            'pelanggan_id' => $customer->id,
            'nama_penerima' => 'Penerima Uji',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 10000,
            'ongkir' => 10000,
            'total_harga' => 20000,
            'status' => $status,
            'payment_status' => 'lunas',
            'tanggal_antar' => now()->toDateString(),
            'dikirim_at' => $status === 'dikirim' ? now() : null,
        ]);
    }
}
