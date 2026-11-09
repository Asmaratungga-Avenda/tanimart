<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\PaymentMethod;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Symfony\Component\Process\Process;
use Tests\Support\CheckoutFixtures;
use Tests\TestCase;

class CheckoutConcurrencyTest extends TestCase
{
    use CheckoutFixtures;
    use DatabaseMigrations;

    public function test_two_simultaneous_checkouts_on_limited_stock_create_only_one_order(): void
    {
        $product = $this->createProduct(['stok' => 1]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $buyerOne = $this->createPelanggan();
        $buyerTwo = $this->createPelanggan();

        $this->addToCart($buyerOne->id, $product->id, 1);
        $this->addToCart($buyerTwo->id, $product->id, 1);

        $payload = $this->cartCheckoutPayload($courier, $paymentMethod);

        $results = $this->runConcurrentCheckouts([
            ['payload' => $payload, 'key' => 'race-stok-pembeli-1', 'pelanggan_id' => $buyerOne->id],
            ['payload' => $payload, 'key' => 'race-stok-pembeli-2', 'pelanggan_id' => $buyerTwo->id],
        ]);

        $successes = collect($results)->where('http_status', 201);
        $failures = collect($results)->filter(
            fn (array $result) => in_array($result['http_status'], [409, 422], true)
        );

        $this->assertCount(1, $successes, 'Tepat satu checkout harus berhasil.');
        $this->assertCount(1, $failures, 'Checkout kedua harus ditolak karena stok habis.');

        $winner = $successes->first();
        $winnerId = (int) $winner['body']['data']['pelanggan_id'];
        $loserId = $winnerId === $buyerOne->id ? $buyerTwo->id : $buyerOne->id;

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
        $this->assertDatabaseHas('orders', [
            'id' => $winner['body']['data']['id'],
            'pelanggan_id' => $winnerId,
        ]);
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 0,
            'tersedia' => false,
        ]);

        $this->assertDatabaseMissing('keranjang', [
            'pelanggan_id' => $winnerId,
            'product_id' => $product->id,
        ]);
        $this->assertDatabaseHas('keranjang', [
            'pelanggan_id' => $loserId,
            'product_id' => $product->id,
            'jumlah' => 1,
        ]);
    }

    public function test_simultaneous_retry_with_same_idempotency_key_creates_one_order(): void
    {
        $product = $this->createProduct(['stok' => 5]);
        $courier = $this->createCourier();
        $paymentMethod = $this->createPaymentMethod();
        $pelanggan = $this->createPelanggan();

        $this->addToCart($pelanggan->id, $product->id, 2);

        $payload = $this->cartCheckoutPayload($courier, $paymentMethod);

        $results = $this->runConcurrentCheckouts([
            ['payload' => $payload, 'key' => 'race-kunci-sama', 'pelanggan_id' => $pelanggan->id],
            ['payload' => $payload, 'key' => 'race-kunci-sama', 'pelanggan_id' => $pelanggan->id],
        ]);

        $statuses = collect($results)->pluck('http_status')->sort()->values()->all();
        $this->assertSame([200, 201], $statuses, 'Satu request membuat pesanan, satunya mengembalikan pesanan lama.');

        $ids = collect($results)
            ->pluck('body.data.id')
            ->filter()
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        $this->assertCount(1, $ids);

        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseCount('order_items', 1);
        $this->assertDatabaseHas('orders', [
            'id' => $ids->first(),
            'idempotency_key' => 'race-kunci-sama',
            'pelanggan_id' => $pelanggan->id,
        ]);
        $this->assertDatabaseHas('order_items', [
            'order_id' => $ids->first(),
            'product_id' => $product->id,
            'quantity' => 2,
        ]);
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stok' => 3,
        ]);
        $this->assertDatabaseMissing('keranjang', [
            'pelanggan_id' => $pelanggan->id,
            'product_id' => $product->id,
        ]);
    }

    private function cartCheckoutPayload(Courier $courier, PaymentMethod $paymentMethod): array
    {
        return [
            'nama_penerima' => 'Penerima Uji',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => now()->toDateString(),
            'slot_pengantaran' => 'pagi',
        ];
    }

    /**
     * @param  array<int, array{payload: array, key: string, pelanggan_id: int}>  $requests
     * @return array<int, array{http_status: int, body: array}>
     */
    private function runConcurrentCheckouts(array $requests): array
    {
        $barrier = sys_get_temp_dir().DIRECTORY_SEPARATOR.'tokotani-race-'.uniqid('', true);
        $processes = [];

        foreach ($requests as $request) {
            $process = new Process([
                PHP_BINARY,
                base_path('tests/Support/checkout_request.php'),
                base64_encode(json_encode($request['payload'])),
                $request['key'],
                (string) $request['pelanggan_id'],
                $barrier,
            ], base_path(), $this->processEnvironment());

            $process->setTimeout(60);
            $process->start();

            $processes[] = $process;
        }

        touch($barrier);

        $results = [];

        foreach ($processes as $process) {
            $process->wait();

            if (! $process->isSuccessful()) {
                $this->fail(
                    'Proses checkout gagal. Stderr: '.$process->getErrorOutput().
                    ' Stdout: '.$process->getOutput()
                );
            }

            $output = $process->getOutput();
            $marker = '__CHECKOUT_RESULT__';
            $position = strpos($output, $marker);

            $this->assertNotFalse($position, 'Output proses tidak memuat penanda hasil: '.$output);

            $decoded = json_decode(substr($output, $position + strlen($marker)), true);

            $this->assertIsArray($decoded, 'Output proses bukan JSON yang valid: '.$output);

            $results[] = $decoded;
        }

        @unlink($barrier);

        return $results;
    }

    private function processEnvironment(): array
    {
        $connection = config('database.default');
        $database = config("database.connections.{$connection}");

        return array_filter([
            'APP_ENV' => 'testing',
            'APP_KEY' => config('app.key'),
            'DB_CONNECTION' => $connection,
            'DB_HOST' => $database['host'] ?? null,
            'DB_PORT' => isset($database['port']) ? (string) $database['port'] : null,
            'DB_DATABASE' => $database['database'] ?? null,
            'DB_USERNAME' => $database['username'] ?? null,
            'DB_PASSWORD' => $database['password'] ?? null,
            'CACHE_STORE' => 'array',
            'SESSION_DRIVER' => 'array',
            'QUEUE_CONNECTION' => 'sync',
            'MAIL_MAILER' => 'array',
        ], fn ($value) => $value !== null);
    }
}
