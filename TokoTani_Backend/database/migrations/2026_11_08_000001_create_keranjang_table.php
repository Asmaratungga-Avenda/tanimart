<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
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
