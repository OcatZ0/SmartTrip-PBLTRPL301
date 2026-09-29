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
                <p class="display-6 mb-0">-</p>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-body">
                <h2 class="h6 text-muted">Kuota Google Places Bulan Ini</h2>
                <p class="display-6 mb-0">-</p>
            </div>
        </div>
    </div>
</div>

<p class="text-muted mt-4">
    Statistik belum terhubung - menunggu tabel <code>places</code> dan <code>place_candidates</code>
    (docs/prd Section 10).
</p>
@endsection
