@extends('admin.auth.layout')

@section('public', true)
@section('title', 'Atur Ulang Kata Sandi')

@section('content')
<form method="POST" action="{{ route('auth.reset-password.submit') }}" class="auth-card flex w-full max-w-[420px] flex-col gap-4 rounded-3xl bg-white px-6 pb-7 pt-9 text-[#14212f] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.55)] sm:px-8">
    @csrf
    <input type="hidden" name="email" value="{{ old('email', $email) }}">
    <input type="hidden" name="token" value="{{ old('token', $token) }}">

    <div class="mb-1.5 flex flex-col gap-1.5">
        <h1 class="m-0 text-[28px] font-extrabold leading-[34px] tracking-[-0.02em]">Buat kata sandi baru</h1>
        <p class="m-0 text-sm text-[#5d6b7c]">Untuk akun <span class="font-semibold text-[#14212f]">{{ old('email', $email) }}</span>. Minimal 8 karakter.</p>
    </div>

    @if ($errors->has('email') || $errors->has('token'))
        <p class="m-0 rounded-[14px] bg-[#fdecea] px-3.5 py-2.5 text-[13px] font-medium text-[#a8321f]">{{ $errors->first('email') ?: $errors->first('token') }}</p>
    @endif

    @foreach ([['password', 'Kata sandi baru', 'new-password'], ['password_confirmation', 'Ulangi kata sandi baru', 'new-password']] as [$field, $label, $autocomplete])
        <div class="flex flex-col gap-1.5">
            <label for="{{ $field }}" class="text-[13px] font-semibold">{{ $label }}</label>
            <div class="flex h-[52px] items-center gap-2.5 rounded-[14px] border bg-[#eef2f8] px-3.5 focus-within:border-[#2b6fab] focus-within:bg-white focus-within:ring-4 focus-within:ring-[#2b6fab]/20 @error($field) border-[#c0392b] @else border-transparent @enderror">
                <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="#5d6b7c" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
                <input id="{{ $field }}" name="{{ $field }}" type="password" required minlength="8" autocomplete="{{ $autocomplete }}" @if ($loop->first) autofocus @endif class="min-w-0 flex-1 border-0 bg-transparent p-0 text-sm text-[#14212f] placeholder:text-[#5d6b7c] focus:outline-none focus:ring-0">
            </div>
            @error($field)
                <p class="m-0 text-xs font-medium text-[#c0392b]">{{ $message }}</p>
            @enderror
        </div>
    @endforeach

    <button type="submit" class="flex h-[52px] items-center justify-center gap-2 rounded-[14px] border-0 bg-[#2b6fab] text-[15px] font-bold text-white transition hover:bg-[#245f93] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#2b6fab]/30">
        Simpan kata sandi baru
        <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
    </button>

    <p class="m-0 mt-1.5 text-center text-[13px] text-[#5d6b7c]">Setelah disimpan, masuk lagi di aplikasi SmartTrip dengan kata sandi baru.</p>
</form>
@endsection
