<?php

namespace App\Http\Controllers;

use App\Models\Courier;
use App\Models\Order;
use App\Models\PaymentMethod;
use App\Models\Product;
use Carbon\Carbon;
use Illuminate\Database\QueryException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
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
            'status' => 'required|string|in:menunggu_pembayaran,dibayar,diproses,dikirim,selesai,dibatalkan',
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

        $validated = $validator->validated();
        $tanggalAntar = Carbon::createFromFormat('Y-m-d', $validated['tanggal_antar'])->startOfDay();
        $isSameDay = $tanggalAntar->isSameDay(Carbon::today());

        try {
            $order = DB::transaction(function () use ($validated, $isSameDay, $idempotencyKey) {
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
                    'nama_penerima' => $validated['nama_penerima'],
                    'alamat_penerima' => $validated['alamat_penerima'],
                    'kurir_id' => $validated['kurir_id'],
                    'payment_method_id' => $validated['payment_method_id'],
                    'subtotal' => $subtotal,
                    'ongkir' => $ongkir,
                    'total_harga' => $subtotal + $ongkir,
                    'status' => 'menunggu_pembayaran',
                    'idempotency_key' => $idempotencyKey,
                    'tanggal_antar' => $validated['tanggal_antar'],
                ]);

                $order->items()->createMany($orderItems);

                return $order->load('items');
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
