<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * F015+F016 (docs/prd design spec Section 9 & 12) - Trip Viewer.
 * F015 (sisi pemilik): undang by email, list/cabut viewer, generate/
 * matikan link undangan (viewer_invite_token). F016 (sisi penerima):
 * klaim akses lewat link (join()) - daftar "Dibagikan ke Saya"
 * (GET /api/trips/shared) ada di TripController::shared().
 */
class TripViewerController extends Controller
{
    public function index(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $viewers = $trip->viewers()->select('users.users_id', 'name', 'email')->get();

        return response()->json([
            'data' => $viewers->map(fn ($viewer) => [
                'users_id' => $viewer->users_id,
                'name' => $viewer->name,
                'email' => $viewer->email,
                'added_at' => $viewer->pivot->added_at,
            ])->values(),
        ]);
    }

    /**
     * US16: cuma jalan buat user yang sudah terdaftar - email yang tidak
     * ketemu ditolak dengan pesan jelas, bukan diam-diam diabaikan.
     * Mengundang orang yang sudah jadi viewer = no-op (idempotent, bukan
     * error), sama seperti pola tambah wishlist duplikat (F007).
     */
    public function store(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $invitee = User::whereNull('deleted_at')->where('email', $data['email'])->first();

        if (! $invitee) {
            return response()->json([
                'message' => 'Tidak ada user terdaftar dengan email ini.',
                'errors' => ['email' => ['Tidak ada user terdaftar dengan email ini.']],
            ], 422);
        }

        if ($invitee->users_id === $request->user()->users_id) {
            return response()->json([
                'message' => 'Tidak bisa mengundang diri sendiri sebagai viewer.',
                'errors' => ['email' => ['Tidak bisa mengundang diri sendiri sebagai viewer.']],
            ], 422);
        }

        if (! $trip->viewers()->where('users.users_id', $invitee->users_id)->exists()) {
            $trip->viewers()->attach($invitee->users_id, ['added_at' => now()]);
        }

        return response()->json([
            'users_id' => $invitee->users_id,
            'name' => $invitee->name,
            'email' => $invitee->email,
        ], 201);
    }

    public function destroy(Request $request, Trip $trip, int $viewer)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if (! $trip->viewers()->where('users.users_id', $viewer)->exists()) {
            abort(404);
        }

        $trip->viewers()->detach($viewer);

        return response()->json(['message' => 'Akses viewer dicabut.']);
    }

    /**
     * Idempotent seperti share_token (Section 10) - link yang sama terus
     * dipakai sampai sengaja di-reset, bukan generate ulang tiap tap.
     */
    public function storeInviteLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($trip->viewer_invite_token === null) {
            $trip->update(['viewer_invite_token' => $this->generateUniqueToken()]);
        }

        return response()->json(['viewer_invite_token' => $trip->viewer_invite_token]);
    }

    /**
     * Cuma menutup jalur masuk baru - viewer yang sudah join lewat link
     * lama tetap punya akses, baris trip_viewers-nya tidak disentuh.
     */
    public function destroyInviteLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->update(['viewer_invite_token' => null]);

        return response()->json(['message' => 'Link undangan dimatikan.']);
    }

    private function generateUniqueToken(): string
    {
        do {
            $token = Str::random(32);
        } while (Trip::where('viewer_invite_token', $token)->exists());

        return $token;
    }

    /**
     * F016 - klaim akses viewer lewat link. Butuh login (beda dari Section
     * 10 yang anon) - route ini sudah di dalam grup auth:sanctum. Tidak ada
     * langkah accept/reject terpisah, begitu berhasil auth langsung masuk.
     */
    public function join(Request $request, string $viewerInviteToken)
    {
        $trip = Trip::where('viewer_invite_token', $viewerInviteToken)->first();

        if (! $trip) {
            abort(404);
        }

        $user = $request->user();

        if (! $trip->isOwnedBy($user) && ! $trip->viewers()->where('users.users_id', $user->users_id)->exists()) {
            $trip->viewers()->attach($user->users_id, ['added_at' => now()]);
        }

        $trip->load(['days' => fn ($dayQuery) => $dayQuery->orderBy('day_number'), 'days.items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order')]);

        return response()->json($trip);
    }
}
