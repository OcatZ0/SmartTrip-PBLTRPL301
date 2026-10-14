@extends('admin.auth.layout')

@section('title', 'Lupa Kata Sandi')

@section('content')
<form method="POST" action="{{ route('admin.password.email') }}" class="flex w-full max-w-[420px] flex-col gap-4 rounded-3xl bg-white px-6 pb-7 pt-9 text-[#14212f] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.55)] sm:px-8">
    @csrf

    <div class="mb-1.5 flex flex-col gap-1.5">
        <h1 class="m-0 text-[28px] font-extrabold leading-[34px] tracking-[-0.02em]">Lupa kata sandi?</h1>
        <p class="m-0 text-sm text-[#5d6b7c]">Masukkan email yang terdaftar, kami kirim tautan untuk mengatur ulang kata sandi.</p>
    </div>

    @if (session('status'))
        <p class="m-0 rounded-[14px] bg-[#e7f4ec] px-3.5 py-2.5 text-[13px] font-medium text-[#1e6b3a]">{{ session('status') }}</p>
    @endif

    <div class="flex flex-col gap-1.5">
        <label for="email" class="text-[13px] font-semibold">Email</label>
        <div class="flex h-[52px] items-center gap-2.5 rounded-[14px] border bg-[#eef2f8] px-3.5 focus-within:border-[#2b6fab] focus-within:bg-white focus-within:ring-4 focus-within:ring-[#2b6fab]/20 @error('email') border-[#c0392b] @else border-transparent @enderror">
            <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="#5d6b7c" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>
            <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus autocomplete="email" placeholder="nama@smarttrip.id" class="min-w-0 flex-1 border-0 bg-transparent p-0 text-sm text-[#14212f] placeholder:text-[#5d6b7c] focus:outline-none focus:ring-0">
        </div>
        @error('email')
            <p class="m-0 text-xs font-medium text-[#c0392b]">{{ $message }}</p>
        @enderror
    </div>

    <button type="submit" class="flex h-[52px] items-center justify-center gap-2 rounded-[14px] border-0 bg-[#2b6fab] text-[15px] font-bold text-white transition hover:bg-[#245f93] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#2b6fab]/30">
        Kirim tautan
        <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
    </button>

    <p class="m-0 mt-1.5 text-center text-[13px] text-[#5d6b7c]">
        Ingat kata sandimu? <a href="{{ route('admin.login') }}" class="font-bold text-[#1f5f99] no-underline hover:text-[#16476d]">Kembali masuk</a>
    </p>
</form>
@endsection
