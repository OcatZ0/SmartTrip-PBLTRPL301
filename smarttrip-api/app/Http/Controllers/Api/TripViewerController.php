<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Knuckles\Scribe\Attributes\Endpoint;
use Knuckles\Scribe\Attributes\Group;

/**
 * F015+F016 (docs/prd design spec Section 9 & 12) - Trip Viewer.
 * F015 (sisi pemilik): undang by email, list/cabut viewer, generate/
 * matikan link undangan (viewer_invite_token). F016 (sisi penerima):
 * klaim akses lewat link (join()) - daftar "Dibagikan ke Saya"
 * (GET /api/trips/shared) ada di TripController::shared().
 */
#[Group('Berbagi Trip', 'Undang viewer lewat email atau link. Viewer hanya bisa melihat, tidak bisa mengubah.')]
class TripViewerController extends Controller
{
    #[Endpoint('Daftar viewer', 'Hanya pemilik trip.')]
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
    #[Endpoint('Undang viewer lewat email', 'Email harus milik pengguna terdaftar.')]
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

    #[Endpoint('Cabut akses viewer', 'Hanya pemilik trip.')]
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
     * Idempotent (Section 10) - link yang sama terus
     * dipakai sampai sengaja di-reset, bukan generate ulang tiap tap.
     */
    #[Endpoint('Buat link undangan', 'Link yang sama dipakai terus sampai dimatikan.')]
    public function storeInviteLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($trip->viewer_invite_token === null) {
            // 40 random characters never collide in practice; the unique index
            // still guards the column.
            $trip->update(['viewer_invite_token' => Str::random(40)]);
        }

        return response()->json(['viewer_invite_token' => $trip->viewer_invite_token]);
    }

    /**
     * Cuma menutup jalur masuk baru - viewer yang sudah join lewat link
     * lama tetap punya akses, baris trip_viewers-nya tidak disentuh.
     */
    #[Endpoint('Matikan link undangan', 'Viewer yang sudah bergabung tetap punya akses.')]
    public function destroyInviteLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->update(['viewer_invite_token' => null]);

        return response()->json(['message' => 'Link undangan dimatikan.']);
    }

    /**
     * F016 - klaim akses viewer lewat link. Butuh login (beda dari Section
     * 10 yang anon) - route ini sudah di dalam grup auth:sanctum. Tidak ada
     * langkah accept/reject terpisah, begitu berhasil auth langsung masuk.
     */
    #[Endpoint('Gabung lewat link', 'Menjadi viewer trip dari token di link undangan.')]
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
