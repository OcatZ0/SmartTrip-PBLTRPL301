<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscoveryRun extends Model
{
    protected $primaryKey = 'discovery_runs_id';

    protected $fillable = [
        'users_id',
        'status',
        'total_steps',
        'done_steps',
        'current_step',
        'inserted',
        'skipped',
        'failed_steps',
        'log',
        'error',
        'started_at',
        'finished_at',
    ];

    protected function casts(): array
    {
        return [
            'log' => 'array',
            'started_at' => 'datetime',
            'finished_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'users_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereIn('status', ['queued', 'running']);
    }

    public function isActive(): bool
    {
        return in_array($this->status, ['queued', 'running'], true);
    }
}
