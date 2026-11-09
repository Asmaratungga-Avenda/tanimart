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
            if (! Schema::hasColumn('orders', 'pelanggan_id')) {
                $table->foreignId('pelanggan_id')
                    ->nullable()
                    ->after('id')
                    ->constrained('users')
                    ->nullOnDelete();
            }

            if (! Schema::hasColumn('orders', 'tanggal_pengantaran')) {
                $table->date('tanggal_pengantaran')->nullable()->after('tanggal_antar');
            }

            if (! Schema::hasColumn('orders', 'slot_pengantaran')) {
                $table->string('slot_pengantaran', 50)->nullable()->after('tanggal_pengantaran');
            }
        });

        if (Schema::hasColumn('orders', 'tanggal_pengantaran')
            && Schema::hasColumn('orders', 'tanggal_antar')) {
            // Data lama tetap dapat dibaca melalui tanggal_pengantaran.
            DB::table('orders')
                ->whereNull('tanggal_pengantaran')
                ->update(['tanggal_pengantaran' => DB::raw('tanggal_antar')]);
        }
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'pelanggan_id')) {
                $table->dropConstrainedForeignId('pelanggan_id');
            }

            $columns = array_values(array_filter([
                Schema::hasColumn('orders', 'tanggal_pengantaran') ? 'tanggal_pengantaran' : null,
                Schema::hasColumn('orders', 'slot_pengantaran') ? 'slot_pengantaran' : null,
            ]));

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
