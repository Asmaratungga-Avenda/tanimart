<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentMethod;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ProductTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_products_and_filter_by_kategori_and_search(): void
    {
        Product::create([
            'nama' => 'Bayam Hijau',
            'harga' => 5000,
            'kategori' => 'Sayuran',
            'stok' => 10,
            'tersedia' => true,
            'deskripsi' => 'Segar',
            'satuan_jual' => 'ikat',
            'mudah_rusak' => true,
        ]);

        Product::create([
            'nama' => 'Beras Pandan Wangi',
            'harga' => 60000,
            'kategori' => 'Sembako',
            'stok' => 5,
            'tersedia' => true,
            'deskripsi' => 'Pulen',
            'satuan_jual' => 'kg',
            'mudah_rusak' => false,
        ]);

        // All products
        $resAll = $this->getJson('/api/produk')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');
        $this->assertCount(2, $resAll->json('data'));

        // Filter by kategori
        $resKat = $this->getJson('/api/produk?kategori=Sayuran')
            ->assertOk();
        $this->assertCount(1, $resKat->json('data'));
        $this->assertEquals('Bayam Hijau', $resKat->json('data.0.nama'));

        // Search by keyword
        $resSearch = $this->getJson('/api/produk?cari=Pandan')
            ->assertOk();
        $this->assertCount(1, $resSearch->json('data'));
        $this->assertEquals('Beras Pandan Wangi', $resSearch->json('data.0.nama'));
    }

    public function test_can_show_product_detail_and_returns_404_if_not_found(): void
    {
        $product = Product::create([
            'nama' => 'Kangkung',
            'harga' => 3000,
            'kategori' => 'Sayuran',
            'stok' => 15,
            'tersedia' => true,
            'satuan_jual' => 'ikat',
            'mudah_rusak' => true,
        ]);

        $this->getJson("/api/produk/{$product->id}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.nama', 'Kangkung');

        $this->getJson('/api/produk/9999')
            ->assertNotFound()
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '404');
    }

    public function test_can_create_and_update_product(): void
    {
        $payload = [
            'nama' => 'Cabai Rawit',
            'harga' => 25000,
            'kategori' => 'Sayuran',
            'stok' => 20,
            'tersedia' => true,
            'deskripsi' => 'Pedas',
            'satuan_jual' => 'kg',
            'mudah_rusak' => true,
        ];

        $resCreate = $this->postJson('/api/produk', $payload)
            ->assertCreated()
            ->assertJsonPath('status', 'sukses')
            ->assertJsonPath('data.nama', 'Cabai Rawit');

        $id = $resCreate->json('data.id');

        $this->putJson("/api/produk/{$id}", ['harga' => 27000])
            ->assertOk()
            ->assertJsonPath('data.harga', 27000);
    }

    public function test_delete_product_without_orders_succeeds(): void
    {
        $product = Product::create([
            'nama' => 'Produk Lepas',
            'harga' => 1000,
            'kategori' => 'Lainnya',
            'stok' => 10,
            'tersedia' => true,
            'satuan_jual' => 'pcs',
            'mudah_rusak' => false,
        ]);

        $this->deleteJson("/api/produk/{$product->id}")
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertDatabaseMissing('products', ['id' => $product->id]);
    }

    public function test_delete_product_used_in_active_order_returns_409(): void
    {
        $product = Product::create([
            'nama' => 'Produk Terpakai',
            'harga' => 10000,
            'kategori' => 'Sayuran',
            'stok' => 5,
            'tersedia' => true,
            'satuan_jual' => 'kg',
            'mudah_rusak' => true,
        ]);

        $courier = Courier::create(['nama' => 'Kurir A', 'tarif' => 5000]);
        $payment = PaymentMethod::create(['nama' => 'Tunai']);

        $order = Order::create([
            'nama_penerima' => 'Pembeli',
            'alamat_penerima' => 'Alamat',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 10000,
            'ongkir' => 5000,
            'total_harga' => 15000,
            'status' => 'menunggu_pembayaran',
            'tanggal_antar' => now()->toDateString(),
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => 1,
            'harga_satuan' => 10000,
            'subtotal' => 10000,
        ]);

        // Attempting to delete should return 409 Conflict
        $this->deleteJson("/api/produk/{$product->id}")
            ->assertStatus(409)
            ->assertJsonPath('status', 'gagal')
            ->assertJsonPath('code', '409');

        $this->assertDatabaseHas('products', ['id' => $product->id]);
    }

    public function test_can_fetch_categories(): void
    {
        DB::table('categories')->insert([
            ['nama_kategori' => 'Sayuran', 'created_at' => now(), 'updated_at' => now()],
            ['nama_kategori' => 'Sembako', 'created_at' => now(), 'updated_at' => now()],
        ]);

        $response = $this->getJson('/api/kategori')
            ->assertOk()
            ->assertJsonPath('status', 'sukses');

        $this->assertCount(2, $response->json('data'));
    }
}

