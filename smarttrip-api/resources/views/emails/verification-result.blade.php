@extends('admin.auth.layout')

@section('public', true)
@section('title', 'Verifikasi Akun')

@section('content')
    @include('auth.partials.result-card', [
        'success' => $success,
        'heading' => $success ? 'Akun berhasil diverifikasi' : 'Verifikasi gagal',
        'message' => $message,
        'hint' => $success
            ? 'Buka aplikasi SmartTrip di ponselmu, lalu masuk dengan email dan kata sandi yang kamu daftarkan.'
            : 'Daftar ulang dari aplikasi SmartTrip untuk menerima email verifikasi baru. Tautan verifikasi berlaku 60 menit.',
    ])
@endsection
