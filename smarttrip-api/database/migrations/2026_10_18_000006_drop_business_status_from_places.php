<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Geoapify has no business status and nothing could set
     * closed_temporarily, so every place was operational. A permanently
     * closed place is now deleted from the catalog instead, which hides it
     * the same way and keeps Discovery from bringing it back.
     */
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('business_status');
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->enum('business_status', ['operational', 'closed_temporarily', 'closed_permanently'])->default('operational');
        });
    }
};
