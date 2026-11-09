<?php

namespace App\Http\Controllers;

use App\Models\Cart;
use App\Models\Courier;
use App\Models\Order;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Jobs\DeliverOrderSimulation;
use Carbon\Carbon;
use Illuminate\Database\QueryException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class CheckoutController extends Controller
{
    private function jsonResponse($status, $code, $message, $data = null, $errors = null, $meta = null)
    {
        $response = [
            'success' => $status === 'sukses',
            'status'  => $status,
            'code'    => (string) $code,
            'message' => $message,
            'data'    => $data,
            'meta'    => $meta,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, (int) $code);
    }

    private function getCustomerId(Request $request): int
    {
        $id = $request->header('X-Pelanggan-Id')
            ?: $request->header('X-Customer-Id')
            ?: $request->input('customer_id');

        return (int) ($id ?: 1);
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

    public function updateStatus(Request $request, $id)
    {
        $order = Order::with(['items.product', 'courier', 'paymentMethod'])->find($id);

        if (! $order) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Pesanan tidak ditemukan'
            );
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|string|in:menunggu_pembayaran,diproses,dikirim,tiba,selesai,dibatalkan',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Validasi gagal',
                null,
                $validator->errors()
            );
        }

        $order->status = $request->input('status');
        $order->save();

        return $this->jsonResponse(
            'sukses',
            200,
            'Status pesanan berhasil diperbarui',
            $order->load(['items.product', 'courier', 'paymentMethod'])
        );
    }

    /**
     * POST /api/pesanan/{id}/pembayaran
     * Pelanggan Konfirmasi pembayaran. Hanya boleh dilakukan oleh pemilik pesanan
     * dan hanya ketika status masih menunggu_pembayaran.
     * Setelah diverifikasi server, status berubah menjadi diproses.
     */
    public function pembayaran(Request $request, $id)
    {
        $customerId = $this->getCustomerId($request);

        $order = Order::find($id);

        if (! $order) {
            return $this->jsonResponse('gagal', 404, 'Pesanan tidak ditemukan');
        }

        // Hanya pemilik pesanan yang boleh konfirmasi pembayaran.
        if ((int) $order->customer_id !== $customerId) {
            return $this->jsonResponse('gagal', 403, 'Anda bukan pemilik pesanan ini.');
        }

        if ($order->status !== 'menunggu_pembayaran') {
            return $this->jsonResponse(
                'gagal',
                409,
                'Pembayaran hanya dapat dikonfirmasi pada pesanan yang masih menunggu pembayaran.'
            );
        }

        $validator = Validator::make($request->all(), [
            'payment_method_id' => 'sometimes|required|integer|exists:payment_methods,id',
            'payment_reference' => 'sometimes|nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse('gagal', 422, 'Validasi gagal', null, $validator->errors());
        }

        $order->update([
            'status' => 'diproses',
            'payment_status' => 'lunas',
            'payment_method_id' => $validator->validated()['payment_method_id'] ?? $order->payment_method_id,
        ]);

        if (filled($validator->validated()['payment_reference'] ?? null)) {
            $order->update(['payment_reference' => $validator->validated()['payment_reference']]);
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Pembayaran berhasil diverifikasi. Pesanan sekarang diproses.',
            $order->load(['items.product', 'courier', 'paymentMethod'])
        );
    }

    /**
     * POST /api/pesanan/{id}/kirim
     * Admin kirim pesanan. Hanya boleh dilakukan admin dan hanya ketika status diproses.
     * Setelah dikirim, simulasi pengiriman berjalan di backend (Laravel Queue).
     */
    public function kirim(Request $request, $id)
    {
        // Autorisasi admin melalui header X-Role atau X-Pelanggan-Role.
        $role = $request->header('X-Role')
            ?: $request->header('X-Pelanggan-Role')
            ?: $request->input('role');

        if (strtolower((string) $role) !== 'admin') {
            return $this->jsonResponse('gagal', 403, 'Hanya admin yang boleh mengirim pesanan.');
        }

        $order = Order::find($id);

        if (! $order) {
            return $this->jsonResponse('gagal', 404, 'Pesanan tidak ditemukan');
        }

        if ($order->status !== 'diproses') {
            return $this->jsonResponse(
                'gagal',
                409,
                'Pesanan hanya dapat dikirim ketika statusnya diproses.'
            );
        }

        $seconds = Config::get('delivery.seconds', 5);
        $enabled = Config::get('delivery.enabled', true);

        $order->update([
            'status' => 'dikirim',
            'dikirim_at' => now(),
        ]);

        if ($enabled) {
            DeliverOrderSimulation::dispatch($order->id)->delay(now()->addSeconds($seconds));
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Pesanan berhasil dikirim. Pengiruman akan tiba dalam simulasi.',
            $order->load(['items.product', 'courier', 'paymentMethod'])
        );
    }

    /**
     * POST /api/pesanan/{id}/selesai
     * Pelanggan menyelesaikan pesanan. Hanya boleh dilakukan oleh pemilik pesanan
     * dan hanya ketika status sudah tiba.
     */
    public function selesai(Request $request, $id)
    {
        $customerId = $this->getCustomerId($request);

        $order = Order::find($id);

        if (! $order) {
            return $this->jsonResponse('gagal', 404, 'Pesanan tidak ditemukan');
        }

        // Hanya pemilik pesanan yang boleh menyelesaikan pesanan miliknya sendiri.
        if ((int) $order->customer_id !== $customerId) {
            return $this->jsonResponse('gagal', 403, 'Anda bukan pemilik pesanan ini.');
        }

        if ($order->status !== 'tiba') {
            return $this->jsonResponse(
                'gagal',
                409,
                'Pesanan hanya dapat diselesaikan setelah status pesanan tiba.'
            );
        }

        $order->update([
            'status' => 'selesai',
            'selesai_at' => now(),
        ]);

        return $this->jsonResponse(
            'sukses',
            200,
            'Pesanan selesai. Terima kasih telah berbelanja di TaniMart.',
            $order->load(['items.product', 'courier', 'paymentMethod'])
        );
    }

    public function store(Request $request)
    {
        // Mendukung kunci idempoten baik dari header maupun body JSON
        $idempotencyKey = $request->header('X-Kunci-Idempoten')
            ?: $request->header('X-Idempotency-Key')
            ?: $request->header('Idempotency-Key')
            ?: $request->input('idempotency_key');

        $idempotencyKey = is_string($idempotencyKey) && trim($idempotencyKey) !== '' ? trim($idempotencyKey) : null;

        if ($idempotencyKey) {
            $existingOrder = Order::with('items')
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existingOrder) {
                return $this->jsonResponse(
                    'sukses',
                    200,
                    'Pesanan sudah diproses sebelumnya',
                    $existingOrder
                );
            }
        }

        $inputData = $request->all();
        if ($idempotencyKey !== null) {
            $inputData['idempotency_key'] = $idempotencyKey;
        }

        $validator = Validator::make($inputData, [
            'nama_penerima' => 'required|string|max:255',
            'alamat_penerima' => 'required|string|max:2000',
            'kurir_id' => ['required', Rule::exists('couriers', 'id')->where('aktif', true)],
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('aktif', true)],
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|distinct|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'tanggal_antar' => 'required|date_format:Y-m-d|after_or_equal:today',
            'idempotency_key' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Validasi gagal',
                null,
                $validator->errors()
            );
        }

        $customerId = $this->getCustomerId($request);
        $validated = $validator->validated();
        $tanggalAntar = Carbon::createFromFormat('Y-m-d', $validated['tanggal_antar'])->startOfDay();
        $isSameDay = $tanggalAntar->isSameDay(Carbon::today());

        try {
            $order = DB::transaction(function () use ($validated, $isSameDay, $idempotencyKey, $customerId) {
                $subtotal = 0;
                $orderItems = [];

                // Mengurutkan item berdasarkan product_id untuk mencegah deadlock pada transaksi bersamaan
                $items = collect($validated['items'])->sortBy('product_id')->values()->all();

                foreach ($items as $item) {
                    $product = Product::lockForUpdate()->find($item['product_id']);

                    if (! $product) {
                        abort($this->jsonResponse(
                            'gagal',
                            404,
                            'Produk tidak ditemukan'
                        ));
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
                            "Stok untuk produk '{$product->nama}' tidak mencukupi"
                        ));
                    }

                    if ($product->mudah_rusak && ! $isSameDay) {
                        abort($this->jsonResponse(
                            'gagal',
                            422,
                            "Produk '{$product->nama}' bersifat mudah rusak dan wajib dikirim pada hari yang sama"
                        ));
                    }

                    $itemSubtotal = $product->harga * $item['quantity'];
                    $subtotal += $itemSubtotal;
                    $product->stok -= $item['quantity'];

                    if ($product->stok <= 0) {
                        $product->tersedia = false;
                    }

                    $product->save();
                    $orderItems[] = [
                        'product_id' => $product->id,
                        'quantity' => $item['quantity'],
                        'harga_satuan' => $product->harga,
                        'subtotal' => $itemSubtotal,
                    ];
                }

                $kurir = Courier::where('id', $validated['kurir_id'])->where('aktif', true)->lockForUpdate()->first();
                if (! $kurir) {
                    abort($this->jsonResponse('gagal', 422, 'Kurir tidak tersedia atau tidak aktif'));
                }
                $ongkir = $kurir->tarif;

                $order = Order::create([
                    'customer_id'       => $customerId,
                    'nama_penerima'     => $validated['nama_penerima'],
                    'alamat_penerima'   => $validated['alamat_penerima'],
                    'kurir_id'          => $validated['kurir_id'],
                    'payment_method_id' => $validated['payment_method_id'],
                    'subtotal'          => $subtotal,
                    'ongkir'            => $ongkir,
                    'total_harga'       => $subtotal + $ongkir,
                    'status'            => 'menunggu_pembayaran',
                    'payment_status'    => 'belum_bayar',
                    'idempotency_key'   => $idempotencyKey,
                    'tanggal_antar'     => $validated['tanggal_antar'],
                ]);

                $order->items()->createMany($orderItems);

                // Sinkronisasi keranjang: Hapus item yang berhasil di-checkout dari tabel carts
                if (Schema::hasTable('carts')) {
                    $orderedProductIds = collect($orderItems)->pluck('product_id')->all();
                    Cart::where('customer_id', $customerId)
                        ->whereIn('product_id', $orderedProductIds)
                        ->delete();
                }

                return $order->load('items');
            });

            $customerId = $request->header('X-Pelanggan-Id') ?? '1';
            Cache::put("cart_user_{$customerId}", [], 86400);

            return $this->jsonResponse(
                'sukses',
                201,
                'Checkout berhasil diproses',
                $order
            );
        } catch (HttpResponseException $e) {
            return $e->getResponse();
        } catch (QueryException $e) {
            if ($idempotencyKey) {
                $existingOrder = Order::with('items')
                    ->where('idempotency_key', $idempotencyKey)
                    ->first();

                if ($existingOrder) {
                    return $this->jsonResponse(
                        'sukses',
                        200,
                        'Pesanan sudah diproses sebelumnya',
                        $existingOrder
                    );
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
}
