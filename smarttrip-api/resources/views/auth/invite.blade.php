@extends('admin.auth.layout')

@section('public', true)
@section('title', 'Undangan Trip')

{{-- Fallback for an invite link (F016) opened where the SmartTrip app is not installed; with the app, Android opens it there (public/.well-known/assetlinks.json). --}}
@section('content')
    @include('auth.partials.result-card', [
        'success' => true,
        'heading' => 'Kamu diundang melihat trip',
        'message' => 'Buka tautan ini di ponsel Android yang sudah terpasang aplikasi SmartTrip. Trip akan terbuka setelah kamu masuk.',
        'hint' => 'Kalau tautan tetap terbuka di browser, salin tautannya lalu tempel di aplikasi: Trip Tersimpan, tab Dibagikan, kolom Punya tautan undangan?',
    ])
@endsection
