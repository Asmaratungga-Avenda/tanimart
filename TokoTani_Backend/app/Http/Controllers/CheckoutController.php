<?php

namespace App\Http\Controllers;

use App\Models\Courier;
use App\Models\Keranjang;
use App\Models\Order;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\QueryException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class CheckoutController extends Controller
{
    private function jsonResponse($status, $code, $message, $data = null, $errors = null)
    {
        $response = [
            'status' => $status,
            'code' => (string) $code,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, (int) $code);
    }

    public function couriers()
    {
        $couriers = Courier::where('aktif', true)->get();

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar kurir berhasil diambil',
            $couriers
        );
    }

    public function paymentMethods()
    {
        $methods = PaymentMethod::where('aktif', true)->get();

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar metode pembayaran berhasil diambil',
            $methods
        );
    }

    public function index()
    {
        $orders = Order::with(['items.product', 'courier', 'paymentMethod'])
            ->latest()
            ->get();

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar pesanan berhasil diambil',
            $orders
        );
    }

    public function show($id)
    {
        $order = Order::with(['items.product', 'courier', 'paymentMethod'])->find($id);

        if (! $order) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Pesanan tidak ditemukan'
            );
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Rincian pesanan berhasil diambil',
            $order
        );
    }

    public function store(Request $request)
    {
        $data = $this->normalizeInput($request);
        $idempotencyKey = $this->resolveIdempotencyKey($request);
        $pelangganId = $this->resolvePelangganId($request, $data);

        $data['idempotency_key'] = $idempotencyKey;
        $data['pelanggan_id'] = $pelangganId;

        // Fingerprint dihitung dari payload asli. Checkout dari keranjang tidak
        // memasukkan isi keranjang agar retry dengan payload yang sama tetap sama.
        $fingerprint = $this->requestHash($this->fingerprintPayload($data, $pelangganId));

        $itemsFromCart = ! $this->hasItemsInput($data);
        if ($itemsFromCart) {
            $data['items'] = $this->cartItems($pelangganId);
        }

        if ($idempotencyKey !== null) {
            $existingOrder = Order::with(['items', 'courier', 'paymentMethod'])
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existingOrder) {
                return $this->idempotentResponse($existingOrder, $fingerprint);
            }
        }

        $validator = Validator::make($data, [
            'nama_penerima' => 'required|string|max:255',
            'alamat_penerima' => 'required|string|max:2000',
            'kurir_id' => ['required', Rule::exists('couriers', 'id')->where('aktif', true)],
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('aktif', true)],
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|distinct|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'tanggal_antar' => 'required|date_format:Y-m-d|after_or_equal:today',
            'slot_pengantaran' => ['required', 'string', Rule::in(config('checkout.slot_pengantaran'))],
            'pelanggan_id' => 'required|integer|min:1',
            'idempotency_key' => 'required|string|max:255',
        ], [
            'kurir_id.required' => 'Pilihan kurir/wilayah wajib diisi.',
            'kurir_id.exists' => 'Kurir/wilayah tidak ditemukan atau tidak aktif.',
            'payment_method_id.required' => 'Metode pembayaran wajib dipilih.',
            'payment_method_id.exists' => 'Metode pembayaran tidak ditemukan atau tidak aktif.',
            'items.required' => 'Keranjang kosong atau item checkout belum diisi.',
            'items.min' => 'Minimal satu produk harus di-checkout.',
            'items.*.product_id.distinct' => 'Produk yang sama tidak boleh muncul lebih dari sekali.',
            'items.*.product_id.exists' => 'Produk tidak ditemukan.',
            'items.*.quantity.min' => 'Kuantitas minimal 1.',
            'tanggal_antar.required' => 'Tanggal pengantaran wajib diisi.',
            'tanggal_antar.date_format' => 'Format tanggal pengantaran harus YYYY-MM-DD.',
            'tanggal_antar.after_or_equal' => 'Tanggal pengantaran tidak boleh di masa lalu.',
            'slot_pengantaran.required' => 'Slot pengantaran wajib dipilih.',
            'slot_pengantaran.in' => 'Slot pengantaran tidak valid.',
            'idempotency_key.required' => 'Header X-Kunci-Idempoten wajib dikirim.',
            'idempotency_key.max' => 'Kunci idempoten terlalu panjang.',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Validasi checkout gagal',
                null,
                $validator->errors()
            );
        }

        $validated = $validator->validated();
        $this->ensurePelangganExists($pelangganId);

        $tanggalAntar = Carbon::createFromFormat('Y-m-d', $validated['tanggal_antar'])->startOfDay();
        $isSameDay = $tanggalAntar->isSameDay(Carbon::today());
        $maxMudahRusak = (int) config('checkout.max_mudah_rusak_per_pesanan', 5);

        try {
            $order = DB::transaction(function () use (
                $validated,
                $isSameDay,
                $maxMudahRusak,
                $idempotencyKey,
                $fingerprint,
                $pelangganId,
                $itemsFromCart
            ) {
                $items = collect($validated['items'])
                    ->map(fn (array $item) => [
                        'product_id' => (int) $item['product_id'],
                        'quantity' => (int) $item['quantity'],
                    ])
                    ->sortBy('product_id')
                    ->values()
                    ->all();

                // Kunci produk lebih dulu dengan urutan product_id. Urutan ini
                // sama dengan alur keranjang (produk lalu baris keranjang) dan
                // mencegah deadlock.
                $products = [];

                foreach ($items as $item) {
                    $product = Product::lockForUpdate()->find($item['product_id']);

                    if (! $product) {
                        abort($this->jsonResponse('gagal', 404, 'Produk tidak ditemukan'));
                    }

                    $products[$product->id] = $product;
                }

                $productIds = collect($items)->pluck('product_id')->all();

                if ($itemsFromCart) {
                    $cartRows = Keranjang::where('pelanggan_id', $pelangganId)
                        ->lockForUpdate()
                        ->get();

                    if ($cartRows->isEmpty()) {
                        abort($this->jsonResponse(
                            'gagal',
                            422,
                            'Keranjang kosong. Tambahkan produk terlebih dahulu.'
                        ));
                    }

                    $lockedProductIds = $cartRows
                        ->pluck('product_id')
                        ->map(fn ($id) => (int) $id)
                        ->sort()
                        ->values()
                        ->all();

                    $expectedProductIds = collect($productIds)
                        ->map(fn ($id) => (int) $id)
                        ->sort()
                        ->values()
                        ->all();

                    if ($lockedProductIds !== $expectedProductIds) {
                        abort($this->jsonResponse(
                            'gagal',
                            409,
                            'Isi keranjang berubah. Silakan ulangi checkout.'
                        ));
                    }

                    $items = $cartRows
                        ->map(fn (Keranjang $row) => [
                            'product_id' => (int) $row->product_id,
                            'quantity' => (int) $row->jumlah,
                        ])
                        ->sortBy('product_id')
                        ->values()
                        ->all();
                } else {
                    // Tetap kunci baris keranjang yang terkait agar tidak berubah
                    // bersamaan saat checkout berbasis payload items.
                    Keranjang::where('pelanggan_id', $pelangganId)
                        ->whereIn('product_id', $productIds)
                        ->lockForUpdate()
                        ->get();
                }

                $subtotal = 0;
                $orderItems = [];

                foreach ($items as $item) {
                    $product = $products[$item['product_id']] ?? null;

                    if (! $product) {
                        abort($this->jsonResponse('gagal', 404, 'Produk tidak ditemukan'));
                    }

                    if (! $product->tersedia || $product->stok <= 0) {
                        abort($this->jsonResponse(
                            'gagal',
                            409,
                            "Produk {$product->nama} habis atau tidak tersedia"
                        ));
                    }

                    if ($item['quantity'] > $product->stok) {
                        abort($this->jsonResponse(
                            'gagal',
                            422,
                            "Stok untuk produk '{$product->nama}' tidak mencukupi",
                            null,
                            ['checkout' => ["Stok untuk produk '{$product->nama}' tidak mencukupi"]]
                        ));
                    }

                    if ($product->mudah_rusak && ! $isSameDay) {
                        abort($this->jsonResponse(
                            'gagal',
                            422,
                            "Produk '{$product->nama}' bersifat mudah rusak dan wajib dikirim pada hari yang sama",
                            null,
                            ['checkout' => ["Produk '{$product->nama}' wajib dikirim pada hari yang sama"]]
                        ));
                    }

                    if ($product->mudah_rusak && $item['quantity'] > $maxMudahRusak) {
                        abort($this->jsonResponse(
                            'gagal',
                            422,
                            "Kuantitas produk mudah rusak '{$product->nama}' maksimal {$maxMudahRusak} per pesanan",
                            null,
                            ['checkout' => ["Kuantitas maksimal {$maxMudahRusak} untuk produk '{$product->nama}'"]]
                        ));
                    }

                    $itemSubtotal = (int) $product->harga * $item['quantity'];
                    $subtotal += $itemSubtotal;
                    $product->stok -= $item['quantity'];

                    if ($product->stok <= 0) {
                        $product->tersedia = false;
                    }

                    $product->save();

                    $orderItems[] = [
                        'product_id' => $product->id,
                        'nama_produk' => $product->nama,
                        'quantity' => $item['quantity'],
                        'harga_satuan' => $product->harga,
                        'subtotal' => $itemSubtotal,
                    ];
                }

                $kurir = Courier::where('id', $validated['kurir_id'])
                    ->where('aktif', true)
                    ->lockForUpdate()
                    ->first();

                if (! $kurir) {
                    abort($this->jsonResponse(
                        'gagal',
                        422,
                        'Kurir tidak tersedia atau tidak aktif',
                        null,
                        ['kurir_id' => ['Kurir tidak tersedia atau tidak aktif.']]
                    ));
                }

                $paymentMethod = PaymentMethod::where('id', $validated['payment_method_id'])
                    ->where('aktif', true)
                    ->first();

                if (! $paymentMethod) {
                    abort($this->jsonResponse(
                        'gagal',
                        422,
                        'Metode pembayaran tidak tersedia atau tidak aktif',
                        null,
                        ['payment_method_id' => ['Metode pembayaran tidak tersedia atau tidak aktif.']]
                    ));
                }

                $ongkir = (int) $kurir->tarif;

                $order = Order::create([
                    'pelanggan_id' => $pelangganId,
                    'nama_penerima' => $validated['nama_penerima'],
                    'alamat_penerima' => $validated['alamat_penerima'],
                    'kurir_id' => $validated['kurir_id'],
                    'payment_method_id' => $validated['payment_method_id'],
                    'subtotal' => $subtotal,
                    'ongkir' => $ongkir,
                    'total_harga' => $subtotal + $ongkir,
                    'status' => 'menunggu_pembayaran',
                    'idempotency_key' => $idempotencyKey,
                    'idempotency_request_hash' => $fingerprint,
                    'tanggal_antar' => $validated['tanggal_antar'],
                    'tanggal_pengantaran' => $validated['tanggal_antar'],
                    'slot_pengantaran' => $validated['slot_pengantaran'],
                ]);

                $order->items()->createMany($orderItems);

                Keranjang::where('pelanggan_id', $pelangganId)
                    ->whereIn('product_id', $productIds)
                    ->delete();

                return $order->load(['items', 'courier', 'paymentMethod']);
            });

            return $this->jsonResponse(
                'sukses',
                201,
                'Checkout berhasil diproses',
                $order
            );
        } catch (HttpResponseException $e) {
            return $e->getResponse();
        } catch (QueryException $e) {
            if ($idempotencyKey !== null) {
                $existingOrder = Order::with(['items', 'courier', 'paymentMethod'])
                    ->where('idempotency_key', $idempotencyKey)
                    ->first();

                if ($existingOrder) {
                    return $this->idempotentResponse($existingOrder, $fingerprint);
                }
            }

            report($e);

            return $this->jsonResponse(
                'gagal',
                500,
                'Terjadi kesalahan pada server'
            );
        } catch (\Throwable $e) {
            report($e);

            return $this->jsonResponse(
                'gagal',
                500,
                'Terjadi kesalahan pada server'
            );
        }
    }

    private function resolveIdempotencyKey(Request $request): ?string
    {
        $key = $request->header('X-Kunci-Idempoten')
            ?: $request->header('X-Idempotency-Key')
            ?: $request->header('Idempotency-Key')
            ?: $request->input('idempotency_key');

        if (! is_string($key)) {
            return null;
        }

        $key = trim($key);

        return $key === '' ? null : $key;
    }

    private function resolvePelangganId(Request $request, array $data): int
    {
        if (auth()->check()) {
            return (int) auth()->id();
        }

        $id = $request->header('X-Pelanggan-Id')
            ?? $request->header('X-Customer-Id')
            ?? ($data['pelanggan_id'] ?? null)
            ?? 1;

        $id = (int) $id;

        return $id > 0 ? $id : 1;
    }

    private function ensurePelangganExists(int $pelangganId): void
    {
        if (User::whereKey($pelangganId)->exists()) {
            return;
        }

        DB::table('users')->insertOrIgnore([
            'id' => $pelangganId,
            'name' => 'Pelanggan '.$pelangganId,
            'email' => 'pelanggan'.$pelangganId.'@tokotani.local',
            'password' => bcrypt(Str::random(16)),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function normalizeInput(Request $request): array
    {
        $data = $request->all();

        $aliases = [
            'courier_id' => 'kurir_id',
            'wilayah_id' => 'kurir_id',
            'wilayah_antar_id' => 'kurir_id',
            'metode_pembayaran_id' => 'payment_method_id',
            'payment_method' => 'payment_method_id',
            'tanggal_pengantaran' => 'tanggal_antar',
            'slot' => 'slot_pengantaran',
            'nama' => 'nama_penerima',
            'alamat' => 'alamat_penerima',
        ];

        foreach ($aliases as $from => $to) {
            if (! array_key_exists($to, $data) && array_key_exists($from, $data)) {
                $data[$to] = $data[$from];
            }
        }

        if (isset($data['slot_pengantaran']) && is_string($data['slot_pengantaran'])) {
            $data['slot_pengantaran'] = strtolower(trim($data['slot_pengantaran']));
        }

        if (isset($data['items']) && is_array($data['items'])) {
            $data['items'] = array_map(function ($item) {
                if (! is_array($item)) {
                    return $item;
                }

                if (! array_key_exists('product_id', $item)) {
                    $item['product_id'] = $item['produk_id'] ?? null;
                }

                if (! array_key_exists('quantity', $item)) {
                    $item['quantity'] = $item['jumlah'] ?? $item['qty'] ?? null;
                }

                return $item;
            }, $data['items']);
        }

        return $data;
    }

    private function hasItemsInput(array $data): bool
    {
        return array_key_exists('items', $data)
            && $data['items'] !== null
            && $data['items'] !== [];
    }

    private function cartItems(int $pelangganId): array
    {
        return Keranjang::where('pelanggan_id', $pelangganId)
            ->orderBy('product_id')
            ->get(['product_id', 'jumlah'])
            ->map(fn (Keranjang $row) => [
                'product_id' => (int) $row->product_id,
                'quantity' => (int) $row->jumlah,
            ])
            ->all();
    }

    private function fingerprintPayload(array $data, int $pelangganId): array
    {
        $items = null;

        if (isset($data['items']) && is_array($data['items']) && $data['items'] !== []) {
            $items = collect($data['items'])
                ->map(function ($item) {
                    if (! is_array($item)) {
                        return $item;
                    }

                    return [
                        'product_id' => $this->intOrOriginal($item['product_id'] ?? null),
                        'quantity' => $this->intOrOriginal($item['quantity'] ?? null),
                    ];
                })
                ->sortBy('product_id')
                ->values()
                ->all();
        }

        return [
            'pelanggan_id' => $pelangganId,
            'nama_penerima' => $this->stringOrNull($data['nama_penerima'] ?? null),
            'alamat_penerima' => $this->stringOrNull($data['alamat_penerima'] ?? null),
            'kurir_id' => $this->intOrOriginal($data['kurir_id'] ?? null),
            'payment_method_id' => $this->intOrOriginal($data['payment_method_id'] ?? null),
            'tanggal_antar' => $this->stringOrNull($data['tanggal_antar'] ?? null),
            'slot_pengantaran' => $this->stringOrNull($data['slot_pengantaran'] ?? null),
            'items' => $items,
        ];
    }

    private function intOrOriginal(mixed $value): mixed
    {
        return is_numeric($value) ? (int) $value : $value;
    }

    private function stringOrNull(mixed $value): ?string
    {
        return is_string($value) ? trim($value) : null;
    }

    private function requestHash(array $payload): string
    {
        $json = json_encode(
            $this->canonicalize($payload),
            JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
        );

        return hash('sha256', $json === false ? '' : $json);
    }

    private function canonicalize(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        if (array_is_list($value)) {
            return array_map(fn ($item) => $this->canonicalize($item), $value);
        }

        ksort($value);

        foreach ($value as $key => $item) {
            $value[$key] = $this->canonicalize($item);
        }

        return $value;
    }

    private function idempotentResponse(Order $order, string $fingerprint)
    {
        if ($order->idempotency_request_hash !== null
            && ! hash_equals($order->idempotency_request_hash, $fingerprint)) {
            return $this->jsonResponse(
                'gagal',
                409,
                'Kunci idempoten sudah digunakan untuk permintaan checkout yang berbeda',
                null,
                ['idempotency_key' => ['Gunakan kunci baru untuk payload checkout yang berbeda.']]
            );
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Pesanan sudah diproses sebelumnya',
            $order->loadMissing(['items', 'courier', 'paymentMethod'])
        );
    }
}
