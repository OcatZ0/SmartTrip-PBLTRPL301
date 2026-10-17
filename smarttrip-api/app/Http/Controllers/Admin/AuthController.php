<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

/**
 * Session-based admin login (docs/prd Section 8), separate from the
 * mobile app's Sanctum token auth.
 */
class AuthController extends Controller
{
    public function showLogin()
    {
        return view('admin.auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        // No "Ingat saya": an admin session ends when it expires or on Keluar.
        if (! Auth::attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau kata sandi salah.'],
            ]);
        }

        if (! Auth::user()->isAdmin()) {
            Auth::logout();

            throw ValidationException::withMessages([
                'email' => ['Akun ini bukan akun admin.'],
            ]);
        }

        $request->session()->regenerate();

        // The login page sends the form with fetch to play its exit transition
        // first; failures above come back as 422 JSON for it.
        if ($request->expectsJson()) {
            return response()->json(['redirect' => route('admin.dashboard')]);
        }

        return redirect()->route('admin.dashboard');
    }

    public function showForgotPassword()
    {
        return view('admin.auth.forgot-password');
    }

    /**
     * Sends the same reset link as the mobile app (POST /api/auth/forgot-password),
     * which opens the web form at /auth/reset-password. The reply is the same
     * whether or not the email exists, so the form cannot be used to check
     * which emails are registered.
     */
    public function sendResetLink(Request $request)
    {
        $request->validate(['email' => ['required', 'string', 'email']]);

        Password::sendResetLink($request->only('email'));

        return back()->with('status', 'Jika email terdaftar, tautan atur ulang kata sandi telah dikirim.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }
}
