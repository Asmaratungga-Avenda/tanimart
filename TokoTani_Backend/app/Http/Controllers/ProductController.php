<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Schema;

class ProductController extends Controller
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

    public function categories()
    {
        if (Schema::hasTable('categories')) {
            $categories = \Illuminate\Support\Facades\DB::table('categories')->get();
        } else {
            $categories = Product::select('kategori')->distinct()->get()->pluck('kategori');
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar kategori berhasil diambil',
            $categories
        );
    }

    public function banners()
    {
        if (Schema::hasTable('banners')) {
            $banners = \App\Models\Banner::aktif()->get();
        } else {
            $banners = [];
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar banner promo berhasil diambil',
            $banners
        );
    }

    public function index(Request $request)
    {
        $query = Product::query();

        if ($request->has('kategori') && !empty($request->kategori)) {
            $query->where('kategori', $request->kategori);
        }

        if ($request->has('cari') && !empty($request->cari)) {
            $query->where('nama', 'like', '%' . $request->cari . '%');
        }

        $perPage = $request->integer('per_page', 15);
        $page = $request->integer('page', 1);

        $products = $query->paginate($perPage, ['*'], 'page', $page);

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar produk berhasil diambil',
            $products->items(),
            null,
            [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'total' => $products->total(),
                'per_page' => $products->perPage(),
            ]
        );
    }

    public function show($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Produk tidak ditemukan'
            );
        }

        return $this->jsonResponse(
            'sukses',
            200,
            'Rincian produk berhasil diambil',
            $product
        );
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nama'        => 'required|string|max:255',
            'harga'       => 'required|integer|min:0',
            'kategori'    => 'nullable|string',
            'category_id' => 'nullable|integer|exists:categories,id',
            'stok'        => 'required|integer|min:0',
            'tersedia'    => 'required|boolean',
            'deskripsi'   => 'nullable|string',
            'satuan_jual' => 'required|string',
            'mudah_rusak' => 'required|boolean',
            'gambar'      => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:4096',
        ]);

        if ($validator->fails()) {
            return $this->jsonResponse(
                'gagal',
                422,
                'Data yang dikirim tidak lengkap',
                null,
                $validator->errors()
            );
        }

        $validated = $validator->validated();
        
        // Default tersedia ke false jika stok <= 0
        if (isset($validated['stok']) && $validated['stok'] <= 0) {
            $validated['tersedia'] = false;
        }

        // Upload gambar menggunakan trait pada model Product
        if ($request->hasFile('gambar')) {
            $product = new Product();
            $validated['gambar'] = $product->uploadImage($request->file('gambar'), 'products');
        }

        // Auto-assign kategori dari ID jika kategori teks kosong
        if (empty($validated['kategori']) && !empty($validated['category_id'])) {
            $category = \App\Models\Category::find($validated['category_id']);
            if ($category) {
                $validated['kategori'] = $category->nama_kategori;
            }
        }

        $product = Product::create($validated);

        return $this->jsonResponse(
            'sukses',
            201,
            'Produk berhasil ditambahkan',
            $product
        );
    }

    public function update(Request $request, $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Produk tidak ditemukan'
            );
        }

        $validator = Validator::make($request->all(), [
            'nama'        => 'sometimes|required|string|max:255',
            'harga'       => 'sometimes|required|integer|min:0',
            'kategori'    => 'sometimes|nullable|string',
            'category_id' => 'sometimes|nullable|integer|exists:categories,id',
            'stok'        => 'sometimes|required|integer|min:0',
            'tersedia'    => 'sometimes|required|boolean',
            'deskripsi'   => 'sometimes|nullable|string',
            'satuan_jual' => 'sometimes|required|string',
            'mudah_rusak' => 'sometimes|required|boolean',
            'gambar'      => 'sometimes|nullable|image|mimes:jpeg,png,jpg,gif,webp|max:4096',
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
        
        if (isset($validated['stok']) && $validated['stok'] <= 0) {
            $validated['tersedia'] = false;
        }

        // Update gambar menggunakan trait (otomatis menghapus yang lama)
        if ($request->hasFile('gambar')) {
            $validated['gambar'] = $product->uploadImage($request->file('gambar'), 'products', $product->gambar);
        }

        if (array_key_exists('category_id', $validated) && empty($validated['kategori']) && !empty($validated['category_id'])) {
            $category = \App\Models\Category::find($validated['category_id']);
            if ($category) {
                $validated['kategori'] = $category->nama_kategori;
            }
        }

        $product->update($validated);

        return $this->jsonResponse(
            'sukses',
            200,
            'Produk berhasil diperbarui',
            $product
        );
    }

    public function destroy($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Produk tidak ditemukan'
            );
        }

        // Cek apakah produk sedang dalam pesanan aktif
        if (Schema::hasTable('order_items')) {
            $isUsedInActiveOrder = $product->orderItems()->whereHas('order', function ($query) {
                $query->whereNotIn('status', ['selesai', 'dibatalkan']);
            })->exists();

            if ($isUsedInActiveOrder) {
                return $this->jsonResponse(
                    'gagal',
                    409,
                    'Produk tidak dapat dihapus karena sedang dalam pesanan yang sedang diproses.'
                );
            }
        }

        // Hapus produk (event deleted pada model akan otomatis menghapus gambar dari storage)
        $product->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Produk berhasil dihapus'
        );
    }
}
