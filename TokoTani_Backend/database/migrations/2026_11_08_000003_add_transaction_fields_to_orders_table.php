<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('pelanggan_id')
                ->nullable()
                ->after('id')
                ->constrained('users')
                ->nullOnDelete();
            $table->date('tanggal_pengantaran')->nullable()->after('tanggal_antar');
            $table->string('slot_pengantaran', 50)->nullable()->after('tanggal_pengantaran');
        });

        // Data lama tetap dapat dibaca melalui tanggal_pengantaran.
        DB::table('orders')
            ->whereNull('tanggal_pengantaran')
            ->update(['tanggal_pengantaran' => DB::raw('tanggal_antar')]);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('pelanggan_id');
            $table->dropColumn(['tanggal_pengantaran', 'slot_pengantaran']);
        });
    }
};
