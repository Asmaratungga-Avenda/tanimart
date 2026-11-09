<?php

namespace App\Http\Controllers;

use App\Models\Keranjang;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class KeranjangController extends Controller
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

    /**
     * Pelanggan diidentifikasi dari header X-Pelanggan-Id (kontrak frontend).
     * Nilai 1 dipakai sebagai fallback agar endpoint tetap dapat diuji tanpa login.
     */
    private function pelangganId(Request $request): int
    {
        if (auth()->check()) {
            return (int) auth()->id();
        }

        $id = $request->header('X-Pelanggan-Id')
            ?? $request->header('X-Customer-Id')
            ?? $request->input('pelanggan_id')
            ?? $request->query('pelanggan_id')
            ?? 1;

        $id = (int) $id;

        return $id > 0 ? $id : 1;
    }

    /**
     * Karena autentikasi belum menjadi bagian tugas ini, pastikan baris pelanggan
     * tersedia agar foreign key keranjang.pelanggan_id tetap valid.
     */
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

        if (! array_key_exists('produk_id', $data) && array_key_exists('product_id', $data)) {
            $data['produk_id'] = $data['product_id'];
        }

        if (! array_key_exists('jumlah', $data)) {
            if (array_key_exists('quantity', $data)) {
                $data['jumlah'] = $data['quantity'];
            } elseif (array_key_exists('qty', $data)) {
                $data['jumlah'] = $data['qty'];
            }
        }

        return $data;
    }

    private function presentItem(Keranjang $item): array
    {
        $product = $item->product;

        return [
            'id' => $item->id,
            'pelanggan_id' => $item->pelanggan_id,
            'produk_id' => $item->product_id,
            'product_id' => $item->product_id,
            'jumlah' => $item->jumlah,
            'subtotal' => $item->subtotal,
            'nama' => $product?->nama,
            'harga' => $product?->harga,
            'stok' => $product?->stok,
            'satuan_jual' => $product?->satuan_jual,
            'mudah_rusak' => (bool) ($product?->mudah_rusak ?? false),
            'produk' => $product,
        ];
    }

    public function index(Request $request)
    {
        $pelangganId = $this->pelangganId($request);

        $items = Keranjang::with('product')
            ->where('pelanggan_id', $pelangganId)
            ->orderBy('id')
            ->get();

        return $this->jsonResponse(
            'sukses',
            200,
            'Isi keranjang berhasil diambil',
            [
                'pelanggan_id' => $pelangganId,
                'items' => $items->map(fn (Keranjang $item) => $this->presentItem($item))->values(),
                'subtotal' => $items->sum(fn (Keranjang $item) => $item->subtotal),
                'jumlah_item' => $items->count(),
            ]
        );
    }

    public function store(Request $request)
    {
        $data = $this->normalizeInput($request);

        $validator = Validator::make($data, [
            'produk_id' => 'required|integer|exists:products,id',
            'jumlah' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Validasi keranjang gagal',
                null,
                $validator->errors()
            );
        }

        $pelangganId = $this->pelangganId($request);
        $this->ensurePelangganExists($pelangganId);

        try {
            [$item, $created] = DB::transaction(function () use ($data, $pelangganId) {
                $product = Product::lockForUpdate()->find($data['produk_id']);

                if (! $product) {
                    abort($this->jsonResponse('gagal', 404, 'Produk tidak ditemukan'));
                }

                if (! $product->tersedia || $product->stok <= 0) {
                    abort($this->jsonResponse(
                        'gagal',
                        409,
                        "Produk {$product->nama} sedang habis atau tidak tersedia"
                    ));
                }

                $existing = Keranjang::where('pelanggan_id', $pelangganId)
                    ->where('product_id', $product->id)
                    ->lockForUpdate()
                    ->first();

                $jumlahBaru = ($existing?->jumlah ?? 0) + (int) $data['jumlah'];

                if ($jumlahBaru > $product->stok) {
                    abort($this->jsonResponse(
                        'gagal',
                        409,
                        "Stok produk {$product->nama} tidak mencukupi. Sisa stok: {$product->stok}"
                    ));
                }

                if ($existing) {
                    $existing->jumlah = $jumlahBaru;
                    $existing->save();
                    $item = $existing;
                    $created = false;
                } else {
                    $item = Keranjang::create([
                        'pelanggan_id' => $pelangganId,
                        'product_id' => $product->id,
                        'jumlah' => $jumlahBaru,
                    ]);
                    $created = true;
                }

                return [$item->fresh('product'), $created];
            });
        } catch (HttpResponseException $e) {
            return $e->getResponse();
        } catch (QueryException $e) {
            // Penjaga terakhir bila dua request menambahkan produk yang sama bersamaan.
            report($e);

            return $this->jsonResponse(
                'gagal',
                409,
                'Keranjang sedang diperbarui oleh permintaan lain. Silakan coba lagi.'
            );
        }

        return $this->jsonResponse(
            'sukses',
            $created ? 201 : 200,
            $created
                ? 'Produk berhasil ditambahkan ke keranjang'
                : 'Jumlah produk di keranjang berhasil diperbarui',
            $this->presentItem($item)
        );
    }

    public function update(Request $request, $id)
    {
        $pelangganId = $this->pelangganId($request);

        $item = Keranjang::where('pelanggan_id', $pelangganId)->find($id);

        if (! $item) {
            return $this->jsonResponse('gagal', 404, 'Item keranjang tidak ditemukan');
        }

        $data = $this->normalizeInput($request);

        $validator = Validator::make($data, [
            'jumlah' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Jumlah item harus berupa bilangan bulat minimal 1',
                null,
                $validator->errors()
            );
        }

        try {
            $item = DB::transaction(function () use ($pelangganId, $id, $data, $item) {
                // Kunci produk lalu baris keranjang dengan urutan yang sama
                // seperti alur tambah dan checkout untuk mencegah deadlock.
                $product = Product::lockForUpdate()->find($item->product_id);

                if (! $product) {
                    abort($this->jsonResponse(
                        'gagal',
                        404,
                        'Produk pada keranjang tidak ditemukan'
                    ));
                }

                $lockedItem = Keranjang::where('pelanggan_id', $pelangganId)
                    ->whereKey($id)
                    ->lockForUpdate()
                    ->first();

                if (! $lockedItem) {
                    abort($this->jsonResponse('gagal', 404, 'Item keranjang tidak ditemukan'));
                }

                if (! $product->tersedia || $product->stok <= 0) {
                    abort($this->jsonResponse(
                        'gagal',
                        409,
                        'Produk pada keranjang sudah tidak tersedia'
                    ));
                }

                if ((int) $data['jumlah'] > $product->stok) {
                    abort($this->jsonResponse(
                        'gagal',
                        409,
                        "Stok produk {$product->nama} tidak mencukupi. Sisa stok: {$product->stok}"
                    ));
                }

                $lockedItem->jumlah = (int) $data['jumlah'];
                $lockedItem->save();

                return $lockedItem->fresh('product');
            });
        } catch (HttpResponseException $e) {
            return $e->getResponse();
        } catch (QueryException $e) {
            report($e);

            return $this->jsonResponse(
                'gagal',
                409,
                'Keranjang sedang diperbarui oleh permintaan lain. Silakan coba lagi.'
            );
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Jumlah item keranjang berhasil diperbarui',
            $this->presentItem($item)
        );
    }

    public function destroy(Request $request, $id)
    {
        $pelangganId = $this->pelangganId($request);

        $item = Keranjang::where('pelanggan_id', $pelangganId)->find($id);

        if (! $item) {
            return $this->jsonResponse('gagal', 404, 'Item keranjang tidak ditemukan');
        }

        $item->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Item berhasil dihapus dari keranjang',
            ['id' => (int) $id]
        );
    }

    public function clear(Request $request)
    {
        $pelangganId = $this->pelangganId($request);

        $dihapus = Keranjang::where('pelanggan_id', $pelangganId)->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Keranjang berhasil dikosongkan',
            ['dihapus' => $dihapus]
        );
    }
}
