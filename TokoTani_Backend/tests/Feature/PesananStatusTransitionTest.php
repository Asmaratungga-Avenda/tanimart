<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\Support\CheckoutFixtures;
use Tests\TestCase;

class PesananStatusTransitionTest extends TestCase
{
    use CheckoutFixtures;
    use RefreshDatabase;

    private const STATUSES = [
        'menunggu_pembayaran',
        'menunggu_konfirmasi',
        'dibayar',
        'diproses',
        'dikirim',
        'selesai',
        'dibatalkan',
    ];

    private const TRANSITIONS = [
        'menunggu_pembayaran' => ['menunggu_konfirmasi', 'dibatalkan'],
        'menunggu_konfirmasi' => ['dibayar', 'dibatalkan'],
        'dibayar' => ['diproses'],
        'diproses' => ['dikirim'],
        'dikirim' => ['selesai'],
        'selesai' => [],
        'dibatalkan' => [],
    ];

    public function test_entire_status_transition_matrix(): void
    {
        foreach (self::STATUSES as $start) {
            $orderId = $this->createOrderAtStatus($start);

            foreach (self::STATUSES as $target) {
                if (in_array($target, self::TRANSITIONS[$start], true)) {
                    continue;
                }

                $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $target])
                    ->assertStatus(409)
                    ->assertJsonPath('status', 'gagal')
                    ->assertJsonPath('code', '409');

                $this->assertDatabaseHas('orders', [
                    'id' => $orderId,
                    'status' => $start,
                ]);
            }

            foreach (self::TRANSITIONS[$start] as $target) {
                $transitionOrderId = $this->createOrderAtStatus($start);

                $this->patchJson("/api/pesanan/{$transitionOrderId}/status", ['status' => $target])
                    ->assertOk()
                    ->assertJsonPath('status', 'sukses')
                    ->assertJsonPath('data.status', $target);

                $this->assertDatabaseHas('orders', [
                    'id' => $transitionOrderId,
                    'status' => $target,
                ]);
            }
        }
    }

    private function createOrderAtStatus(string $status): int
    {
        $product = $this->createProduct(['stok' => 10]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();

        $orderId = $this->postJson('/api/checkout', $this->checkoutPayload(
            $product,
            $courier,
            $paymentMethod,
            null,
            1
        ), ['X-Kunci-Idempoten' => 'matrix-'.Str::random(12)])
            ->assertCreated()
            ->json('data.id');

        foreach ($this->pathTo($status) as $nextStatus) {
            $this->patchJson("/api/pesanan/{$orderId}/status", ['status' => $nextStatus])
                ->assertOk();
        }

        $this->assertDatabaseHas('orders', ['id' => $orderId, 'status' => $status]);

        return (int) $orderId;
    }

    private function pathTo(string $status): array
    {
        return match ($status) {
            'menunggu_pembayaran' => [],
            'menunggu_konfirmasi' => ['menunggu_konfirmasi'],
            'dibayar' => ['menunggu_konfirmasi', 'dibayar'],
            'diproses' => ['menunggu_konfirmasi', 'dibayar', 'diproses'],
            'dikirim' => ['menunggu_konfirmasi', 'dibayar', 'diproses', 'dikirim'],
            'selesai' => ['menunggu_konfirmasi', 'dibayar', 'diproses', 'dikirim', 'selesai'],
            'dibatalkan' => ['dibatalkan'],
        };
    }
}
