<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * OpenStreetMap had no contact for any catalog place and an admin cannot
     * really confirm a phone number, so the app no longer keeps them; a
     * tourist who needs to call looks the place up themselves.
     */
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn(['phone', 'website']);
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->string('phone')->nullable();
            $table->string('website')->nullable();
        });
    }
};
