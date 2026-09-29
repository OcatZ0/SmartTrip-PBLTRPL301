<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\RegistrationVerificationMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * F001-F004: registrasi (dengan verifikasi email), login (email/password +
 * Google), logout.
 *
 * Alur registrasi/linking (lihat percakapan desain):
 * - Registrasi manual TIDAK langsung membuat/mengubah baris `users`. Ia
 *   menyimpan permintaan ke `pending_registrations` dan mengirim link
 *   verifikasi. Baris `users` baru dibuat/diperbarui setelah link diklik
 *   (lihat verifyRegistration).
 * - Kalau email itu sudah dipakai akun Google-only (password masih null),
 *   verifikasi akan MENAUTKAN password baru ke akun itu, bukan membuat
 *   akun baru - inilah yang membuat "akun Google lalu daftar manual pakai
 *   email sama" jadi aman (dibuktikan lewat kepemilikan inbox).
 * - Login Google yang menemukan email dengan akun ter-verifikasi (dari
 *   alur manual di atas) langsung menautkan google_id tanpa verifikasi
 *   tambahan, karena kepemilikan email itu sudah dibuktikan sebelumnya.
 */
class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $existing = User::where('email', $data['email'])->first();

        if ($existing && $existing->password !== null) {
            throw ValidationException::withMessages([
                'email' => ['Email ini sudah terdaftar. Silakan login.'],
            ]);
        }

        $token = Str::random(64);

        DB::table('pending_registrations')->updateOrInsert(
            ['email' => $data['email']],
            [
                'name' => $data['name'],
                'password' => Hash::make($data['password']),
                'token' => hash('sha256', $token),
                'created_at' => now(),
            ]
        );

        $verificationUrl = URL::temporarySignedRoute(
            'auth.verify-registration',
            now()->addMinutes(60),
            ['email' => $data['email'], 'token' => $token]
        );

        Mail::to($data['email'])->send(new RegistrationVerificationMail($verificationUrl));

        return response()->json([
            'message' => 'Silakan cek email Anda untuk verifikasi akun.',
        ], 202);
    }

    public function verifyRegistration(Request $request)
    {
        $email = $request->query('email');
        $token = (string) $request->query('token');

        $pending = DB::table('pending_registrations')->where('email', $email)->first();

        $failure = fn (string $message) => view('emails.verification-result', [
            'success' => false,
            'message' => $message,
        ]);

        if (! $pending || ! hash_equals($pending->token, hash('sha256', $token))) {
            return $failure('Tautan verifikasi tidak valid.');
        }

        if (now()->diffInMinutes($pending->created_at) > 60) {
            DB::table('pending_registrations')->where('email', $email)->delete();

            return $failure('Tautan verifikasi sudah kedaluwarsa. Silakan daftar ulang.');
        }

        $user = User::where('email', $email)->first();

        if ($user) {
            // Akun Google-only yang menautkan password baru.
            $user->forceFill([
                'name' => $user->name ?: $pending->name,
                'password' => $pending->password,
                'email_verified_at' => $user->email_verified_at ?? now(),
            ])->save();
        } else {
            User::create([
                'name' => $pending->name,
                'email' => $email,
                'password' => $pending->password,
                'email_verified_at' => now(),
            ]);
        }

        DB::table('pending_registrations')->where('email', $email)->delete();

        return view('emails.verification-result', [
            'success' => true,
            'message' => 'Akun berhasil diverifikasi. Silakan login di aplikasi.',
        ]);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau kata sandi salah.'],
            ]);
        }

        $user = User::where('email', $credentials['email'])->firstOrFail();

        return response()->json([
            'user' => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ]);
    }

    public function loginWithGoogle(Request $request)
    {
        $data = $request->validate([
            'id_token' => ['required', 'string'],
        ]);

        $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $data['id_token'],
        ]);

        if ($response->failed()) {
            throw ValidationException::withMessages([
                'id_token' => ['Token Google tidak valid.'],
            ]);
        }

        $payload = $response->json();

        if (($payload['aud'] ?? null) !== config('services.google.client_id')) {
            throw ValidationException::withMessages([
                'id_token' => ['Token Google tidak valid.'],
            ]);
        }

        $googleId = $payload['sub'];
        $email = $payload['email'];
        $name = $payload['name'] ?? $email;

        $user = User::where('google_id', $googleId)->first();

        if (! $user) {
            $user = User::where('email', $email)->first();

            if ($user) {
                // Email sudah terdaftar (manual atau sudah terverifikasi
                // sebelumnya) - tautkan google_id, tidak perlu verifikasi
                // tambahan karena Google sendiri sudah memverifikasi email.
                $user->forceFill([
                    'google_id' => $googleId,
                    'email_verified_at' => $user->email_verified_at ?? now(),
                ])->save();
            } else {
                $user = User::create([
                    'name' => $name,
                    'email' => $email,
                    'google_id' => $googleId,
                    'password' => null,
                    'email_verified_at' => now(),
                ]);
            }
        }

        return response()->json([
            'user' => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }
}
