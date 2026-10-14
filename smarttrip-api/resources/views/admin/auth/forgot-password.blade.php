@extends('admin.auth.layout')

@section('title', 'Lupa Kata Sandi')

@section('content')
<h1 class="auth-title auth-title-lg">Lupa Kata Sandi?</h1>
<p class="auth-subtitle">Jangan khawatir. Masukkan alamat email yang terdaftar dan kami akan mengirim tautan untuk mengatur ulang kata sandi</p>

@if (session('status'))
    <div class="alert alert-success auth-alert">{{ session('status') }}</div>
@endif

<form method="POST" action="{{ route('admin.password.email') }}" novalidate>
    @csrf

    <label class="auth-label" for="email">Email</label>
    <div class="auth-field">
        <i class="bi bi-envelope"></i>
        <input type="email" class="auth-input @error('email') is-invalid @enderror" id="email" name="email"
               value="{{ old('email') }}" placeholder="nama@gmail.com" autocomplete="email" required autofocus>
    </div>
    @error('email')
        <div class="auth-error-text">{{ $message }}</div>
    @enderror

    <button type="submit" class="auth-submit">
        <span>Kirim Tautan</span>
        <i class="bi bi-arrow-right"></i>
    </button>

    <div class="text-center mt-3">
        <a class="auth-link" href="{{ route('admin.login') }}"><i class="bi bi-arrow-left"></i> Kembali ke halaman masuk</a>
    </div>
</form>
@endsection
