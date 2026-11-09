<?php

namespace App\Http\Controllers;

use App\Models\Cart;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CartController extends Controller
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
            'errors'  => $errors,
        ];

        return response()->json($response, (int) $code);
    }

    private function getCustomerId(Request $request): int
    {
        $id = $request->header('X-Pelanggan-Id')
            ?: $request->header('X-Customer-Id')
            ?: $request->input('customer_id');

        return (int) ($id ?: 1);
    }

    public function index(Request $request)
    {
        $customerId = $this->getCustomerId($request);

        $carts = Cart::with('product')
            ->where('customer_id', $customerId)
            ->get();

        $subtotal = 0;
        $items = [];

        foreach ($carts as $cart) {
            $product = $cart->product;
            if (!$product) {
                continue;
            }

            $itemSubtotal = $product->harga * $cart->quantity;
            $subtotal += $itemSubtotal;

            $items[] = [
                'id'          => $cart->id,
                'customer_id' => $cart->customer_id,
                'produk_id'   => $product->id,
                'nama'        => $product->nama,
                'harga'       => $product->harga,
                'jumlah'      => $cart->quantity,
                'stok'        => $product->stok,
                'satuan_jual' => $product->satuan_jual,
                'mudah_rusak' => (bool) $product->mudah_rusak,
                'foto'        => null,
                'subtotal'    => $itemSubtotal,
                'produk'      => [
                    'id'          => $product->id,
                    'nama'        => $product->nama,
                    'harga'       => $product->harga,
                    'kategori'    => $product->kategori,
                    'stok'        => $product->stok,
                    'tersedia'    => (bool) $product->tersedia,
                    'deskripsi'   => $product->deskripsi,
                    'satuan_jual' => $product->satuan_jual,
                    'mudah_rusak' => (bool) $product->mudah_rusak,
                ],
            ];
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
        $customerId = $this->getCustomerId($request);

        // Menerima baik produk_id maupun product_id, jumlah maupun quantity
        $productId = $request->input('produk_id', $request->input('product_id'));
        $quantity  = $request->input('jumlah', $request->input('quantity', 1));

        $validator = Validator::make([
            'product_id' => $productId,
            'quantity'   => $quantity,
        ], [
            'product_id' => 'required|integer|exists:products,id',
            'quantity'   => 'required|integer|min:1',
        ], [
            'product_id.required' => 'ID produk wajib diisi.',
            'product_id.exists'   => 'Produk tidak ditemukan.',
            'quantity.required'   => 'Jumlah wajib diisi.',
            'quantity.min'        => 'Jumlah minimal 1.',
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

        $product = Product::find($productId);

        if (!$product->tersedia || $product->stok <= 0) {
            return $this->jsonResponse(
                'gagal',
                409,
                "Produk {$product->nama} saat ini tidak tersedia atau stok habis."
            );
        }

        $existing = Cart::where('customer_id', $customerId)
            ->where('product_id', $productId)
            ->first();

        $desiredQty = $existing ? ($existing->quantity + (int) $quantity) : (int) $quantity;

        if ($desiredQty > $product->stok) {
            return $this->jsonResponse(
                'gagal',
                409,
                "Stok untuk '{$product->nama}' tidak mencukupi (tersedia: {$product->stok})."
            );
        }

        if ($existing) {
            $existing->update(['quantity' => $desiredQty]);
            $cart = $existing;
        } else {
            $cart = Cart::create([
                'customer_id' => $customerId,
                'product_id'  => $productId,
                'quantity'    => $desiredQty,
            ]);
        }

        $cart->load('product');

        return $this->jsonResponse(
            'sukses',
            201,
            'Produk berhasil ditambahkan ke keranjang',
            [
                'id'        => $cart->id,
                'produk_id' => $cart->product_id,
                'jumlah'    => $cart->quantity,
                'produk'    => $cart->product,
            ]
        );
    }

    public function update(Request $request, $id)
    {
        $customerId = $this->getCustomerId($request);
        $quantity = $request->input('jumlah', $request->input('quantity'));

        if ($quantity === null) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Jumlah wajib diisi',
                null,
                ['jumlah' => ['Kolom jumlah wajib diisi.']]
            );
        }

        $intQty = (int) $quantity;
        if ($intQty <= 0) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Jumlah item keranjang harus minimal 1',
                null,
                ['jumlah' => ['Jumlah item keranjang harus minimal 1.']]
            );
        }

        $cart = Cart::with('product')
            ->where('id', $id)
            ->where('customer_id', $customerId)
            ->first();

        if (!$cart) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Item keranjang tidak ditemukan'
            );
        }

        $product = $cart->product;
        if (!$product || $intQty > $product->stok) {
            $stokTersedia = $product ? $product->stok : 0;
            return $this->jsonResponse(
                'gagal',
                409,
                "Stok untuk '{$cart->product?->nama}' tidak mencukupi (tersedia: {$stokTersedia})."
            );
        }

        $cart->update(['quantity' => $intQty]);

        return $this->jsonResponse(
            'sukses',
            200,
            'Jumlah item keranjang berhasil diperbarui',
            [
                'id'        => $cart->id,
                'produk_id' => $cart->product_id,
                'jumlah'    => $cart->quantity,
            ]
        );
    }

    public function destroy(Request $request, $id)
    {
        $customerId = $this->getCustomerId($request);

        $cart = Cart::where('id', $id)
            ->where('customer_id', $customerId)
            ->first();

        if (!$cart) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Item keranjang tidak ditemukan'
            );
        }

        $cart->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Item keranjang berhasil dihapus'
        );
    }

    public function clear(Request $request)
    {
        $customerId = $this->getCustomerId($request);

        Cart::where('customer_id', $customerId)->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Keranjang belanja berhasil dikosongkan'
        );
    }
}

