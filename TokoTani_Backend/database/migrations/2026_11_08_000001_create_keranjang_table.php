<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Database lokal lama mungkin sudah memiliki tabel keranjang dengan
        // nama kolom domain lama (user_id/produk_id). Selaraskan tanpa
        // menghapus data yang sudah ada.
        if (Schema::hasTable('keranjang')) {
            if (Schema::hasColumn('keranjang', 'user_id')
                && ! Schema::hasColumn('keranjang', 'pelanggan_id')) {
                Schema::table('keranjang', function (Blueprint $table) {
                    $table->renameColumn('user_id', 'pelanggan_id');
                });
            }

            if (Schema::hasColumn('keranjang', 'produk_id')
                && ! Schema::hasColumn('keranjang', 'product_id')) {
                Schema::table('keranjang', function (Blueprint $table) {
                    $table->renameColumn('produk_id', 'product_id');
                });
            }

            if (Schema::hasColumn('keranjang', 'catatan')) {
                Schema::table('keranjang', function (Blueprint $table) {
                    $table->dropColumn('catatan');
                });
            }

            return;
        }

        Schema::create('keranjang', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pelanggan_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->unsignedInteger('jumlah');
            $table->timestamps();

            // Satu pelanggan hanya boleh memiliki satu baris per produk.
            // Penambahan produk yang sama wajib memperbarui kolom jumlah.
            $table->unique(['pelanggan_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('keranjang');
    }
};
