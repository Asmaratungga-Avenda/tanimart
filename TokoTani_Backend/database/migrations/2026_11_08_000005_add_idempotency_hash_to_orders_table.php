<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('orders', 'idempotency_request_hash')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->string('idempotency_request_hash', 64)
                ->nullable()
                ->after('idempotency_key');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('orders', 'idempotency_request_hash')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('idempotency_request_hash');
        });
    }
};
