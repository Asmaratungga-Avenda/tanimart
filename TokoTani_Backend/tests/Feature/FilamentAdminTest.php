<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\AuthenticatedApiRequests;
use Tests\TestCase;

class FilamentAdminTest extends TestCase
{
    use RefreshDatabase;
    use AuthenticatedApiRequests;

    public function test_admin_login_page_can_be_rendered(): void
    {
        $response = $this->get('/admin/login');

        $response->assertSuccessful();
    }

    public function test_authenticated_user_can_access_filament_dashboard(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($user)->get('/admin');

        $response->assertSuccessful();
    }

    public function test_authenticated_user_can_access_filament_resources(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $this->actingAs($user)->get('/admin/products')->assertSuccessful();
        $this->actingAs($user)->get('/admin/categories')->assertSuccessful();
        $this->actingAs($user)->get('/admin/orders')->assertSuccessful();
        $this->actingAs($user)->get('/admin/banners')->assertSuccessful();
        $this->actingAs($user)->get('/admin/couriers')->assertSuccessful();
        $this->actingAs($user)->get('/admin/payment-methods')->assertSuccessful();
        $this->actingAs($user)->get('/admin/users')->assertSuccessful();
    }

    public function test_order_view_page_renders_with_items_relation(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $product = Product::create([
            'nama' => 'Cabai Merah',
            'harga' => 30000,
            'kategori' => 'Sayuran',
            'stok' => 10,
            'tersedia' => true,
            'satuan_jual' => 'kg',
            'mudah_rusak' => true,
        ]);
        $courier = Courier::create(['nama' => 'Kurir Express', 'tarif' => 15000]);
        $payment = PaymentMethod::create(['nama' => 'Transfer Bank']);

        $order = Order::create([
            'nama_penerima' => 'Siti Aminah',
            'alamat_penerima' => 'Jl. Pahlawan No. 5',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 60000,
            'ongkir' => 15000,
            'total_harga' => 75000,
            'status' => 'menunggu_pembayaran',
            'tanggal_antar' => now()->toDateString(),
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => 2,
            'harga_satuan' => 30000,
            'subtotal' => 60000,
        ]);

        $response = $this->actingAs($user)->get("/admin/orders/{$order->id}");

        $response->assertSuccessful();
    }

    public function test_cancelling_order_restores_product_stock_automatically(): void
    {
        $product = Product::create([
            'nama' => 'Tomat Ceri',
            'harga' => 15000,
            'kategori' => 'Sayuran',
            'stok' => 5, // sisa 5 setelah checkout 3
            'tersedia' => true,
            'satuan_jual' => 'kg',
            'mudah_rusak' => true,
        ]);
        $courier = Courier::create(['nama' => 'Kurir Toko', 'tarif' => 10000]);
        $payment = PaymentMethod::create(['nama' => 'Tunai']);

        $order = Order::create([
            'nama_penerima' => 'Budi',
            'alamat_penerima' => 'Alamat',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 45000,
            'ongkir' => 10000,
            'total_harga' => 55000,
            'status' => 'menunggu_pembayaran',
            'tanggal_antar' => now()->toDateString(),
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => 3,
            'harga_satuan' => 15000,
            'subtotal' => 45000,
        ]);

        // Admin membatalkan pesanan di Filament
        $order->status = 'dibatalkan';
        $order->save();

        // Stok tomat harus otomatis kembali 5 + 3 = 8
        $this->assertEquals(8, $product->fresh()->stok);
    }

    public function test_product_stock_zero_automatically_sets_tersedia_false(): void
    {
        $product = Product::create([
            'nama' => 'Bawang Putih',
            'harga' => 20000,
            'kategori' => 'Bumbu',
            'stok' => 0,
            'tersedia' => true, // diset true
            'satuan_jual' => 'kg',
            'mudah_rusak' => false,
        ]);

        // Karena stok 0, hook booted saving harus otomatis memaksa tersedia = false
        $this->assertFalse($product->fresh()->tersedia);
    }

    public function test_unpaid_order_cannot_be_shipped(): void
    {
        $courier = Courier::create(['nama' => 'JNE', 'tarif' => 10000]);
        $payment = PaymentMethod::create(['nama' => 'Transfer']);

        $order = Order::create([
            'nama_penerima' => 'Ahmad',
            'alamat_penerima' => 'Jl. Mawar 1',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 20000,
            'ongkir' => 10000,
            'total_harga' => 30000,
            'status' => 'menunggu_pembayaran',
            'payment_status' => 'belum_bayar',
            'tanggal_antar' => now()->toDateString(),
        ]);

        $response = $this->withHeader('X-Role', 'admin')->postJson("/api/pesanan/{$order->id}/kirim");

        $response->assertStatus(409);
    }

    public function test_shipping_order_workflow_with_delivery_simulation(): void
    {
        \Illuminate\Support\Facades\Queue::fake();

        $courier = Courier::create(['nama' => 'JNE Express', 'tarif' => 10000]);
        $payment = PaymentMethod::create(['nama' => 'QRIS']);

        $order = Order::create([
            'customer_id' => 1,
            'nama_penerima' => 'Budi',
            'alamat_penerima' => 'Jl. Delima',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 25000,
            'ongkir' => 10000,
            'total_harga' => 35000,
            'status' => 'diproses',
            'payment_status' => 'lunas',
            'tanggal_antar' => now()->toDateString(),
        ]);

        $response = $this->withHeader('X-Role', 'admin')->postJson("/api/pesanan/{$order->id}/kirim");
        $response->assertOk();

        $this->assertEquals('dikirim', $order->fresh()->status);
        $this->assertNotNull($order->fresh()->dikirim_at);

        \Illuminate\Support\Facades\Queue::assertPushed(\App\Jobs\DeliverOrderSimulation::class);
    }

    public function test_customer_can_complete_order_when_status_is_tiba(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $this->authenticateAs($customer);

        $courier = Courier::create(['nama' => 'JNE Speed', 'tarif' => 10000]);
        $payment = PaymentMethod::create(['nama' => 'QRIS Pay']);

        $order = Order::create([
            'customer_id' => $customer->id,
            'pelanggan_id' => $customer->id,
            'nama_penerima' => 'Budi',
            'alamat_penerima' => 'Jl. Delima',
            'kurir_id' => $courier->id,
            'payment_method_id' => $payment->id,
            'subtotal' => 25000,
            'ongkir' => 10000,
            'total_harga' => 35000,
            'status' => 'tiba',
            'payment_status' => 'lunas',
            'tanggal_antar' => now()->toDateString(),
        ]);

        $response = $this->postJson("/api/pesanan/{$order->id}/selesai");
        $response->assertOk();

        $this->assertEquals('selesai', $order->fresh()->status);
        $this->assertNotNull($order->fresh()->selesai_at);
    }
}
