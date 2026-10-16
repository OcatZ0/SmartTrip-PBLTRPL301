<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The "Perkiraan AI" mark on places.estimated_cost_idr is dropped: an AI
 * estimate the admin accepts (or leaves in place) is the admin's decision,
 * so the cost is treated the same whoever filled it in.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('estimated_cost_is_ai');
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->boolean('estimated_cost_is_ai')->default(false);
        });
    }
};
