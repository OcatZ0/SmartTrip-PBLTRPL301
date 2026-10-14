<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('icon_symbol')->nullable()->default('ombak')->after('slug');
            $table->string('subtitle_id')->nullable()->after('icon_symbol');
            $table->text('ai_keywords')->nullable()->after('subtitle_id');
            $table->string('visibility_onboarding')->nullable()->default('Tampil di A4')->after('ai_keywords');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn(['icon_symbol', 'subtitle_id', 'ai_keywords', 'visibility_onboarding']);
        });
    }
};
