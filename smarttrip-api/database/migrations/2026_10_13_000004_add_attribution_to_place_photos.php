<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Photos picked from Openverse are Creative Commons works: the license
     * requires showing who made them, under which license, and where they
     * came from. All null for photos the admin uploads.
     */
    public function up(): void
    {
        Schema::table('place_photos', function (Blueprint $table) {
            $table->string('credit')->nullable();
            $table->string('license')->nullable();
            $table->string('license_url')->nullable();
            $table->string('source_url')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('place_photos', function (Blueprint $table) {
            $table->dropColumn(['credit', 'license', 'license_url', 'source_url']);
        });
    }
};
