@extends('admin.layout')

@section('title', 'Dashboard')

@section('content')
<h1 class="h3 mb-4">Dashboard</h1>

<div class="row g-3">
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Kandidat Menunggu Review</h2>
                <p class="display-6 mb-0">{{ $pendingCandidates }}</p>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Tempat Butuh Perhatian</h2>
                <p class="display-6 mb-0">{{ $placesMissingCost + $placesTagsNotReviewed }}</p>
                <p class="text-muted small mb-0">
                    {{ $placesMissingCost }} belum ada estimasi biaya,
                    {{ $placesTagsNotReviewed }} tag kategori belum direview
                </p>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Kredit Geoapify Hari Ini</h2>
                <p class="display-6 mb-0">{{ $quotaUsed }} / {{ $quotaLimit }}</p>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mt-1">
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Discovery Terakhir</h2>
                <p class="mb-0">{{ $lastDiscoveryAt?->format('Y-m-d H:i') ?? 'Belum pernah dijalankan' }}</p>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Enrichment Terakhir</h2>
                <p class="mb-0">{{ $lastEnrichmentAt?->format('Y-m-d H:i') ?? 'Belum pernah dijalankan' }}</p>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Volume Trip</h2>
                <p class="display-6 mb-0">{{ $tripVolume }}</p>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mt-1">
    <div class="col-md-6">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Rata-Rata Rating In-App</h2>
                <p class="display-6 mb-0">{{ $averageInAppRating !== null ? number_format($averageInAppRating, 2) : '-' }}</p>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted mb-3">Tempat Paling Di-Wishlist</h2>
                @if ($mostWishlistedPlaces->isEmpty())
                    <p class="text-muted mb-0">Belum ada data wishlist.</p>
                @else
                    <ol class="mb-0 ps-3">
                        @foreach ($mostWishlistedPlaces as $place)
                            <li>{{ $place->name }} ({{ $place->wishlisted_in_count }})</li>
                        @endforeach
                    </ol>
                @endif
            </div>
        </div>
    </div>
</div>
@endsection
