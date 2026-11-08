<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('couriers', 'wilayah')) {
            return;
        }

        Schema::table('couriers', function (Blueprint $table) {
            $table->string('wilayah')->nullable()->after('nama');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('couriers', 'wilayah')) {
            return;
        }

        Schema::table('couriers', function (Blueprint $table) {
            $table->dropColumn('wilayah');
        });
    }
};
