<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // docs/prd design spec Section 4: admin-manageable (CRUD lewat
        // panel), bukan hardcode. Delete diproteksi ON DELETE RESTRICT
        // lewat FK dari place_category/trip_interest_category/
        // user_default_interest_category (dibuat belakangan).
        Schema::create('categories', function (Blueprint $table) {
            $table->id('categories_id');
            $table->string('name_id');
            $table->string('name_en');
            $table->string('slug')->unique();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
