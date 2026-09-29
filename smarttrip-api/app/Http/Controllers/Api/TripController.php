<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;

/**
 * Trip setup (docs/prd design spec Section 12). Minimal for now - just
 * enough to create/read a trip so F007 (wishlist) has something to
 * attach to. Weights/hotel/generate land with F008.
 */
class TripController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'num_days' => ['required', 'integer', 'min:1'],
            'budget_total' => ['required', 'integer', 'min:1'],
            'start_date' => ['required', 'date'],
            'daily_start_time' => ['nullable', 'date_format:H:i'],
            'daily_end_time' => ['nullable', 'date_format:H:i', 'after:daily_start_time'],
            'has_own_hotel' => ['sometimes', 'boolean'],
        ]);

        $trip = $request->user()->trips()->create([
            'title' => $data['title'] ?? 'Trip Batam',
            'num_days' => $data['num_days'],
            'budget_total' => $data['budget_total'],
            'start_date' => $data['start_date'],
            'has_own_hotel' => $data['has_own_hotel'] ?? false,
            ...array_filter([
                'daily_start_time' => $data['daily_start_time'] ?? null,
                'daily_end_time' => $data['daily_end_time'] ?? null,
            ]),
        ]);

        return response()->json($trip, 201);
    }

    public function show(Request $request, Trip $trip)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        return response()->json($trip);
    }
}
