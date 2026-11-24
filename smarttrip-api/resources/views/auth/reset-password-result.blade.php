@extends('admin.auth.layout')

@section('public', true)
@section('title', 'Atur Ulang Kata Sandi')

@section('content')
    @include('auth.partials.result-card', [
        'success' => $success,
        'heading' => $success ? 'Kata sandi berhasil diubah' : 'Tautan tidak dapat dipakai',
        'message' => $message,
        'hint' => $success
            ? 'Buka aplikasi SmartTrip di ponselmu, lalu masuk dengan email dan kata sandi baru.'
            : 'Minta tautan baru dari aplikasi SmartTrip: buka halaman Masuk, lalu pilih "Lupa kata sandi?". Tautan hanya berlaku 60 menit dan sekali pakai.',
    ])
@endsection
