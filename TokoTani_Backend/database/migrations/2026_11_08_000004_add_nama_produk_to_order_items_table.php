<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('order_items', 'nama_produk')) {
            Schema::table('order_items', function (Blueprint $table) {
                $table->string('nama_produk')->nullable()->after('product_id');
            });
        }

        // Isi snapshot nama produk untuk baris lama tanpa mengubah harga transaksi.
        DB::table('order_items')
            ->whereNull('nama_produk')
            ->get(['id', 'product_id'])
            ->each(function ($item): void {
                $nama = DB::table('products')->where('id', $item->product_id)->value('nama');

                if ($nama !== null) {
                    DB::table('order_items')
                        ->where('id', $item->id)
                        ->update(['nama_produk' => $nama]);
                }
            });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('order_items', 'nama_produk')) {
            return;
        }

        Schema::table('order_items', function (Blueprint $table) {
            $table->dropColumn('nama_produk');
        });
    }
};
