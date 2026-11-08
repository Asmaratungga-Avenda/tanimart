<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;

class CartController extends Controller
{
    private function jsonResponse($status, $code, $message, $data = null, $errors = null)
    {
        $response = [
            'status'  => $status,
            'code'    => (string) $code,
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

    private function getCartKey(Request $request): string
    {
        $customerId = $request->header('X-Pelanggan-Id') ?? '1';
        return "cart_user_{$customerId}";
    }

    private function getCartItems(Request $request): array
    {
        $key = $this->getCartKey($request);
        $items = Cache::get($key, null);
        if ($items === null) {
            // Seed initial items from available products if cache empty
            $p1 = Product::find(1);
            $p2 = Product::find(2);
            $items = [];
            if ($p1 && $p1->stok >= 2) {
                $items[] = [
                    'id'          => 101,
                    'produk_id'   => $p1->id,
                    'nama'        => $p1->nama,
                    'harga'       => $p1->harga,
                    'jumlah'      => 2,
                    'stok'        => $p1->stok,
                    'satuan_jual' => $p1->satuan_jual,
                    'mudah_rusak' => (bool) $p1->mudah_rusak,
                    'foto'        => $p1->foto,
                ];
            }
            if ($p2 && $p2->stok >= 1) {
                $items[] = [
                    'id'          => 102,
                    'produk_id'   => $p2->id,
                    'nama'        => $p2->nama,
                    'harga'       => $p2->harga,
                    'jumlah'      => 1,
                    'stok'        => $p2->stok,
                    'satuan_jual' => $p2->satuan_jual,
                    'mudah_rusak' => (bool) $p2->mudah_rusak,
                    'foto'        => $p2->foto,
                ];
            }
            Cache::put($key, $items, now()->addDays(7));
        }
        return $items;
    }

    private function saveCartItems(Request $request, array $items): void
    {
        $key = $this->getCartKey($request);
        Cache::put($key, $items, now()->addDays(7));
    }

    public function index(Request $request)
    {
        $items = $this->getCartItems($request);
        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += ($item['harga'] * $item['jumlah']);
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Isi keranjang belanja berhasil diambil',
            [
                'items'    => $items,
                'subtotal' => $subtotal,
            ]
        );
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'produk_id' => 'required|integer|exists:products,id',
            'jumlah'    => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse('gagal', 422, 'Validasi gagal', null, $validator->errors());
        }

        $product = Product::find($request->input('produk_id'));
        if (!$product || !$product->tersedia || $product->stok <= 0) {
            return $this->jsonResponse('gagal', 409, "Produk {$product->nama} habis atau tidak tersedia");
        }

        $items = $this->getCartItems($request);
        $found = false;
        $qtyToAdd = (int) $request->input('jumlah');

        foreach ($items as &$item) {
            if ($item['produk_id'] == $product->id) {
                $newQty = $item['jumlah'] + $qtyToAdd;
                if ($newQty > $product->stok) {
                    return $this->jsonResponse(
                        'gagal',
                        409,
                        "Stok tidak mencukupi untuk {$product->nama}. Stok tersedia: {$product->stok} {$product->satuan_jual}"
                    );
                }
                $item['jumlah'] = $newQty;
                $found = true;
                break;
            }
        }
        unset($item);

        if (!$found) {
            if ($qtyToAdd > $product->stok) {
                return $this->jsonResponse(
                    'gagal',
                    409,
                    "Stok tidak mencukupi untuk {$product->nama}. Stok tersedia: {$product->stok} {$product->satuan_jual}"
                );
            }
            $items[] = [
                'id'          => time() + rand(100, 999),
                'produk_id'   => $product->id,
                'nama'        => $product->nama,
                'harga'       => $product->harga,
                'jumlah'      => $qtyToAdd,
                'stok'        => $product->stok,
                'satuan_jual' => $product->satuan_jual,
                'mudah_rusak' => (bool) $product->mudah_rusak,
                'foto'        => $product->foto,
            ];
        }

        $this->saveCartItems($request, $items);

        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += ($item['harga'] * $item['jumlah']);
        }

        return $this->jsonResponse(
            'sukses',
            201,
            'Produk berhasil ditambahkan ke keranjang',
            [
                'items'    => $items,
                'subtotal' => $subtotal,
            ]
        );
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'jumlah' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse('gagal', 422, 'Validasi gagal', null, $validator->errors());
        }

        $newQty = (int) $request->input('jumlah');
        if ($newQty <= 0) {
            return $this->jsonResponse('gagal', 422, 'Jumlah barang harus minimal 1');
        }

        $items = $this->getCartItems($request);
        $found = false;

        foreach ($items as &$item) {
            if ($item['id'] == $id) {
                $product = Product::find($item['produk_id']);
                $maxStock = $product ? $product->stok : $item['stok'];

                if ($newQty > $maxStock) {
                    return $this->jsonResponse(
                        'gagal',
                        409,
                        "Stok tidak mencukupi untuk {$item['nama']}! Tersedia hanya {$maxStock} {$item['satuan_jual']}."
                    );
                }

                $item['jumlah'] = $newQty;
                $found = true;
                break;
            }
        }
        unset($item);

        if (!$found) {
            return $this->jsonResponse('gagal', 404, 'Item keranjang tidak ditemukan');
        }

        $this->saveCartItems($request, $items);

        return $this->jsonResponse('sukses', 200, 'Jumlah item keranjang berhasil diperbarui');
    }

    public function destroy(Request $request, $id)
    {
        $items = $this->getCartItems($request);
        $newItems = array_values(array_filter($items, function ($item) use ($id) {
            return $item['id'] != $id;
        }));

        $this->saveCartItems($request, $newItems);

        return $this->jsonResponse('sukses', 200, 'Item keranjang berhasil dihapus');
    }

    public function clear(Request $request)
    {
        $this->saveCartItems($request, []);
        return $this->jsonResponse('sukses', 200, 'Keranjang berhasil dikosongkan');
    }
}

