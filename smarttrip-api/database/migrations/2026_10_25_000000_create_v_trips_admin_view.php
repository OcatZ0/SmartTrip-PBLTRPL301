<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

// Admin panel only needs trip volume and existence; share_token, viewer_invite_token,
// budget and weights stay out of reach of the admin database role (GRANT is per environment).
return new class extends Migration
{
    public function up(): void
    {
        $columns = 'trips_id, users_id, title, num_days, start_date, daily_start_time, daily_end_time, created_at, deleted_at';

        // OR REPLACE keeps the GRANTs already given on the view; sqlite (tests) has no OR REPLACE.
        if (DB::getDriverName() === 'sqlite') {
            DB::statement('DROP VIEW IF EXISTS v_trips_admin');
            DB::statement("CREATE VIEW v_trips_admin AS SELECT {$columns} FROM trips");

            return;
        }

        DB::statement("CREATE OR REPLACE VIEW v_trips_admin AS SELECT {$columns} FROM trips");
    }

    public function down(): void
    {
        DB::statement('DROP VIEW IF EXISTS v_trips_admin');
    }
};
