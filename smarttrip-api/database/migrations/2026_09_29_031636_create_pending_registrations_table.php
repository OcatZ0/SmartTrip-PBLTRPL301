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
        // Holds a not-yet-confirmed registration/account-link request until
        // its email verification link is clicked (see AuthController).
        // Keyed by email like Laravel's own password_reset_tokens table.
        Schema::create('pending_registrations', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('name');
            $table->string('password');
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pending_registrations');
    }
};
