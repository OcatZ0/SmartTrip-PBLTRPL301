@extends('admin.auth.layout')

@section('title', 'Masuk')

@section('content')
<h1 class="auth-title">Selamat Datang Kembali</h1>
<p class="auth-subtitle">Kelola destinasi dan rekomendasi wisata Batam</p>

@if (session('status'))
    <div class="alert alert-success auth-alert">{{ session('status') }}</div>
@endif

<form method="POST" action="{{ route('admin.login.attempt') }}" novalidate>
    @csrf

    <label class="auth-label" for="email">Email</label>
    <div class="auth-field">
        <i class="bi bi-envelope"></i>
        <input type="email" class="auth-input @error('email') is-invalid @enderror" id="email" name="email"
               value="{{ old('email') }}" placeholder="nama@gmail.com" autocomplete="username" required autofocus>
    </div>
    @error('email')
        <div class="auth-error-text">{{ $message }}</div>
    @enderror

    <div class="auth-label-row">
        <label class="auth-label" for="password">Kata Sandi</label>
        <a class="auth-link" href="{{ route('admin.password.request') }}">Lupa kata sandi?</a>
    </div>
    <div class="auth-field">
        <i class="bi bi-lock"></i>
        <input type="password" class="auth-input @error('password') is-invalid @enderror" id="password" name="password"
               placeholder="Masukkan kata sandi" autocomplete="current-password" required>
        <button type="button" class="auth-eye" data-toggle-password="password" aria-label="Tampilkan kata sandi">
            <i class="bi bi-eye"></i>
        </button>
    </div>
    @error('password')
        <div class="auth-error-text">{{ $message }}</div>
    @enderror

    <label class="auth-check">
        <input type="checkbox" name="remember" value="1" @checked(old('remember'))>
        <span>Ingat saya</span>
    </label>

    <button type="submit" class="auth-submit">
        <span>Masuk</span>
        <i class="bi bi-arrow-right"></i>
    </button>
</form>
@endsection
