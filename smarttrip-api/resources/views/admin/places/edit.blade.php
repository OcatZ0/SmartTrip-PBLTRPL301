@extends('admin.layout')

@section('title', 'Edit ' . $place->name)
@section('heading', $place->name)
@section('subtitle', 'Edit data, harga, kategori, dan foto tempat ini.')
@section('back_url', route('admin.places.index'))
@section('back_label', 'Kelola Tempat')

@push('styles')
<style>

    /* Cards Base */
    .edit-card {
        background-color: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 16px;
        padding: 20px 24px;
        margin-bottom: 20px;
    }

    /* Header Banner Google Places */
    .source-info-banner {
        background-color: #EFF6FF;
        border: 1px solid #DBEAFE;
        border-radius: 10px;
        padding: 8px 14px;
        font-size: 12px;
        font-weight: 600;
        color: #1E40AF;
        display: flex;
        align-items: center;
        gap: 6px;
    }

    .place-header-thumb {
        width: 140px;
        height: 90px;
        border-radius: 12px;
        object-fit: cover;
    }

    .thumb-overlay-badge {
        position: absolute;
        bottom: 6px;
        left: 6px;
        background: rgba(15, 23, 42, 0.75);
        color: #FFFFFF;
        font-size: 10px;
        font-weight: 600;
        padding: 2px 8px;
        border-radius: 6px;
        backdrop-filter: blur(2px);
    }

    .rating-badge-google {
        background-color: #FEF3C7;
        color: #B45309;
        font-size: 12px;
        font-weight: 800;
        padding: 2px 8px;
        border-radius: 6px;
        display: inline-flex;
        align-items: center;
        gap: 4px;
    }

    /* Form Section Header */
    .section-accent-title {
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 15px;
        font-weight: 800;
        color: #0F172A;
        margin-bottom: 16px;
    }

    .accent-bar-blue {
        width: 4px;
        height: 18px;
        background-color: #1672B8;
        border-radius: 2px;
    }

    /* Input Custom Blue Styled */
    .input-blue-box {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 10px;
        padding: 10px 14px;
        font-size: 14px;
        font-weight: 700;
        color: #0369A1;
        width: 100%;
        outline: none;
    }

    .input-counter-group {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 4px 8px;
    }

    .btn-counter {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background: #FFFFFF;
        border: 1px solid #BAE6FD;
        color: #0369A1;
        font-weight: 800;
        font-size: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
    }

    /* Outdoor Banner Switch */
    .outdoor-switch-banner {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 14px;
        padding: 16px 20px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 20px;
    }

    .outdoor-icon-box {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        background-color: #E0F2FE;
        color: #0284C7;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        flex-shrink: 0;
    }

    .badge-outdoor-active {
        background-color: #DCFCE7;
        color: #15803D;
        font-size: 11px;
        font-weight: 700;
        padding: 2px 8px;
        border-radius: 10px;
    }

    /* Time Range Box */
    .time-range-box {
        background-color: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        padding: 12px 16px;
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .time-icon-circle {
        width: 34px;
        height: 34px;
        border-radius: 50%;
        background-color: #FFFFFF;
        border: 1px solid #CBD5E1;
        color: #64748B;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
    }

    /* Category Tag Checkboxes */
    .category-chip-checkbox {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 6px 14px;
        border-radius: 20px;
        background-color: #1D4ED8;
        color: #FFFFFF;
        font-size: 12.5px;
        font-weight: 700;
        cursor: pointer;
        user-select: none;
        transition: all 0.15s ease;
    }

    .category-chip-checkbox.inactive {
        background-color: #F1F5F9;
        color: #475569;
        border: 1px solid #CBD5E1;
    }

    .btn-add-cat-pill {
        background-color: #E0F2FE;
        color: #0369A1;
        font-size: 12.5px;
        font-weight: 700;
        padding: 6px 16px;
        border-radius: 20px;
        border: none;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        cursor: pointer;
    }

    .btn-add-cat-pill:hover {
        background-color: #BAE6FD;
    }

    /* Textarea Box Custom */
    .textarea-custom {
        background-color: #F8FAFC;
        border: 1px solid #CBD5E1;
        border-radius: 12px;
        padding: 14px 16px;
        font-size: 13.5px;
        color: #1E293B;
        line-height: 1.6;
        width: 100%;
        outline: none;
    }

    .textarea-custom:focus {
        background-color: #FFFFFF;
        border-color: #1672B8;
    }

    /* Facility Chips */
    .facility-chip {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 10px;
        padding: 10px 14px;
        display: inline-flex;
        align-items: center;
        gap: 10px;
        font-size: 12.5px;
        font-weight: 700;
        color: #0369A1;
    }

    .facility-square-icon {
        width: 14px;
        height: 14px;
        background-color: #0284C7;
        border-radius: 3px;
    }

    /* Sidebar Cards */
    .sidebar-verified-box {
        background-color: #EFF6FF;
        border: 1px solid #DBEAFE;
        border-radius: 12px;
        padding: 14px 16px;
        display: flex;
        align-items: center;
        gap: 12px;
        color: #1E40AF;
        font-weight: 800;
        font-size: 13.5px;
        margin-bottom: 16px;
    }

    .sidebar-metric-box {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 12px;
        padding: 14px;
        text-align: center;
    }

    .metric-value {
        font-size: 22px;
        font-weight: 900;
        color: #0F172A;
        line-height: 1.2;
    }

    .metric-label {
        font-size: 11px;
        font-weight: 700;
        color: #64748B;
    }

    .geofence-map-container {
        border-radius: 12px;
        overflow: hidden;
        position: relative;
        border: 1px solid #E2E8F0;
        height: 140px;
        background: #E2E8F0 url('https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&h=300&fit=crop') center/cover;
    }

    .geofence-pulse-overlay {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 80px;
        height: 80px;
        border-radius: 50%;
        background: rgba(2, 132, 199, 0.25);
        border: 2px solid #0284C7;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .geofence-pin {
        width: 30px;
        height: 30px;
        border-radius: 50%;
        background-color: #0369A1;
        color: #FFFFFF;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    }

    .geofence-pill-tag {
        position: absolute;
        bottom: 8px;
        left: 50%;
        transform: translateX(-50%);
        background-color: #0F172A;
        color: #FFFFFF;
        font-size: 10px;
        font-weight: 700;
        padding: 3px 10px;
        border-radius: 12px;
        white-space: nowrap;
    }

    /* Fixed Bottom Footer Bar */
    .edit-bottom-bar {
        position: sticky;
        bottom: 0;
        left: 0;
        right: 0;
        background-color: #FFFFFF;
        border-top: 1px solid #E2E8F0;
        padding: 14px 28px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-left: -24px;
        margin-right: -24px;
        margin-bottom: -24px;
        margin-top: 24px;
        z-index: 100;
        box-shadow: 0 -4px 16px rgba(0,0,0,0.04);
    }

    .btn-delete-link {
        color: #DC2626;
        font-weight: 700;
        font-size: 13.5px;
        background: transparent;
        border: none;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        text-decoration: none;
        cursor: pointer;
    }

    .btn-delete-link:hover {
        color: #991B1B;
        text-decoration: underline;
    }

    .btn-batal-custom {
        background-color: #EFF6FF;
        border: 1px solid #DBEAFE;
        color: #1E40AF;
        font-weight: 700;
        font-size: 13.5px;
        padding: 10px 24px;
        border-radius: 10px;
        text-decoration: none;
    }

    .btn-batal-custom:hover {
        background-color: #DBEAFE;
        color: #1E3A8A;
    }

    .btn-simpan-custom {
        background-color: #1672B8;
        border: none;
        color: #FFFFFF;
        font-weight: 800;
        font-size: 13.5px;
        padding: 10px 28px;
        border-radius: 10px;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        transition: background-color 0.15s ease;
    }

    .btn-simpan-custom:hover {
        background-color: #0F5C97;
    }
</style>
@endpush

@section('content')

@if (session('status'))
    <div class="alert alert-success">{{ session('status') }}</div>
@endif
@if (session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
@endif
@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

    <!-- Main Edit Form -->
    <form method="POST" action="{{ route('admin.places.update', $place) }}" id="formEditPlace">
        @csrf
        @method('PUT')

        <div class="row g-4">
            <!-- Left Main Form Column (8 Columns) -->
            <div class="col-lg-8">
                
                <!-- Card 1: Banner Header Source Google Places API -->
                <div class="edit-card">
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <div class="source-info-banner">
                            <i class="bi bi-lock-fill"></i>
                            <span>Sumber: Google Places API (Read-only, tersinkronisasi otomatis)</span>
                        </div>
                        <span class="text-slate-400" style="font-size: 11.5px;">
                            <i class="bi bi-arrow-repeat me-1"></i>Diperbarui 12 jam yang lalu
                        </span>
                    </div>

                    <div class="d-flex gap-3 align-items-start">
                        <div class="position-relative flex-shrink-0">
                            <img src="{{ $place->photo_url ?? 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300&h=300&fit=crop' }}" class="place-header-thumb" alt="{{ $place->name }}">
                            <span class="thumb-overlay-badge">Foto Google (1/48)</span>
                        </div>
                        <div class="flex-grow-1">
                            <div class="d-flex align-items-center gap-2 mb-1">
                                <h3 class="fw-extrabold text-slate-900 fs-5 mb-0">{{ $place->name }}</h3>
                                <span class="rating-badge-google">
                                    <i class="bi bi-star-fill"></i> {{ number_format($place->rating ?? 4.8, 1) }}
                                    <span class="fw-normal text-amber-800" style="font-size: 11px;">({{ number_format($place->review_count ?? 1240) }} ulasan Google)</span>
                                </span>
                            </div>
                            <div class="text-slate-600 mb-1" style="font-size: 12.5px;">
                                <i class="bi bi-geo-alt-fill text-slate-400 me-1"></i>
                                {{ $place->address ?? 'Jl. Trans Barelang, Tembesi, Sagulung, Kota Batam, Kepulauan Riau 29472' }}
                            </div>
                            <div class="text-slate-400" style="font-size: 12px;">
                                <i class="bi bi-crosshair me-1"></i> {{ $place->lat ?? '0.9829' }}° N, {{ $place->lng ?? '104.0371' }}° E
                                &nbsp;•&nbsp;
                                <i class="bi bi-bank me-1"></i> Tourist Attraction / Landmark
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Card 2: Form Kurasi Khusus SmartTrip -->
                <div class="edit-card">
                    <div class="section-accent-title">
                        <div class="accent-bar-blue"></div>
                        <span>Kurasi Khusus Rekomendasi SmartTrip</span>
                    </div>

                    <!-- Estimasi Biaya & Lama Kunjungan Ideal -->
                    <div class="row g-3 mb-4">
                        <div class="col-md-6">
                            <div class="d-flex align-items-center justify-content-between mb-1">
                                <label class="form-label-custom mb-0" style="font-size: 13px; font-weight: 700; color: #0F172A;">Estimasi Biaya Masuk &amp; Parkir</label>
                                <span class="text-slate-400" style="font-size: 11.5px;">Per Mobil</span>
                            </div>
                            <div class="input-group">
                                <span class="input-group-text bg-sky-50 border-sky-200 text-sky-700 fw-bold fs-7" style="border-radius: 10px 0 0 10px; border-color: #BAE6FD;">Rp</span>
                                <input type="number" name="estimated_cost_idr" id="inputCostIdr" class="input-blue-box rounded-start-0 border-start-0" value="{{ old('estimated_cost_idr', $place->estimated_cost_idr ?? 10000) }}">
                            </div>
                            <div class="text-slate-400 mt-1" style="font-size: 11.5px;">Biaya parkir kendaraan viewing point sisi utara.</div>
                        </div>

                        <div class="col-md-6">
                            <div class="d-flex align-items-center justify-content-between mb-1">
                                <label class="form-label-custom mb-0" style="font-size: 13px; font-weight: 700; color: #0F172A;">Lama Kunjungan Ideal</label>
                                <span class="text-slate-400" style="font-size: 11.5px;">Rekomendasi Rute</span>
                            </div>
                            <div class="input-counter-group">
                                <button type="button" class="btn-counter" onclick="adjustVisitTime(-15)">-</button>
                                <div class="fw-extrabold text-sky-800" style="font-size: 15px;">
                                    <span id="displayVisitMinutes">{{ old('estimated_visit_minutes', $place->estimated_visit_minutes ?? 90) }}</span>
                                    <span class="fw-normal text-sky-600" style="font-size: 12px;">menit</span>
                                </div>
                                <input type="hidden" name="estimated_visit_minutes" id="inputVisitMinutes" value="{{ old('estimated_visit_minutes', $place->estimated_visit_minutes ?? 90) }}">
                                <button type="button" class="btn-counter" onclick="adjustVisitTime(15)">+</button>
                            </div>
                            <div class="text-slate-400 mt-1" style="font-size: 11.5px;">Waktu ideal untuk menikmati pemandangan dan foto.</div>
                        </div>
                    </div>

                    <!-- Outdoor Banner Switch -->
                    <div class="outdoor-switch-banner">
                        <div class="d-flex align-items-center gap-3">
                            <div class="outdoor-icon-box">
                                <i class="bi bi-cloud-rain-fill"></i>
                            </div>
                            <div>
                                <div class="d-flex align-items-center gap-2">
                                    <span class="fw-bold text-slate-900" style="font-size: 14px;">Tempat Outdoor / Terbuka</span>
                                    <span class="badge-outdoor-active">Aktif</span>
                                </div>
                                <div class="text-slate-500" style="font-size: 12px;">
                                    Mengaktifkan notifikasi cuaca hujan &amp; jadwal pasang surut BMKG secara otomatis untuk pengguna.
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch m-0 ms-3">
                            <input class="form-check-input" type="checkbox" name="is_outdoor" value="1" style="width: 44px; height: 24px; cursor: pointer;" @checked(old('is_outdoor', $place->is_outdoor ?? true))>
                        </div>
                    </div>

                    <!-- Rentang Waktu Terbaik Kunjungan -->
                    <div class="mb-4">
                        <div class="d-flex align-items-center gap-2 mb-2">
                            <label class="form-label-custom mb-0" style="font-size: 13px; font-weight: 700; color: #0F172A;">Rentang Waktu Terbaik Kunjungan</label>
                            <span class="badge" style="background-color: #FEF3C7; color: #B45309; font-size: 11px; font-weight: 700; border-radius: 10px;">✨ Momen Sunset Barelang</span>
                        </div>

                        <div class="row g-3">
                            <div class="col-md-6">
                                <div class="time-range-box">
                                    <div class="time-icon-circle">
                                        <i class="bi bi-clock-fill"></i>
                                    </div>
                                    <div>
                                        <div class="text-slate-400" style="font-size: 11px; font-weight: 600;">Mulai Kunjungan</div>
                                        <div class="fw-extrabold text-slate-800" style="font-size: 14px;">16:30 WIB</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="time-range-box">
                                    <div class="time-icon-circle">
                                        <i class="bi bi-moon-stars-fill"></i>
                                    </div>
                                    <div>
                                        <div class="text-slate-400" style="font-size: 11px; font-weight: 600;">Selesai / Senja Usai</div>
                                        <div class="fw-extrabold text-slate-800" style="font-size: 14px;">18:30 WIB</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Kategori Destinasi Tag Chips -->
                    <div class="mb-4">
                        <label class="form-label-custom mb-2" style="font-size: 13px; font-weight: 700; color: #0F172A; display: block;">Kategori Destinasi</label>
                        <div class="d-flex flex-wrap gap-2 mb-2">
                            @foreach ($categories as $cat)
                                @php
                                    $isAttached = $place->categories->contains('categories_id', $cat->categories_id);
                                @endphp
                                <label class="category-chip-checkbox {{ $isAttached ? '' : 'inactive' }}">
                                    <input type="checkbox" name="category_ids[]" value="{{ $cat->categories_id }}" class="d-none" onchange="toggleChipStyle(this)" @checked($isAttached)>
                                    <i class="bi {{ $isAttached ? 'bi-check-lg' : 'bi-plus' }}"></i>
                                    <span>{{ $cat->name_id }}</span>
                                </label>
                            @endforeach
                            <button type="button" class="btn-add-cat-pill" onclick="window.location.href='{{ route('admin.categories.index') }}'">
                                <i class="bi bi-plus-lg"></i>
                                <span>Tambah Kategori Baru</span>
                            </button>
                        </div>
                    </div>

                    <!-- Deskripsi Tempat (Bahasa Indonesia) -->
                    <div class="mb-4">
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <div class="d-flex align-items-center gap-2">
                                <label class="form-label-custom mb-0" style="font-size: 13px; font-weight: 700; color: #0F172A;">Deskripsi Tempat (Bahasa Indonesia)</label>
                                <span class="badge bg-slate-200 text-slate-700 fw-bold" style="font-size: 10px;">ID</span>
                            </div>
                            <span class="text-slate-400" style="font-size: 11.5px;">3 Paragraf Kurasi</span>
                        </div>
                        <textarea name="description_override" class="textarea-custom" rows="5" placeholder="Tuliskan deskripsi lengkap tempat wisata ini...">{{ old('description_override', $place->description_override ?? $place->description) }}</textarea>
                    </div>

                    <!-- Deskripsi Tempat (English) -->
                    <div class="mb-4">
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <div class="d-flex align-items-center gap-2">
                                <label class="form-label-custom mb-0" style="font-size: 13px; font-weight: 700; color: #0F172A;">Deskripsi Tempat (English)</label>
                                <span class="badge bg-slate-200 text-slate-700 fw-bold" style="font-size: 10px;">EN</span>
                            </div>
                            <span class="text-slate-400" style="font-size: 11.5px;">Automated Sync to Global App</span>
                        </div>
                        <textarea name="description_en" class="textarea-custom" rows="4" placeholder="Write destination description in English...">{{ old('description_en', $place->description_en) }}</textarea>
                    </div>

                    <!-- Fasilitas & Aksesibilas Terverifikasi -->
                    <div class="mb-2">
                        <label class="form-label-custom mb-2" style="font-size: 13px; font-weight: 700; color: #0F172A; display: block;">Fasilitas &amp; Aksesibilitas Terverifikasi</label>
                        <div class="d-flex flex-wrap gap-2">
                            <div class="facility-chip">
                                <div class="facility-square-icon"></div>
                                <span>Dapat diakses bus pariwisata</span>
                            </div>
                            <div class="facility-chip">
                                <div class="facility-square-icon"></div>
                                <span>Toilet umum &amp; musala</span>
                            </div>
                            <div class="facility-chip">
                                <div class="facility-square-icon"></div>
                                <span>Restoran seafood kelong (&lt;10 mnt)</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Right Sidebar Column (4 Columns) -->
            <div class="col-lg-4">
                
                <!-- Sidebar Card 1: Status Verifikasi Data -->
                <div class="edit-card">
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <h4 class="fw-extrabold text-slate-900 fs-6 mb-0">Status Verifikasi Data</h4>
                        <i class="bi bi-shield-check text-sky-600 fs-5"></i>
                    </div>

                    <div class="sidebar-verified-box">
                        <i class="bi bi-check-circle-fill text-sky-600 fs-5"></i>
                        <div>
                            <div>Data Lengkap &amp; Terverifikasi</div>
                        </div>
                    </div>

                    <div class="text-slate-600" style="font-size: 12.5px; line-height: 1.8;">
                        <div class="d-flex justify-content-between">
                            <span class="text-slate-400">Terakhir Diubah:</span>
                            <span class="fw-bold text-slate-800">Dian Pratama (Kurator)</span>
                        </div>
                        <div class="text-end text-slate-400" style="font-size: 11.5px;">18 Mei 2025, 09:15 WIB</div>
                        
                        <div class="d-flex justify-content-between mt-2 pt-2 border-top">
                            <span class="text-slate-400">Tipe Input:</span>
                            <span class="fw-bold text-sky-700">
                                <i class="bi bi-cloud-check me-1"></i>Destinasi Terverifikasi API
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Sidebar Card 2: Metrik Popularitas Turis -->
                <div class="edit-card">
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <h4 class="fw-extrabold text-slate-900 fs-6 mb-0">Metrik Popularitas Turis</h4>
                        <i class="bi bi-graph-up-arrow text-slate-400 fs-6"></i>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <div class="sidebar-metric-box">
                                <div class="text-sky-700 fw-bold mb-1" style="font-size: 11px;">
                                    <i class="bi bi-heart me-1"></i>Wishlist
                                </div>
                                <div class="metric-value">1.420</div>
                                <div class="metric-label">kali disimpan</div>
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="sidebar-metric-box">
                                <div class="text-amber-700 fw-bold mb-1" style="font-size: 11px;">
                                    <i class="bi bi-sign-turn-right me-1"></i>Smart Route
                                </div>
                                <div class="metric-value">680</div>
                                <div class="metric-label">masuk itinerary</div>
                            </div>
                        </div>
                    </div>

                    <div class="bg-slate-50 border rounded-3 p-3">
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <span class="text-slate-500 fw-semibold" style="font-size: 11px;">Tren Rekomendasi 7 Hari Terakhir</span>
                            <span class="fw-extrabold text-emerald-600" style="font-size: 12px;">+18.4%</span>
                        </div>
                        <!-- Sparkline Chart Mock SVG -->
                        <svg width="100%" height="40" viewBox="0 0 200 40" fill="none">
                            <path d="M0 35 Q 30 38, 60 25 T 120 20 T 180 8 L 200 5" stroke="#0284C7" stroke-width="2.5" fill="none"/>
                            <path d="M0 35 Q 30 38, 60 25 T 120 20 T 180 8 L 200 5 L 200 40 L 0 40 Z" fill="url(#blueGradient)" opacity="0.15"/>
                            <defs>
                                <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="0%" stop-color="#0284C7"/>
                                    <stop offset="100%" stop-color="#FFFFFF"/>
                                </linearGradient>
                            </defs>
                        </svg>
                    </div>
                </div>

                <!-- Sidebar Card 3: Peta Lokasi & Geofence -->
                <div class="edit-card">
                    <div class="d-flex align-items-center justify-content-between mb-1">
                        <h4 class="fw-extrabold text-slate-900 fs-6 mb-0">Peta Lokasi &amp; Geofence</h4>
                        <i class="bi bi-geo-fill text-sky-600 fs-6"></i>
                    </div>
                    <div class="text-slate-400 mb-3" style="font-size: 11.5px;">Radius Pemicu Notifikasi (500m)</div>

                    <div class="geofence-map-container mb-3">
                        <div class="geofence-pulse-overlay">
                            <div class="geofence-pin">
                                <i class="bi bi-send-fill"></i>
                            </div>
                        </div>
                        <div class="geofence-pill-tag">Barelang Geofence Radius</div>
                    </div>

                    <div class="d-flex align-items-center justify-content-between" style="font-size: 12px;">
                        <span class="text-slate-500">
                            <i class="bi bi-triangle-fill text-slate-400 me-1" style="font-size: 8px;"></i>Akurasi Titik: Presisi Tinggi
                        </span>
                        <a href="javascript:void(0)" onclick="alert('Geofence terverifikasi otomatis')" class="text-sky-700 fw-bold text-decoration-none">
                            Ubah Geofence &gt;
                        </a>
                    </div>
                </div>

            </div>
        </div>

        <!-- Sticky Bottom Action Bar -->
        <div class="edit-bottom-bar">
            <button type="button" class="btn-delete-link" onclick="confirmDeletePlace()">
                <i class="bi bi-trash-fill"></i> Hapus Tempat dari Katalog
            </button>
            <div class="d-flex align-items-center gap-3">
                <a href="{{ route('admin.places.index') }}" class="btn-batal-custom">Batal</a>
                <button type="submit" class="btn-simpan-custom">
                    <i class="bi bi-floppy-fill"></i> Simpan Perubahan Data
                </button>
            </div>
        </div>
    </form>

    <!-- Form Hidden Delete Place -->
    <form id="formDeletePlaceAction" method="POST" action="{{ route('admin.places.destroy', $place) }}" class="d-none">
        @csrf
        @method('DELETE')
    </form>

@include('admin.places.photos', ['place' => $place])

@include('admin.partials.activity-log', ['activities' => $activities])
@endsection

@push('scripts')
<script>
    function adjustVisitTime(amount) {
        var input = document.getElementById('inputVisitMinutes');
        var display = document.getElementById('displayVisitMinutes');
        var current = parseInt(input.value) || 60;
        var updated = Math.max(15, current + amount);
        input.value = updated;
        display.innerText = updated;
    }

    function toggleChipStyle(checkbox) {
        var label = checkbox.closest('.category-chip-checkbox');
        var icon = label.querySelector('i');
        if (checkbox.checked) {
            label.classList.remove('inactive');
            icon.className = 'bi bi-check-lg';
        } else {
            label.classList.add('inactive');
            icon.className = 'bi bi-plus';
        }
    }

    function confirmDeletePlace() {
        if (confirm('Apakah Anda yakin ingin menghapus "{{ addslashes($place->name) }}" dari katalog?')) {
            document.getElementById('formDeletePlaceAction').submit();
        }
    }
</script>
@endpush
