<?php

namespace App\Models;

use Spatie\Activitylog\Models\Activity as SpatieActivity;

/**
 * activity_log has no updated_at (an entry is never edited); set as
 * activitylog.activity_model so the package stops writing it.
 */
class Activity extends SpatieActivity
{
    public const UPDATED_AT = null;
}
