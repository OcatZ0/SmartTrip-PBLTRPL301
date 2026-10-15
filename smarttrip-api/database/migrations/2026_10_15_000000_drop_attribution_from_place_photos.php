<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Photo credit and license are no longer stored or shown in the app.
     */
    public function up(): void
    {
        Schema::table('place_photos', function (Blueprint $table) {
            $table->dropColumn(['credit', 'license', 'license_url', 'source_url']);
        });
    }

    public function down(): void
    {
        Schema::table('place_photos', function (Blueprint $table) {
            $table->string('credit')->nullable();
            $table->string('license')->nullable();
            $table->string('license_url')->nullable();
            $table->string('source_url')->nullable();
        });
    }
};
