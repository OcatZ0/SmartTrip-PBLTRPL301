<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * categories.visibility_onboarding was free text ("Tampil di A4"); whether a
 * category is offered in the mobile onboarding interest picker (A4) is a
 * yes/no, so it becomes a boolean. Existing values carry over: anything other
 * than an explicit "not shown" stays shown.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->boolean('show_in_onboarding')->default(true);
        });

        DB::table('categories')
            ->where('visibility_onboarding', 'Tidak tampil di A4')
            ->update(['show_in_onboarding' => false]);

        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('visibility_onboarding');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('visibility_onboarding')->nullable()->default('Tampil di A4');
        });

        DB::table('categories')
            ->where('show_in_onboarding', false)
            ->update(['visibility_onboarding' => 'Tidak tampil di A4']);

        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('show_in_onboarding');
        });
    }
};
