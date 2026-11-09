<?php

namespace Tests\Feature;

use App\Models\Courier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class KurirTest extends TestCase
{
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
}
