<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('couriers', 'deleted_at')) {
            return;
        }

        Schema::table('couriers', function (Blueprint $table) {
            $table->softDeletes()->after('aktif');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('couriers', 'deleted_at')) {
            return;
        }

        Schema::table('couriers', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
