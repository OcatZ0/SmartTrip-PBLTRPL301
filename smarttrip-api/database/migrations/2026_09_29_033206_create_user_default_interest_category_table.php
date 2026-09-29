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
        // docs/prd design spec Section 4: minat default level akun, sumber
        // pre-fill buat trip baru.
        Schema::create('user_default_interest_category', function (Blueprint $table) {
            $table->foreignId('users_id')->constrained('users', 'users_id')->cascadeOnDelete();
            $table->foreignId('categories_id')->constrained('categories', 'categories_id')->restrictOnDelete();
            $table->unique(['users_id', 'categories_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_default_interest_category');
    }
};
