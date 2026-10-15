<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * estimated_cost_idr written by Gemini is a guess, so it stays marked
     * until an admin changes it.
     */
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->boolean('estimated_cost_is_ai')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('estimated_cost_is_ai');
        });
    }
};
