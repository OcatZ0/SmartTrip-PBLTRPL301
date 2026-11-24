@extends('admin.auth.layout')

@section('public', true)
@section('title', 'Atur Ulang Kata Sandi')

@section('content')
    @if ($success)
        @include('auth.partials.result-card', [
            'success' => true,
            'heading' => 'Kata sandi berhasil diubah',
            'message' => $isAdmin
                ? 'Masuk ke panel admin dengan email dan kata sandi baru.'
                : 'Buka aplikasi SmartTrip di ponselmu, lalu masuk dengan email dan kata sandi baru.',
            'action' => $isAdmin ? ['label' => 'Masuk ke Panel Admin', 'url' => route('admin.login')] : null,
        ])
    @else
        @include('auth.partials.result-card', [
            'success' => false,
            'heading' => 'Tautan tidak dapat dipakai',
            'message' => $message,
            'hint' => 'Minta tautan baru lewat "Lupa kata sandi?" di halaman masuk aplikasi atau panel admin. Tautan berlaku 60 menit dan hanya bisa dipakai sekali.',
        ])
    @endif
@endsection
