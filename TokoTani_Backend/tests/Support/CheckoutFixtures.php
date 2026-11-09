<?php

namespace Tests\Support;

use App\Models\Courier;
use App\Models\Keranjang;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Str;

trait CheckoutFixtures
{
    protected function createProduct(array $overrides = []): Product
    {
        return Product::create(array_merge([
            'nama' => 'Produk Uji '.Str::random(6),
            'harga' => 5000,
            'kategori' => 'Sayuran',
            'stok' => 10,
            'tersedia' => true,
            'deskripsi' => 'Produk untuk pengujian.',
            'satuan_jual' => 'ikat',
            'mudah_rusak' => false,
        ], $overrides));
    }

    protected function createCourier(array $overrides = []): Courier
    {
        return Courier::create(array_merge([
            'nama' => 'Kurir Uji '.Str::random(6),
            'wilayah' => '0-5 km',
            'tarif' => 10000,
            'aktif' => true,
        ], $overrides));
    }

    protected function createPaymentMethod(array $overrides = []): PaymentMethod
    {
        return PaymentMethod::create(array_merge([
            'nama' => 'Pembayaran Uji '.Str::random(6),
            'aktif' => true,
        ], $overrides));
    }

    protected function createPelanggan(array $overrides = []): User
    {
        return User::create(array_merge([
            'name' => 'Pelanggan Uji '.Str::random(6),
            'email' => 'pelanggan-'.Str::lower(Str::random(10)).'@tokotani.test',
            'password' => 'password',
        ], $overrides));
    }

    protected function addToCart(int $pelangganId, int $productId, int $jumlah): Keranjang
    {
        return Keranjang::create([
            'pelanggan_id' => $pelangganId,
            'product_id' => $productId,
            'jumlah' => $jumlah,
        ]);
    }

    protected function checkoutPayload(
        Product $product,
        Courier $courier,
        PaymentMethod $paymentMethod,
        ?string $deliveryDate = null,
        int $quantity = 1,
        string $slot = 'pagi'
    ): array {
        return [
            'nama_penerima' => 'Penerima Uji',
            'alamat_penerima' => 'Jl. Pengujian No. 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $paymentMethod->id,
            'tanggal_antar' => $deliveryDate ?? now()->toDateString(),
            'slot_pengantaran' => $slot,
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                ],
            ],
        ];
    }
}
