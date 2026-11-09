<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('payment_status')->nullable()->after('status');
            $table->timestamp('dikirim_at')->nullable()->after('tanggal_antar');
            $table->timestamp('tiba_at')->nullable()->after('dikirim_at');
            $table->timestamp('selesai_at')->nullable()->after('tiba_at');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['payment_status', 'dikirim_at', 'tiba_at', 'selesai_at']);
        });
    }
};
