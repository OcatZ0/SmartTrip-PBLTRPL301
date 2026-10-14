@extends('admin.layout')

@section('title', 'Kelola Tempat')
@section('breadcrumb', 'Manajemen Destinasi')

@push('styles')
<style>
    /* Global Font (Plus Jakarta Sans) */
    .page-title {
        font-size: 20px;
        font-weight: 800;
        color: #0F172A;
        letter-spacing: -0.3px;
    }

    .page-subtitle {
        font-size: 13px;
        color: #64748B;
        font-weight: 500;
    }

    /* Primary Add Button */
    .btn-add-place {
        background-color: #1672B8;
        border: 1px solid #1672B8;
        color: #FFFFFF;
        font-weight: 700;
        font-size: 13px;
        padding: 8px 16px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        transition: background-color 0.15s ease;
    }

    .btn-add-place:hover {
        background-color: #0F5C97;
        border-color: #0F5C97;
        color: #FFFFFF;
    }

    /* Filter Card */
    .filter-card {
        background-color: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        padding: 10px 14px;
        margin-bottom: 12px;
    }

    .filter-input-group {
        display: flex;
        gap: 10px;
        align-items: center;
        flex-wrap: wrap;
    }

    .filter-search-box {
        position: relative;
        flex: 2;
        min-width: 220px;
    }

    .filter-search-box input {
        width: 100%;
        height: 36px;
        background-color: #F8FAFC;
        border: 1px solid #CBD5E1;
        border-radius: 8px;
        padding-left: 34px;
        padding-right: 12px;
        font-size: 12.5px;
        color: #1E293B;
        font-weight: 600;
    }

    .filter-search-box input:focus {
        background-color: #FFFFFF;
        border-color: #1672B8;
        outline: none;
    }

    .filter-search-box i {
        position: absolute;
        left: 12px;
        top: 50%;
        transform: translateY(-50%);
        color: #94A3B8;
        font-size: 13px;
    }

    .filter-select {
        height: 36px;
        background-color: #F8FAFC;
        border: 1px solid #CBD5E1;
        border-radius: 8px;
        padding: 0 12px;
        font-size: 12.5px;
        color: #334155;
        font-weight: 600;
        flex: 1;
        min-width: 150px;
        outline: none;
    }

    .filter-select:focus {
        border-color: #1672B8;
    }

    .btn-filter-refresh {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        border: 1px solid #CBD5E1;
        background-color: #F8FAFC;
        color: #64748B;
        display: flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        transition: background-color 0.15s ease;
    }

    .btn-filter-refresh:hover {
        background-color: #E2E8F0;
        color: #0F172A;
    }

    /* Summary Badges Bar */
    .summary-badges-bar {
        display: flex;
        gap: 10px;
        align-items: center;
        margin-bottom: 12px;
    }

    .summary-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 12px;
        border-radius: 16px;
        font-size: 12px;
        font-weight: 700;
    }

    .summary-pill-total {
        background-color: #F1F5F9;
        color: #475569;
        border: 1px solid #E2E8F0;
    }

    .summary-pill-siap {
        background-color: #DCEBFE;
        color: #1D4ED8;
        border: 1px solid #BFDBFE;
    }

    .summary-pill-butuh {
        background-color: #FEF3C7;
        color: #B45309;
        border: 1px solid #FDE68A;
    }

    .dot-pill {
        width: 6px;
        height: 6px;
        border-radius: 50%;
    }

    /* Places Table (Fixed Height / Compact Spacing) */
    .places-table-card {
        background-color: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        overflow: hidden;
        display: flex;
        flex-direction: column;
    }

    .places-table {
        width: 100%;
        border-collapse: collapse;
    }

    .places-table th {
        background-color: #F8FAFC;
        padding: 10px 14px;
        font-size: 11px;
        font-weight: 800;
        letter-spacing: 0.5px;
        color: #64748B;
        text-transform: uppercase;
        border-bottom: 1px solid #E2E8F0;
    }

    .places-table td {
        padding: 9px 14px;
        border-bottom: 1px solid #F1F5F9;
        vertical-align: middle;
        font-size: 13px;
    }

    .places-table tr:last-child td {
        border-bottom: none;
    }

    .places-table tr:hover td {
        background-color: #F8FAFC;
    }

    .place-thumbnail {
        width: 42px;
        height: 42px;
        border-radius: 8px;
        object-fit: cover;
        border: 1px solid #E2E8F0;
    }

    .place-name {
        font-weight: 800;
        color: #0F172A;
        font-size: 13.5px;
        line-height: 1.25;
    }

    /* Match "BTM-DST-001" size to "bebas masuk" (11px, font-weight 500, #94A3B8) */
    .place-code {
        font-size: 11px;
        font-weight: 500;
        color: #94A3B8;
        line-height: 1.2;
    }

    /* Type Badges */
    .badge-type {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 3px 10px;
        border-radius: 14px;
        font-size: 11.5px;
        font-weight: 700;
    }

    .badge-type-ikon { background-color: #DBEAFE; color: #1D4ED8; }
    .badge-type-pantai { background-color: #CFFAFE; color: #0891B2; }
    .badge-type-seafood { background-color: #FFEDD5; color: #C2410C; }
    .badge-type-kuliner { background-color: #FEF3C7; color: #B45309; }
    .badge-type-bahari { background-color: #E0E7FF; color: #4F46E5; }
    .badge-type-belanja { background-color: #EDE9FE; color: #6D28D9; }

    .location-text {
        color: #475569;
        font-weight: 600;
        font-size: 12.5px;
    }

    .rating-text {
        font-weight: 800;
        color: #0F172A;
        font-size: 13px;
    }

    .rating-star {
        color: #F59E0B;
    }

    .rating-count {
        color: #94A3B8;
        font-weight: 600;
        font-size: 11.5px;
    }

    .ticket-text {
        font-weight: 700;
        color: #1E293B;
        font-size: 12.5px;
    }

    .ticket-sub {
        font-size: 11px;
        color: #94A3B8;
        font-weight: 500;
    }

    .ticket-warning {
        color: #B45309;
        font-weight: 700;
        font-size: 12px;
    }

    /* Action Buttons */
    .btn-action-edit {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background-color: #EFF6FF;
        color: #1D4ED8;
        border: none !important;
        outline: none !important;
        box-shadow: none !important;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        cursor: pointer;
        transition: background-color 0.15s ease;
    }

    .btn-action-edit:hover {
        background-color: #1D4ED8;
        color: #FFFFFF;
    }

    .btn-action-delete {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background-color: #FEF2F2;
        color: #EF4444;
        border: none !important;
        outline: none !important;
        box-shadow: none !important;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: background-color 0.15s ease;
    }

    .btn-action-delete:hover {
        background-color: #EF4444;
        color: #FFFFFF;
    }

    .btn-action-history {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background-color: #F5F3FF;
        color: #7C3AED;
        border: none !important;
        outline: none !important;
        box-shadow: none !important;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        cursor: pointer;
        transition: background-color 0.15s ease;
    }

    .btn-action-history:hover {
        background-color: #7C3AED;
        color: #FFFFFF;
    }

    /* Clean & Neat Pagination Bar Alignment */
    .pagination-bar {
        padding: 12px 20px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: #FFFFFF;
        border-top: 1px solid #E2E8F0;
    }

    .pagination-info {
        font-size: 12.5px;
        color: #64748B;
        font-weight: 600;
    }

    .pagination-bar .pagination {
        margin: 0 !important;
        padding: 0 !important;
        display: flex;
        align-items: center;
        gap: 4px;
        list-style: none;
    }

    .pagination-bar .page-item .page-link {
        border-radius: 6px !important;
        padding: 5px 12px;
        font-size: 12px;
        font-weight: 700;
        color: #334155;
        background-color: #FFFFFF;
        border: 1px solid #CBD5E1;
        display: flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
    }

    .pagination-bar .page-item.active .page-link {
        background-color: #1672B8;
        border-color: #1672B8;
        color: #FFFFFF;
    }

    .pagination-bar .page-item.disabled .page-link {
        color: #94A3B8;
        background-color: #F8FAFC;
        border-color: #E2E8F0;
    }

    /* ─────────────────────────────────────────────────────────────────── */
    /* MODAL STYLING WITH GUARANTEED VISIBLE SCROLLBAR & STICKY FOOTER     */
    /* ─────────────────────────────────────────────────────────────────── */
    .modal-dialog-custom {
        max-width: 720px;
    }

    .modal-content-custom {
        border-radius: 20px;
        border: 1px solid #E5E7EB;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12);
        background-color: #FFFFFF;
        overflow: hidden;
        max-height: calc(100vh - 3rem);
    }

    .modal-header-custom {
        padding: 18px 24px;
        border-bottom: 1px solid #F1F5F9;
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        background-color: #FFFFFF;
        flex-shrink: 0;
    }

    .modal-header-icon {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background-color: #EFF6FF;
        color: #1672B8;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
    }

    .badge-mode {
        background-color: #E6F4EA;
        color: #137333;
        font-size: 11px;
        font-weight: 600;
        padding: 3px 10px;
        border-radius: 12px;
        border: none;
    }

    /* Custom Visible Scrollbar inside Modal Body */
    .modal-body-scrollable {
        padding: 20px 24px;
        overflow-y: scroll !important;
        max-height: calc(100vh - 200px);
    }

    .modal-body-scrollable::-webkit-scrollbar {
        width: 8px;
    }

    .modal-body-scrollable::-webkit-scrollbar-track {
        background: #F1F5F9;
        border-radius: 4px;
    }

    .modal-body-scrollable::-webkit-scrollbar-thumb {
        background: #1672B8;
        border-radius: 4px;
    }

    .modal-body-scrollable::-webkit-scrollbar-thumb:hover {
        background: #0F5C97;
    }

    .form-label-custom {
        font-size: 13px;
        font-weight: 600;
        color: #202124;
        margin-bottom: 6px;
        display: block;
    }

    .form-label-custom span {
        color: #EA4335;
    }

    .form-control-custom {
        height: 40px;
        border-radius: 10px;
        border: 1px solid #DADCE0;
        padding: 0 14px;
        font-size: 13px;
        color: #202124;
        font-weight: 600;
        width: 100%;
        outline: none;
        background-color: #FFFFFF;
        transition: border-color 0.15s ease;
    }

    .form-control-custom:focus {
        border-color: #1672B8;
    }

    .latlng-container-box {
        background-color: #F8F9FA;
        border: 1px solid #F1F3F4;
        border-radius: 12px;
        padding: 12px 14px;
        margin-bottom: 14px;
    }

    .btn-kunci-titik {
        height: 40px;
        padding: 0 16px;
        background-color: #1672B8;
        color: #FFFFFF;
        border-radius: 10px;
        font-weight: 600;
        font-size: 12.5px;
        border: none;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        white-space: nowrap;
    }

    .btn-kunci-titik:hover {
        background-color: #0F5C97;
    }

    .file-dropzone {
        border: 1.5px dashed #DADCE0;
        border-radius: 12px;
        padding: 10px 14px;
        background-color: #FAFAFA;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }

    .dropzone-file-info {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .dropzone-icon {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        background-color: #EFF6FF;
        color: #1672B8;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
    }

    .modal-footer-custom {
        padding: 14px 24px;
        border-top: 1px solid #F1F5F9;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 12px;
        background-color: #FFFFFF;
        flex-shrink: 0;
    }

    /* Toast Modal */
    .success-modal-card {
        background-color: #FFFFFF !important;
        border-radius: 28px !important;
        padding: 36px 32px !important;
        text-align: center !important;
        max-width: 440px !important;
        width: 100% !important;
        margin: 0 auto !important;
        border: 1px solid #E2E8F0 !important;
        box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.08), 0 8px 16px -6px rgba(0, 0, 0, 0.04) !important;
        cursor: pointer;
    }

    .success-icon-squircle {
        width: 56px;
        height: 56px;
        border-radius: 18px;
        border: 1.5px solid #86EFAC;
        background-color: #FFFFFF;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 18px auto;
    }

    .delete-icon-circle {
        width: 56px;
        height: 56px;
        border-radius: 50%;
        background-color: #FEF2F2;
        color: #EF4444;
        border: 1px solid #FEE2E2;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
        margin: 0 auto 14px auto;
    }

    /* ─────────────────────────────────────────────────────────────────── */
    /* F022 AUDIT TRAIL TIMELINE STYLING                                   */
    /* ─────────────────────────────────────────────────────────────────── */
    .audit-timeline {
        position: relative;
        padding-left: 28px;
        margin-top: 6px;
    }

    .audit-timeline::before {
        content: '';
        position: absolute;
        top: 14px;
        bottom: 14px;
        left: 11px;
        width: 2px;
        background: #E2E8F0;
    }

    .audit-item {
        position: relative;
        margin-bottom: 22px;
    }

    .audit-item:last-child {
        margin-bottom: 0;
    }

    .audit-dot {
        position: absolute;
        left: -28px;
        top: 8px;
        width: 24px;
        height: 24px;
        border-radius: 50%;
        background: #FFFFFF;
        border: 2px solid #CBD5E1;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 11px;
        z-index: 2;
    }

    .audit-dot.created {
        border-color: #10B981;
        color: #10B981;
        background: #ECFDF5;
    }

    .audit-dot.updated {
        border-color: #3B82F6;
        color: #3B82F6;
        background: #EFF6FF;
    }

    .audit-dot.deleted {
        border-color: #EF4444;
        color: #EF4444;
        background: #FEF2F2;
    }

    .audit-card {
        background: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
        overflow: hidden;
    }

    .audit-card-header {
        background: #F8FAFC;
        padding: 10px 16px;
        border-bottom: 1px solid #E2E8F0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 8px;
    }

    .audit-card-body {
        padding: 14px 16px;
        background: #FFFFFF;
    }

    .audit-diff-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .audit-diff-row {
        border-bottom: 1px solid #F1F5F9;
    }

    .audit-diff-row:last-child {
        border-bottom: none;
    }

    .audit-diff-label {
        padding: 9px 14px 9px 0;
        font-weight: 700;
        font-size: 12.5px;
        color: #334155;
        width: 210px;
        vertical-align: middle;
    }

    .audit-diff-content {
        padding: 9px 0;
        vertical-align: middle;
    }

    .audit-val-old {
        display: inline-block;
        padding: 4px 10px;
        border-radius: 6px;
        background: #FEF2F2;
        color: #B91C1C;
        border: 1px solid #FEE2E2;
        font-size: 12px;
        font-weight: 600;
        text-decoration: line-through;
    }

    .audit-val-new {
        display: inline-block;
        padding: 4px 10px;
        border-radius: 6px;
        background: #F0FDF4;
        color: #15803D;
        border: 1px solid #DCFCE7;
        font-size: 12px;
        font-weight: 700;
    }

    .audit-val-empty {
        color: #94A3B8;
        font-style: italic;
        font-size: 12px;
    }

    .audit-text-diff {
        background: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 10px;
        padding: 12px 14px;
        margin-bottom: 10px;
    }

    .audit-text-diff:last-child {
        margin-bottom: 0;
    }

    .audit-text-diff-title {
        font-weight: 700;
        font-size: 12.5px;
        color: #1E293B;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
        gap: 6px;
    }

    .audit-text-box {
        padding: 10px 12px;
        border-radius: 8px;
        font-size: 12px;
        line-height: 1.55;
        white-space: pre-wrap;
        min-height: 44px;
    }

    .audit-text-box.old {
        background: #FEF2F2;
        color: #991B1B;
        border: 1px solid #FEE2E2;
    }

    .audit-text-box.new {
        background: #F0FDF4;
        color: #166534;
        border: 1px solid #DCFCE7;
    }

    .audit-badge-event {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 3px 8px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 700;
    }

    .audit-badge-event.created {
        background: #D1FAE5;
        color: #065F46;
    }

    .audit-badge-event.updated {
        background: #DBEAFE;
        color: #1E40AF;
    }

    .audit-badge-event.deleted {
        background: #FEE2E2;
        color: #991B1B;
    }
</style>
@endpush

@section('content')

    <!-- Header Section -->
    <div class="d-flex align-items-center justify-content-between mb-3">
        <div>
            <h1 class="page-title mb-0">Kelola Tempat</h1>
            <p class="page-subtitle mb-0">Basis data lengkap {{ $totalPlacesCount }} destinasi terdaftar di Pulau Batam</p>
        </div>

        <button class="btn-add-place" data-bs-toggle="modal" data-bs-target="#modalTambahTempat">
            <i class="bi bi-plus-lg"></i>
            <span>Tambah Tempat Manual</span>
        </button>
    </div>

    <!-- Filter Card -->
    <div class="filter-card">
        <form method="GET" action="{{ route('admin.places.index') }}" class="filter-input-group">
            <div class="filter-search-box">
                <i class="bi bi-search"></i>
                <input type="text" name="search" value="{{ $search }}" placeholder="Cari tempat wisata, alamat, atau ID...">
            </div>

            <select name="type" class="filter-select" onchange="this.form.submit()">
                <option value="">Semua Tipe Wisata</option>
                <option value="attraction" {{ $selectedType === 'attraction' ? 'selected' : '' }}>Wisata / Atraksi</option>
                <option value="culinary" {{ $selectedType === 'culinary' ? 'selected' : '' }}>Kuliner & Resto</option>
                <option value="lodging" {{ $selectedType === 'lodging' ? 'selected' : '' }}>Penginapan / Hotel</option>
            </select>

            <select name="status_data" class="filter-select" onchange="this.form.submit()">
                <option value="">Semua Status Data</option>
                <option value="siap_tampil" {{ $selectedStatus === 'siap_tampil' ? 'selected' : '' }}>Siap Tampil di App</option>
                <option value="butuh_lengkapi" {{ $selectedStatus === 'butuh_lengkapi' ? 'selected' : '' }}>Butuh Lengkapi</option>
            </select>

            <select name="kecamatan" class="filter-select" onchange="this.form.submit()">
                <option value="">Semua Wilayah / Kecamatan</option>
                @foreach($kecamatanList as $kec)
                    <option value="{{ $kec }}" {{ $selectedKecamatan === $kec ? 'selected' : '' }}>{{ $kec }}</option>
                @endforeach
            </select>

            <a href="{{ route('admin.places.index') }}" class="btn-filter-refresh" title="Reset Filter">
                <i class="bi bi-arrow-counterclockwise"></i>
            </a>
        </form>
    </div>

    <!-- Summary Badges Bar -->
    <div class="summary-badges-bar">
        <div class="summary-pill summary-pill-total">
            <span class="dot-pill" style="background-color: #64748B;"></span>
            <span>Total: {{ $totalPlacesCount }} Destinasi</span>
        </div>
        <div class="summary-pill summary-pill-siap">
            <span class="dot-pill" style="background-color: #1D4ED8;"></span>
            <span>Siap Tampil di App: {{ $siapTampilCount }}</span>
        </div>
        <div class="summary-pill summary-pill-butuh">
            <span class="dot-pill" style="background-color: #B45309;"></span>
            <span>Butuh Lengkapi: {{ $butuhLengkapiCount }} Tempat</span>
        </div>
    </div>

    <!-- Table Card (Strict 6 Items Pagination) -->
    <div class="places-table-card">
        <div class="table-responsive">
            <table class="places-table">
                <thead>
                    <tr>
                        <th style="width: 70px;">Thumbnail</th>
                        <th>Nama Tempat & ID</th>
                        <th>Tipe Wisata</th>
                        <th>Wilayah</th>
                        <th>Rating Publik</th>
                        <th>Tiket / Biaya</th>
                        <th style="width: 90px;" class="text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($places as $place)
                        <tr>
                            <td>
                                <img src="{{ $place->photo_url ?? 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=120&h=120&fit=crop' }}" 
                                     alt="{{ $place->name }}" class="place-thumbnail">
                            </td>
                            <td>
                                <div class="place-name">{{ $place->name }}</div>
                                <div class="place-code">{{ $place->external_place_id ?? sprintf('BTM-DST-%03d', $place->places_id) }}</div>
                            </td>
                            <td>
                                @php
                                    $catName = $place->categories->first()->name_id ?? 'Wisata Umum';
                                    $badgeClass = 'badge-type-ikon';
                                    $icon = 'bi-geo-alt';

                                    if (str_contains(strtolower($catName), 'pantai')) {
                                        $badgeClass = 'badge-type-pantai';
                                        $icon = 'bi-water';
                                    } elseif (str_contains(strtolower($catName), 'seafood')) {
                                        $badgeClass = 'badge-type-seafood';
                                        $icon = 'bi-cup-hot';
                                    } elseif (str_contains(strtolower($catName), 'kuliner')) {
                                        $badgeClass = 'badge-type-kuliner';
                                        $icon = 'bi-utensils';
                                    } elseif (str_contains(strtolower($catName), 'bahari')) {
                                        $badgeClass = 'badge-type-bahari';
                                        $icon = 'bi-tsunami';
                                    } elseif (str_contains(strtolower($catName), 'belanja')) {
                                        $badgeClass = 'badge-type-belanja';
                                        $icon = 'bi-bag-check';
                                    }
                                @endphp
                                <span class="badge-type {{ $badgeClass }}">
                                    <i class="bi {{ $icon }}"></i>
                                    <span>{{ $catName }}</span>
                                </span>
                            </td>
                            <td>
                                <span class="location-text">
                                    <i class="bi bi-geo-alt me-1 text-slate-400"></i>{{ $place->kecamatan ?? 'Batam' }}
                                </span>
                            </td>
                            <td>
                                <div class="rating-text">
                                    <i class="bi bi-star-fill rating-star me-1"></i>{{ number_format($place->rating ?? 4.5, 1) }}
                                    <span class="rating-count">({{ number_format($place->review_count ?? 100) }})</span>
                                </div>
                            </td>
                            <td>
                                @if($place->estimated_cost_idr === 0)
                                    <div class="ticket-text">Gratis</div>
                                    <div class="ticket-sub">Bebas Masuk</div>
                                @elseif($place->estimated_cost_idr > 0)
                                    <div class="ticket-text">Rp {{ number_format($place->estimated_cost_idr, 0, ',', '.') }}</div>
                                @else
                                    <div class="ticket-warning">
                                        <i class="bi bi-exclamation-circle me-1"></i>Belum Diatur
                                    </div>
                                @endif
                            </td>
                            <td class="text-center">
                                <div class="d-flex align-items-center justify-content-center gap-2">
                                    <button type="button" class="btn-action-history" title="Riwayat Perubahan (Audit Trail)"
                                            onclick="openHistoryModal('{{ route('admin.places.activities', $place) }}', '{{ addslashes($place->name) }}')">
                                        <i class="bi bi-clock-history" style="pointer-events: none;"></i>
                                    </button>
                                    <button type="button" class="btn-action-edit" title="Edit Tempat"
                                            data-bs-toggle="modal" data-bs-target="#modalEditTempat"
                                            data-id="{{ $place->places_id }}"
                                            data-name="{{ $place->name }}"
                                            data-cat="{{ $place->categories->first()?->categories_id ?? '' }}"
                                            data-kecamatan="{{ $place->kecamatan ?? '' }}"
                                            data-lat="{{ $place->lat }}"
                                            data-lng="{{ $place->lng }}"
                                            data-address="{{ $place->address ?? '' }}"
                                            data-photo="{{ $place->photo_url ?? '' }}"
                                            data-cost="{{ $place->estimated_cost_idr }}"
                                            data-visit="{{ $place->estimated_visit_minutes }}"
                                            data-desc-id="{{ $place->description_override ?? $place->description ?? '' }}"
                                            data-desc-en="{{ $place->description_en ?? '' }}"
                                            data-outdoor="{{ $place->is_outdoor ? 1 : 0 }}"
                                            onclick="openEditPlaceModal(this)">
                                        <i class="bi bi-pencil-fill" style="pointer-events: none;"></i>
                                    </button>
                                    <button type="button" class="btn-action-delete" title="Hapus Tempat"
                                            data-delete-url="{{ route('admin.places.destroy', $place) }}"
                                            data-name="{{ $place->name }}"
                                            onclick="openDeletePlaceModal(this)">
                                        <i class="bi bi-trash-fill" style="pointer-events: none;"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center py-4 text-muted">
                                <i class="bi bi-inbox fs-2 d-block mb-1 text-slate-300"></i>
                                <span>Tidak ada tempat wisata yang ditemukan.</span>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Clean Pagination Footer Bar -->
        <div class="pagination-bar">
            <div class="pagination-info">
                Menampilkan {{ $places->firstItem() ?? 0 }}–{{ $places->lastItem() ?? 0 }} dari {{ $places->total() }} tempat
            </div>

            <div>
                {{ $places->links('pagination::bootstrap-5') }}
            </div>
        </div>
    </div>


    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL TAMBAH TEMPAT MANUAL (SCROLLABLE WITH VISIBLE BLUE SCROLLBAR) -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalTambahTempat" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-dialog-custom">
            <div class="modal-content modal-content-custom">
                <!-- Header (Fixed Top) -->
                <div class="modal-header-custom">
                    <div class="d-flex align-items-center gap-3">
                        <div class="modal-header-icon">
                            <i class="bi bi-plus-lg"></i>
                        </div>
                        <div>
                            <div class="d-flex align-items-center gap-2">
                                <h5 class="modal-title fw-bold fs-5 mb-0 text-slate-900">Tambah Tempat Manual</h5>
                                <span class="badge-mode">Mode Kurator</span>
                            </div>
                            <p class="mb-0 text-slate-500" style="font-size: 12.5px;">Kurasi entitas destinasi langsung ke database SmartTrip Batam.</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <!-- Form (With Custom Scrollable Body & Sticky Footer) -->
                <form method="POST" action="{{ route('admin.places.store') }}" enctype="multipart/form-data" class="d-flex flex-column m-0 p-0" style="overflow: hidden;">
                    @csrf
                    <div class="modal-body-scrollable">
                        <!-- Nama Tempat / Destinasi -->
                        <div class="mb-3">
                            <label class="form-label-custom">Nama Tempat / Destinasi <span>*</span></label>
                            <input type="text" name="name" class="form-control-custom" value="Pantai Viovio Sunset Bar & Glamping" placeholder="contoh: Pantai Viovio Sunset Bar & Glamping" required>
                        </div>

                        <!-- Kategori Wisata & Wilayah / Kecamatan -->
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label-custom">Kategori Wisata <span>*</span></label>
                                <select name="category_ids[]" class="form-control-custom" required>
                                    <option value="">Wisata Alam & Pantai</option>
                                    @foreach($categories as $cat)
                                        <option value="{{ $cat->categories_id }}" {{ str_contains(strtolower($cat->name_id), 'pantai') ? 'selected' : '' }}>{{ $cat->name_id }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-custom">Wilayah / Kecamatan <span>*</span></label>
                                <select name="kecamatan" class="form-control-custom" required>
                                    <option value="">Galang / Barelang</option>
                                    @foreach($kecamatanList as $kec)
                                        <option value="{{ $kec }}" {{ $kec === 'Galang' ? 'selected' : '' }}>{{ $kec }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <!-- Pencarian Lokasi (Google Places / OSM) -->
                        <div class="mb-3">
                            <label class="form-label-custom">Pencarian Lokasi (Google Places / OSM) <span>*</span></label>
                            <div class="d-flex gap-2">
                                <div class="position-relative flex-grow-1">
                                    <i class="bi bi-search position-absolute text-primary" style="left: 14px; top: 12px; font-size: 14px;"></i>
                                    <input type="text" id="inputSearchPlaces" class="form-control-custom ps-5" value="Viovio Beach & Bar, Sijantung Galang" placeholder="Viovio Beach & Bar, Sijantung Galang">
                                </div>
                                <button type="button" class="btn-kunci-titik" onclick="mockKunciTitik()">
                                    <i class="bi bi-geo-alt-fill"></i>
                                    <span>Kunci Titik</span>
                                </button>
                            </div>
                        </div>

                        <!-- Latitude & Longitude Box (Wrapped Container) -->
                        <div class="latlng-container-box">
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label-custom mb-1">Latitude (lat) <span>*</span></label>
                                    <input type="number" step="any" name="lat" id="inputLat" class="form-control-custom fw-bold" value="0.865421" placeholder="0.865421" required>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label-custom mb-1">Longitude (lng) <span>*</span></label>
                                    <input type="number" step="any" name="lng" id="inputLng" class="form-control-custom fw-bold" value="104.214589" placeholder="104.214589" required>
                                </div>
                            </div>
                        </div>

                        <!-- Alamat Lengkap & Patokan -->
                        <div class="mb-3">
                            <label class="form-label-custom">Alamat Lengkap & Patokan <span>*</span></label>
                            <textarea name="address" class="form-control-custom" style="height: 64px; padding: 10px 14px; resize: none;" placeholder="Jl. Trans Barelang Jembatan 5, Sijantung, Kec. Galang, Kota Batam" required>Jl. Trans Barelang Jembatan 5, Sijantung, Kec. Galang, Kota Batam</textarea>
                        </div>

                        <!-- Foto Destinasi Dropzone -->
                        <div class="mb-3">
                            <label class="form-label-custom">Foto Destinasi (place_photos / URL) <span class="fw-normal text-muted" style="font-size: 12px;">(JPG, PNG maks. 2MB)</span></label>
                            <div class="file-dropzone mb-2">
                                <div class="dropzone-file-info">
                                    <div class="dropzone-icon">
                                        <i class="bi bi-image"></i>
                                    </div>
                                    <div>
                                        <div class="fw-bold text-slate-800" style="font-size: 13px;" id="fileNamePreview">Viovio-sunset-panoramic.jpg</div>
                                        <div class="text-slate-400" style="font-size: 11.5px;">1.2 MB • Siap diunggah ke storage</div>
                                    </div>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <label for="inputPhotoFile" class="btn btn-outline-secondary btn-sm rounded-2 fw-semibold px-3" style="font-size: 12.5px; border-color: #DADCE0; color: #3C4043;">Ganti</label>
                                    <input type="file" name="photo_file" id="inputPhotoFile" class="d-none" onchange="previewFile(this)">
                                    <button type="button" class="btn text-slate-400 p-0 fs-5 ms-1" onclick="clearFile()"><i class="bi bi-trash"></i></button>
                                </div>
                            </div>
                            <input type="url" name="photo_url" class="form-control-custom" placeholder="Atau URL Foto (https://...)">
                        </div>

                        <!-- Estimasi Biaya & Jam Operasional -->
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label-custom">Estimasi Biaya / Tiket</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-white border-end-0 text-slate-500 fw-bold" style="border-radius: 10px 0 0 10px; border-color: #DADCE0;">Rp</span>
                                    <input type="number" name="estimated_cost_idr" id="inputCost" class="form-control-custom rounded-start-0 border-start-0" value="15000" placeholder="15000">
                                </div>
                                <div class="form-check mt-2">
                                    <input type="checkbox" name="is_free" value="1" class="form-check-input" id="checkFree" onchange="toggleFree(this)">
                                    <label class="form-check-label text-slate-600" for="checkFree" style="font-size: 12px; font-weight: 500;">Gratis / Bebas Biaya</label>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-custom">Estimasi Durasi & Jam</label>
                                <div class="input-group mb-2">
                                    <input type="number" name="estimated_visit_minutes" class="form-control-custom rounded-end-0 border-end-0" value="90" placeholder="90">
                                    <span class="input-group-text bg-slate-100 border-start-0 text-primary fw-bold" style="border-radius: 0 10px 10px 0; border-color: #DADCE0; font-size: 12.5px;">Menit</span>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <input type="text" class="form-control-custom text-center" value="09:00" style="height: 38px;">
                                    <span class="text-slate-400">-</span>
                                    <input type="text" class="form-control-custom text-center" value="20:00" style="height: 38px;">
                                    <span class="text-slate-500 fw-semibold" style="font-size: 12px;">WIB</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Footer (Fixed Bottom) -->
                    <div class="modal-footer-custom">
                        <button type="button" class="btn btn-light rounded-2 px-4 fw-bold border" style="font-size: 13.5px; border-color: #DADCE0; color: #3C4043;" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary rounded-2 px-4 fw-bold" style="background-color: #1672B8; border: none; font-size: 13.5px;">
                            <i class="bi bi-check-lg me-1"></i> Simpan Destinasi
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL EDIT TEMPAT WISATA                                            -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalEditTempat" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-dialog-custom">
            <div class="modal-content modal-content-custom">
                <!-- Header (Fixed Top) -->
                <div class="modal-header-custom">
                    <div class="d-flex align-items-center gap-3">
                        <div class="modal-header-icon" style="background-color: #EFF6FF; color: #1672B8;">
                            <i class="bi bi-pencil-fill"></i>
                        </div>
                        <div>
                            <div class="d-flex align-items-center gap-2">
                                <h5 class="modal-title fw-bold fs-5 mb-0 text-slate-900" id="modalEditPlaceTitle">Edit Destinasi Kurasi</h5>
                                <span class="badge-mode">Edit Tempat</span>
                            </div>
                            <p class="mb-0 text-slate-500" style="font-size: 12.5px;">Perbarui data tempat wisata dan kurasi rekomendasi SmartTrip Batam.</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <!-- Form (With Custom Scrollable Body & Sticky Footer) -->
                <form id="formEditPlaceModal" method="POST" action="" enctype="multipart/form-data" class="d-flex flex-column m-0 p-0" style="overflow: hidden;">
                    @csrf
                    @method('PUT')
                    
                    <div class="modal-body-scrollable">
                        <!-- Nama Tempat / Destinasi -->
                        <div class="mb-3">
                            <label class="form-label-custom">Nama Tempat / Destinasi <span>*</span></label>
                            <input type="text" name="name" id="editPlaceName" class="form-control-custom" placeholder="Nama Destinasi" required>
                        </div>

                        <!-- Kategori Wisata & Wilayah / Kecamatan -->
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label-custom">Kategori Wisata</label>
                                <select name="category_ids[]" id="editPlaceCategory" class="form-control-custom">
                                    <option value="">Pilih Kategori Utama</option>
                                    @foreach($categories as $cat)
                                        <option value="{{ $cat->categories_id }}">{{ $cat->name_id }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-custom">Wilayah / Kecamatan</label>
                                <select name="kecamatan" id="editPlaceKecamatan" class="form-control-custom">
                                    <option value="">Pilih Kecamatan</option>
                                    @foreach($kecamatanList as $kec)
                                        <option value="{{ $kec }}">{{ $kec }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <!-- Latitude & Longitude Box -->
                        <div class="latlng-container-box">
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label-custom mb-1">Latitude (lat) <span>*</span></label>
                                    <input type="number" step="any" name="lat" id="editPlaceLat" class="form-control-custom fw-bold" placeholder="0.865421" required>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label-custom mb-1">Longitude (lng) <span>*</span></label>
                                    <input type="number" step="any" name="lng" id="editPlaceLng" class="form-control-custom fw-bold" placeholder="104.214589" required>
                                </div>
                            </div>
                        </div>

                        <!-- Alamat Lengkap -->
                        <div class="mb-3">
                            <label class="form-label-custom">Alamat Lengkap &amp; Patokan <span>*</span></label>
                            <textarea name="address" id="editPlaceAddress" class="form-control-custom" style="height: 64px; padding: 10px 14px; resize: none;" placeholder="Alamat lengkap destinasi" required></textarea>
                        </div>

                        <!-- Foto Destinasi & Preview -->
                        <div class="mb-3">
                            <label class="form-label-custom">Foto Destinasi (Ganti Foto / Upload File Baru) <span class="fw-normal text-muted" style="font-size: 12px;">(JPG, PNG maks. 2MB)</span></label>
                            
                            <!-- Preview Foto Saat Ini -->
                            <div class="d-flex align-items-center gap-3 p-2 mb-2 bg-light rounded-3 border" id="editCurrentPhotoPreviewBox">
                                <img id="editCurrentPhotoThumb" src="https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=100&h=100&fit=crop" style="width: 48px; height: 48px; object-fit: cover; border-radius: 8px; border: 1px solid #CBD5E1;">
                                <div class="flex-grow-1">
                                    <div class="fw-bold text-slate-800" style="font-size: 12.5px;">Foto Destinasi Saat Ini</div>
                                    <div class="text-slate-400" style="font-size: 11px;">Unggah file baru di bawah ini untuk memperbarui gambar.</div>
                                </div>
                            </div>

                            <div class="file-dropzone mb-2">
                                <div class="dropzone-file-info">
                                    <div class="dropzone-icon">
                                        <i class="bi bi-image"></i>
                                    </div>
                                    <div>
                                        <div class="fw-bold text-slate-800" style="font-size: 13px;" id="editFileNamePreview">Belum ada file baru dipilih</div>
                                        <div class="text-slate-400" style="font-size: 11.5px;">Pilih file baru dari komputer untuk mengganti foto</div>
                                    </div>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <label for="inputEditPhotoFile" class="btn btn-outline-secondary btn-sm rounded-2 fw-semibold px-3" style="font-size: 12.5px; border-color: #DADCE0; color: #3C4043;">Pilih File</label>
                                    <input type="file" name="photo_file" id="inputEditPhotoFile" class="d-none" onchange="previewEditFile(this)">
                                    <button type="button" class="btn text-slate-400 p-0 fs-5 ms-1" onclick="clearEditFile()"><i class="bi bi-trash"></i></button>
                                </div>
                            </div>
                            <input type="url" name="photo_url" id="editPlacePhotoUrl" class="form-control-custom" placeholder="Atau perbarui URL Foto (https://...)">
                        </div>

                        <!-- Estimasi Biaya & Durasi Kunjungan -->
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label-custom">Estimasi Biaya Masuk &amp; Parkir (IDR)</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-white border-end-0 text-slate-500 fw-bold" style="border-radius: 10px 0 0 10px; border-color: #DADCE0;">Rp</span>
                                    <input type="number" name="estimated_cost_idr" id="editPlaceCost" class="form-control-custom rounded-start-0 border-start-0" placeholder="10000">
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-custom">Estimasi Durasi Kunjungan (Menit)</label>
                                <div class="input-group">
                                    <input type="number" name="estimated_visit_minutes" id="editPlaceVisitMinutes" class="form-control-custom rounded-end-0 border-end-0" placeholder="90">
                                    <span class="input-group-text bg-slate-100 border-start-0 text-primary fw-bold" style="border-radius: 0 10px 10px 0; border-color: #DADCE0; font-size: 12.5px;">Menit</span>
                                </div>
                            </div>
                        </div>

                        <!-- Sensitif Cuaca / Outdoor -->
                        <div class="mb-3 p-3 rounded-3 border bg-light d-flex align-items-center justify-content-between">
                            <div>
                                <div class="fw-bold text-slate-800" style="font-size: 13px;">Sensitif Cuaca (Wisata Outdoor / Terbuka)</div>
                                <div class="text-slate-500" style="font-size: 11.5px;">Aktifkan peringatan cuaca BMKG otomatis saat hujan/pasang surut.</div>
                            </div>
                            <div class="form-check form-switch m-0">
                                <input class="form-check-input" type="checkbox" name="is_outdoor" id="editPlaceOutdoor" value="1" style="width: 40px; height: 20px; cursor: pointer;">
                            </div>
                        </div>

                        <!-- Deskripsi Bahasa Indonesia & Inggris -->
                        <div class="mb-3">
                            <label class="form-label-custom">Deskripsi Kurator (Bahasa Indonesia)</label>
                            <textarea name="description_override" id="editPlaceDescId" class="form-control-custom" style="height: 80px; padding: 10px 14px; resize: none;" placeholder="Deskripsi kurator (Bahasa Indonesia)"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label-custom">Deskripsi (Bahasa Inggris)</label>
                            <textarea name="description_en" id="editPlaceDescEn" class="form-control-custom" style="height: 70px; padding: 10px 14px; resize: none;" placeholder="Deskripsi (Bahasa Inggris)"></textarea>
                        </div>
                    </div>

                    <!-- Footer (Fixed Bottom) -->
                    <div class="modal-footer-custom">
                        <button type="button" class="btn btn-light rounded-2 px-4 fw-bold border" style="font-size: 13.5px; border-color: #DADCE0; color: #3C4043;" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary rounded-2 px-4 fw-bold" style="background-color: #1672B8; border: none; font-size: 13.5px;">
                            <i class="bi bi-check-lg me-1"></i> Simpan Perubahan
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL CONFIRMATION HAPUS TEMPAT                                     -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalDeletePlace" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width: 420px;">
            <div class="modal-content p-4 text-center" style="border-radius: 20px; border: 1px solid #CBD5E1; box-shadow: none; background: #FFFFFF;">
                <div class="delete-icon-circle">
                    <i class="bi bi-trash-fill"></i>
                </div>
                <h3 class="fw-bold text-slate-900 fs-4 mb-2">Hapus Tempat Wisata?</h3>
                <p class="text-slate-500 mb-4" style="font-size: 13.5px;">
                    Data yang dipilih (<strong id="deletePlaceName">Tempat Wisata</strong>) akan dihapus secara permanen dari katalog SmartTrip Batam.
                </p>

                <form id="formDeletePlaceModal" method="POST" action="">
                    @csrf
                    @method('DELETE')
                    <div class="d-flex align-items-center justify-content-center gap-3">
                        <button type="button" class="btn btn-outline-primary fw-bold" style="width: 48%; height: 42px; border-radius: 10px; border-color: #1672B8; color: #1672B8;" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-danger fw-bold" style="width: 48%; height: 42px; border-radius: 10px; background-color: #DC2626; border: none;">Hapus</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL RIWAYAT PERUBAHAN (F022 AUDIT TRAIL)                          -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalHistory" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
            <div class="modal-content modal-content-custom">
                <!-- Header (Fixed Top) -->
                <div class="modal-header-custom" style="padding: 18px 24px; border-bottom: 1px solid #E2E8F0; background: #FFFFFF; display: flex; align-items: center; justify-content: space-between;">
                    <div class="d-flex align-items-center gap-3">
                        <div style="width: 44px; height: 44px; border-radius: 12px; background: #F5F3FF; color: #7C3AED; display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0;">
                            <i class="bi bi-clock-history"></i>
                        </div>
                        <div>
                            <div class="d-flex align-items-center gap-2">
                                <h5 class="modal-title fw-bold fs-5 mb-0" style="color: #0F172A;">Riwayat Perubahan Data</h5>
                                <span class="badge" style="background: #F5F3FF; color: #7C3AED; font-weight: 700; font-size: 11px; border: 1px solid #DDD6FE; border-radius: 6px;">F022 Audit Trail</span>
                            </div>
                            <p class="mb-0 text-muted" style="font-size: 12.5px; margin-top: 2px;">
                                Data: <strong id="historyModalSubject" style="color: #1E293B;">-</strong> • Rekam jejak seluruh penyesuaian kurator
                            </p>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <!-- Body (Scrollable) -->
                <div class="modal-body-scrollable" id="historyModalBody" style="background: #F8FAFC; padding: 22px 24px;">
                    <div class="text-center py-5" id="historyLoadingState">
                        <div class="spinner-border" role="status" style="width: 2.5rem; height: 2.5rem; color: #7C3AED !important;">
                            <span class="visually-hidden">Memuat...</span>
                        </div>
                        <p class="text-muted mt-2 mb-0" style="font-size: 13px; font-weight: 500;">Mengambil log audit data...</p>
                    </div>

                    <div id="historyContentContainer" class="d-none">
                        <!-- Populated dynamically by JS -->
                    </div>
                </div>

                <!-- Footer (Fixed Bottom) -->
                <div class="modal-footer-custom" style="padding: 14px 24px; border-top: 1px solid #E2E8F0; background: #FFFFFF; display: flex; justify-content: flex-end;">
                    <button type="button" class="btn px-4 fw-bold" style="font-size: 13px; border-radius: 8px; background: #F1F5F9; color: #475569; border: 1px solid #CBD5E1;" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- SUCCESS TOAST MODAL                                                 -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    @if(session('place_created_success') || session('status'))
        <div class="modal fade show d-block" id="modalBerhasil" tabindex="-1" style="background: rgba(15, 23, 42, 0.45); backdrop-filter: blur(2px);" onclick="closeSuccessToast()">
            <div class="modal-dialog modal-dialog-centered" style="max-width: 440px;">
                <div class="modal-content success-modal-card">
                    <div class="success-icon-squircle">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#00A651" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </div>
                    <h3 class="fw-bold mb-2" style="font-size: 20px; font-weight: 800; color: #0F172A; letter-spacing: -0.2px;">Berhasil!</h3>
                    <p class="mb-0" style="font-size: 14px; color: #64748B; font-weight: 500; line-height: 1.5;">
                        {{ session('place_created_success') ?? session('status') }}
                    </p>
                </div>
            </div>
        </div>
    @endif

@endsection

@push('scripts')
<script>
    function mockKunciTitik() {
        const query = document.getElementById('inputSearchPlaces').value;
        if (!query) {
            document.getElementById('inputSearchPlaces').value = 'Pantai Viovio Sunset Bar, Galang Batam';
        }
        document.getElementById('inputLat').value = '0.865421';
        document.getElementById('inputLng').value = '104.214589';
        alert('Kunci Titik Berhasil! Koordinat (0.865421, 104.214589) telah diisi dari lokasi.');
    }

    function toggleFree(checkbox) {
        const costInput = document.getElementById('inputCost');
        if (checkbox.checked) {
            costInput.value = 0;
            costInput.disabled = true;
        } else {
            costInput.disabled = false;
        }
    }

    function previewFile(input) {
        if (input.files && input.files[0]) {
            document.getElementById('fileNamePreview').innerText = input.files[0].name;
        }
    }

    function clearFile() {
        document.getElementById('inputPhotoFile').value = '';
        document.getElementById('fileNamePreview').innerText = 'Belum ada file dipilih';
    }

    function previewEditFile(input) {
        if (input.files && input.files[0]) {
            document.getElementById('editFileNamePreview').innerText = input.files[0].name;
            var reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('editCurrentPhotoThumb').src = e.target.result;
            }
            reader.readAsDataURL(input.files[0]);
        }
    }

    function clearEditFile() {
        document.getElementById('inputEditPhotoFile').value = '';
        document.getElementById('editFileNamePreview').innerText = 'Belum ada file baru dipilih';
    }

    function openEditPlaceModal(target) {
        let btn = (target && target.closest) ? (target.closest('.btn-action-edit') || target) : target;
        let ds = (btn && btn.dataset) ? btn.dataset : (btn || {});

        const id = ds.id || '';
        const name = ds.name || '';
        const catId = ds.cat || '';
        const kecamatan = ds.kecamatan || '';
        const lat = ds.lat || '';
        const lng = ds.lng || '';
        const address = ds.address || '';
        const photo = ds.photo || '';
        const cost = ds.cost || '';
        const visit = ds.visit || '';
        const descId = ds.descId || '';
        const descEn = ds.descEn || '';
        const outdoor = ds.outdoor || 0;

        document.getElementById('modalEditPlaceTitle').innerText = 'Edit Destinasi: ' + (name || 'Tempat Wisata');
        document.getElementById('formEditPlaceModal').action = id ? ('/admin/places/' + id) : '';
        document.getElementById('editPlaceName').value = name;
        document.getElementById('editPlaceKecamatan').value = kecamatan;
        if (document.getElementById('editPlaceCategory')) {
            document.getElementById('editPlaceCategory').value = catId;
        }
        document.getElementById('editPlaceLat').value = lat;
        document.getElementById('editPlaceLng').value = lng;
        document.getElementById('editPlaceAddress').value = address;
        document.getElementById('editPlacePhotoUrl').value = photo;
        if (document.getElementById('editCurrentPhotoThumb')) {
            document.getElementById('editCurrentPhotoThumb').src = photo || 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=100&h=100&fit=crop';
        }
        document.getElementById('editPlaceCost').value = cost;
        document.getElementById('editPlaceVisitMinutes').value = visit;
        document.getElementById('editPlaceDescId').value = descId;
        document.getElementById('editPlaceDescEn').value = descEn;
        document.getElementById('editPlaceOutdoor').checked = (outdoor == 1 || outdoor === 'true' || outdoor === '1');

        var modalEl = document.getElementById('modalEditPlace');
        var myModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        myModal.show();
    }

    function openDeletePlaceModal(target, nameFallback) {
        let url = '';
        let name = '';
        if (typeof target === 'object' && target !== null && target.dataset) {
            url = target.dataset.deleteUrl;
            name = target.dataset.name;
        } else {
            url = target;
            name = nameFallback || 'Tempat Wisata';
        }

        document.getElementById('formDeletePlaceModal').action = url;
        document.getElementById('deletePlaceName').innerText = name;
        var modalEl = document.getElementById('modalDeletePlace');
        var myModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        myModal.show();
    }

    const FIELD_METADATA = {
        'name': { label: 'Nama Tempat', icon: 'bi-geo-alt-fill' },
        'name_id': { label: 'Nama Kategori (ID)', icon: 'bi-tag-fill' },
        'name_en': { label: 'Nama Kategori (EN)', icon: 'bi-translate' },
        'subtitle_id': { label: 'Subjudul / Tagline', icon: 'bi-card-heading' },
        'icon_symbol': { label: 'Simbol Visual', icon: 'bi-emoji-smile' },
        'ai_keywords': { label: 'Kata Kunci Rekomendasi AI', icon: 'bi-stars', isLong: true },
        'slug': { label: 'Slug URL', icon: 'bi-link-45deg' },
        'type': { label: 'Kategori / Tipe Tempat', icon: 'bi-compass' },
        'address': { label: 'Alamat Lokasi', icon: 'bi-map' },
        'kecamatan': { label: 'Kecamatan', icon: 'bi-pin-map-fill' },
        'estimated_cost_idr': { label: 'Estimasi Biaya Masuk', icon: 'bi-cash-coin' },
        'estimated_visit_minutes': { label: 'Durasi Kunjungan', icon: 'bi-hourglass-split' },
        'is_outdoor': { label: 'Karakteristik Area', icon: 'bi-sun-fill' },
        'description_override': { label: 'Deskripsi Tempat (Bahasa Indonesia)', icon: 'bi-card-text', isLong: true },
        'description_en': { label: 'Deskripsi Tempat (Bahasa Inggris)', icon: 'bi-card-text', isLong: true },
        'description': { label: 'Deskripsi Lengkap', icon: 'bi-card-text', isLong: true },
        'lat': { label: 'Titik Koordinat (Latitude)', icon: 'bi-geo' },
        'lng': { label: 'Titik Koordinat (Longitude)', icon: 'bi-geo' },
        'photo_url': { label: 'URL Foto Sampul', icon: 'bi-image' }
    };

    const IGNORED_KEYS = ['category_tags_reviewed', 'updated_at', 'created_at', 'id', 'places_id', 'categories_id'];

    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function formatRawValue(key, val) {
        if (val === null || val === undefined || val === '') {
            return '';
        }

        if (key === 'estimated_cost_idr') {
            const num = Number(val);
            if (num === 0) return 'Gratis (Bebas Masuk)';
            return 'Rp ' + num.toLocaleString('id-ID');
        }

        if (key === 'is_outdoor') {
            const isOut = (val === 1 || val === true || val === '1' || val === 'true');
            return isOut ? 'Luar Ruangan (Outdoor)' : 'Dalam Ruangan (Indoor)';
        }

        if (key === 'estimated_visit_minutes') {
            const mins = Number(val);
            if (mins <= 0) return 'Fleksibel';
            if (mins < 60) return mins + ' Menit';
            const jam = (mins / 60).toFixed(1).replace('.0', '');
            return mins + ' Menit (' + jam + ' Jam)';
        }

        if (key === 'icon_symbol') {
            const symbols = {
                'ombak': '🌊 Ombak',
                'feri': '🚢 Feri',
                'kuliner': '🍽️ Kuliner',
                'ikon': '⭐ Ikon',
                'belanja': '🛍️ Belanja',
                'alam': '🌴 Alam'
            };
            return symbols[val] || String(val);
        }

        if (key === 'type') {
            const types = {
                'attraction': 'Tempat Wisata',
                'culinary': 'Wisata Kuliner',
                'lodging': 'Akomodasi / Penginapan'
            };
            return types[val] || String(val);
        }

        return String(val);
    }

    function renderDiffValue(val, isNew) {
        if (!val) {
            return `<span class="audit-val-empty">${isNew ? '(Dikosongkan)' : '(Sebelumnya kosong)'}</span>`;
        }
        const cls = isNew ? 'audit-val-new' : 'audit-val-old';
        return `<span class="${cls}">${escapeHtml(val)}</span>`;
    }

    function openHistoryModal(url, subjectTitle) {
        document.getElementById('historyModalSubject').innerText = subjectTitle || 'Destinasi';
        document.getElementById('historyLoadingState').classList.remove('d-none');
        document.getElementById('historyContentContainer').classList.add('d-none');
        document.getElementById('historyContentContainer').innerHTML = '';

        var modalEl = document.getElementById('modalHistory');
        var myModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        myModal.show();

        fetch(url, { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(res => res.json())
            .then(data => {
                document.getElementById('historyLoadingState').classList.add('d-none');
                const container = document.getElementById('historyContentContainer');
                container.classList.remove('d-none');

                if (!data.activities || data.activities.length === 0) {
                    container.innerHTML = `
                        <div class="text-center py-5">
                            <i class="bi bi-clock-history text-muted d-block mb-3" style="font-size: 42px; opacity: 0.4;"></i>
                            <div class="fw-bold fs-6" style="color: #1E293B;">Belum Ada Riwayat Perubahan</div>
                            <p class="text-muted mb-0" style="font-size: 13px;">Data ini belum pernah mengalami modifikasi atau kurasi ulang sejak ditambahkan.</p>
                        </div>
                    `;
                    return;
                }

                let html = '<div class="audit-timeline">';
                data.activities.forEach(item => {
                    let dotIcon = 'bi-pencil-fill';
                    let eventLabel = 'Perubahan Data';
                    let eventIcon = 'bi-pencil-square';

                    if (item.event === 'created') {
                        dotIcon = 'bi-plus-lg';
                        eventLabel = 'Data Ditambahkan';
                        eventIcon = 'bi-plus-circle-fill';
                    } else if (item.event === 'deleted') {
                        dotIcon = 'bi-trash-fill';
                        eventLabel = 'Data Dihapus';
                        eventIcon = 'bi-trash-fill';
                    }

                    const attrs = item.attributes || {};
                    const oldVals = item.old || {};

                    let bodyHtml = '';

                    if (item.event === 'created') {
                        const initKeys = Object.keys(attrs).filter(k => !IGNORED_KEYS.includes(k));
                        bodyHtml += `
                            <div style="background: #F0FDF4; border: 1px solid #DCFCE7; border-radius: 10px; padding: 12px 16px;" class="mb-3">
                                <div class="d-flex align-items-center gap-2 mb-1">
                                    <i class="bi bi-check-circle-fill text-success" style="font-size: 16px;"></i>
                                    <strong style="color: #166534; font-size: 13px;">Data Baru Berhasil Ditambahkan</strong>
                                </div>
                                <div class="text-muted" style="font-size: 12px;">
                                    Data pertama kali diinput ke dalam sistem oleh <strong>${escapeHtml(item.causer)}</strong>.
                                </div>
                            </div>
                        `;
                        if (initKeys.length > 0) {
                            bodyHtml += `
                                <div class="p-3 rounded-3" style="background: #F8FAFC; border: 1px solid #E2E8F0;">
                                    <div class="text-muted fw-bold mb-2" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;">
                                        <i class="bi bi-info-circle me-1"></i>Informasi Awal:
                                    </div>
                                    <div class="row g-2">
                            `;
                            initKeys.forEach(k => {
                                const meta = FIELD_METADATA[k] || { label: k.replace(/_/g, ' '), icon: 'bi-dot' };
                                const valStr = formatRawValue(k, attrs[k]) || '(Tidak diisi)';
                                bodyHtml += `
                                    <div class="col-sm-6">
                                        <div class="p-2 rounded bg-white border d-flex align-items-center justify-content-between" style="font-size: 12px; border-color: #E2E8F0 !important;">
                                            <span class="text-muted"><i class="bi ${meta.icon} me-1"></i>${meta.label}</span>
                                            <span class="fw-semibold text-dark text-end ms-2">${escapeHtml(valStr)}</span>
                                        </div>
                                    </div>
                                `;
                            });
                            bodyHtml += `</div></div>`;
                        }
                    } else if (item.event === 'deleted') {
                        const delKeys = Object.keys(oldVals).filter(k => !IGNORED_KEYS.includes(k));
                        bodyHtml += `
                            <div style="background: #FEF2F2; border: 1px solid #FEE2E2; border-radius: 10px; padding: 12px 16px;" class="mb-3">
                                <div class="d-flex align-items-center gap-2 mb-1">
                                    <i class="bi bi-exclamation-triangle-fill text-danger" style="font-size: 16px;"></i>
                                    <strong style="color: #991B1B; font-size: 13px;">Data Dihapus dari Sistem</strong>
                                </div>
                                <div class="text-muted" style="font-size: 12px;">
                                    Data ini telah dihapus oleh <strong>${escapeHtml(item.causer)}</strong>.
                                </div>
                            </div>
                        `;
                        if (delKeys.length > 0) {
                            bodyHtml += `
                                <div class="p-3 rounded-3" style="background: #F8FAFC; border: 1px solid #E2E8F0;">
                                    <div class="text-muted fw-bold mb-2" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;">
                                        <i class="bi bi-archive me-1"></i>Data Terakhir Sebelum Dihapus:
                                    </div>
                                    <div class="row g-2">
                            `;
                            delKeys.forEach(k => {
                                const meta = FIELD_METADATA[k] || { label: k.replace(/_/g, ' '), icon: 'bi-dot' };
                                const valStr = formatRawValue(k, oldVals[k]) || '(Tidak ada data)';
                                bodyHtml += `
                                    <div class="col-sm-6">
                                        <div class="p-2 rounded bg-white border d-flex align-items-center justify-content-between" style="font-size: 12px; border-color: #E2E8F0 !important;">
                                            <span class="text-muted"><i class="bi ${meta.icon} me-1"></i>${meta.label}</span>
                                            <span class="fw-semibold text-dark text-end ms-2">${escapeHtml(valStr)}</span>
                                        </div>
                                    </div>
                                `;
                            });
                            bodyHtml += `</div></div>`;
                        }
                    } else {
                        // Event UPDATED
                        const dirtyKeys = Object.keys(attrs).filter(k => !IGNORED_KEYS.includes(k));
                        if (dirtyKeys.length === 0) {
                            bodyHtml += `
                                <div class="text-muted fst-italic py-1" style="font-size: 12.5px;">
                                    <i class="bi bi-info-circle me-1"></i>Pembaruan sistem tercatat (tidak ada kolom konten utama yang berubah).
                                </div>
                            `;
                        } else {
                            const textDiffKeys = [];
                            const tableDiffKeys = [];

                            dirtyKeys.forEach(k => {
                                const meta = FIELD_METADATA[k] || { label: k.replace(/_/g, ' '), icon: 'bi-pencil' };
                                const oldVal = oldVals[k];
                                const newVal = attrs[k];
                                const isLong = meta.isLong || 
                                               (typeof newVal === 'string' && newVal.length > 60) || 
                                               (typeof oldVal === 'string' && oldVal.length > 60);

                                if (isLong) {
                                    textDiffKeys.push(k);
                                } else {
                                    tableDiffKeys.push(k);
                                }
                            });

                            // Render table for short fields
                            if (tableDiffKeys.length > 0) {
                                bodyHtml += '<table class="audit-diff-table mb-2">';
                                bodyHtml += '<tbody>';
                                tableDiffKeys.forEach(k => {
                                    const meta = FIELD_METADATA[k] || { label: k.replace(/_/g, ' '), icon: 'bi-dot' };
                                    const oldStr = formatRawValue(k, oldVals[k]);
                                    const newStr = formatRawValue(k, attrs[k]);

                                    bodyHtml += `
                                        <tr class="audit-diff-row">
                                            <td class="audit-diff-label">
                                                <i class="bi ${meta.icon} text-primary me-2"></i>${meta.label}
                                            </td>
                                            <td class="audit-diff-content">
                                                <div class="d-flex align-items-center gap-2 flex-wrap">
                                                    ${renderDiffValue(oldStr, false)}
                                                    <i class="bi bi-arrow-right text-muted" style="font-size: 11px;"></i>
                                                    ${renderDiffValue(newStr, true)}
                                                </div>
                                            </td>
                                        </tr>
                                    `;
                                });
                                bodyHtml += '</tbody></table>';
                            }

                            // Render side-by-side cards for long text fields
                            if (textDiffKeys.length > 0) {
                                textDiffKeys.forEach(k => {
                                    const meta = FIELD_METADATA[k] || { label: k.replace(/_/g, ' '), icon: 'bi-card-text' };
                                    const oldStr = formatRawValue(k, oldVals[k]) || '(Sebelumnya kosong)';
                                    const newStr = formatRawValue(k, attrs[k]) || '(Dikosongkan)';

                                    bodyHtml += `
                                        <div class="audit-text-diff">
                                            <div class="audit-text-diff-title">
                                                <i class="bi ${meta.icon} text-primary me-1"></i> ${meta.label}
                                            </div>
                                            <div class="row g-2">
                                                <div class="col-md-6">
                                                    <div class="text-muted fw-bold mb-1" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;">
                                                        <i class="bi bi-dash-circle text-danger me-1"></i>Sebelumnya
                                                    </div>
                                                    <div class="audit-text-box old">${escapeHtml(oldStr)}</div>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="text-muted fw-bold mb-1" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;">
                                                        <i class="bi bi-check-circle text-success me-1"></i>Menjadi
                                                    </div>
                                                    <div class="audit-text-box new">${escapeHtml(newStr)}</div>
                                                </div>
                                            </div>
                                        </div>
                                    `;
                                });
                            }
                        }
                    }

                    html += `
                        <div class="audit-item">
                            <div class="audit-dot ${item.event}">
                                <i class="bi ${dotIcon}"></i>
                            </div>
                            <div class="audit-card">
                                <div class="audit-card-header">
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="audit-badge-event ${item.event}">
                                            <i class="bi ${eventIcon}"></i> ${eventLabel}
                                        </span>
                                        <span class="fw-bold" style="font-size: 13px; color: #1E293B;">
                                            <i class="bi bi-person-circle text-muted me-1"></i>${escapeHtml(item.causer)}
                                        </span>
                                    </div>
                                    <div class="text-muted" style="font-size: 12px;">
                                        <i class="bi bi-clock me-1"></i>${item.created_at}
                                        ${item.human_time ? `<span class="badge bg-light text-muted border ms-1" style="font-size: 11px; font-weight: 500;">${item.human_time}</span>` : ''}
                                    </div>
                                </div>
                                <div class="audit-card-body">
                                    ${bodyHtml}
                                </div>
                            </div>
                        </div>
                    `;
                });
                html += '</div>';
                container.innerHTML = html;
            })
            .catch(err => {
                document.getElementById('historyLoadingState').classList.add('d-none');
                const container = document.getElementById('historyContentContainer');
                container.classList.remove('d-none');
                container.innerHTML = `
                    <div class="alert alert-danger mb-0" style="font-size: 13px; border-radius: 10px;">
                        <i class="bi bi-exclamation-triangle-fill me-1"></i> Gagal memuat riwayat perubahan: ${escapeHtml(err.message)}
                    </div>
                `;
            });
    }

    function closeSuccessToast() {
        var el = document.getElementById('modalBerhasil');
        if (el) el.remove();
        document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
        document.body.classList.remove('modal-open');
        document.body.style.overflow = '';
    }

    document.addEventListener('DOMContentLoaded', function() {
        var editModalEl = document.getElementById('modalEditTempat');
        if (editModalEl) {
            editModalEl.addEventListener('show.bs.modal', function (event) {
                var button = event.relatedTarget;
                if (button) {
                    openEditPlaceModal(button);
                }
            });
        }

        var successModal = document.getElementById('modalBerhasil');
        if (successModal) {
            setTimeout(function() {
                closeSuccessToast();
            }, 3000);
        }

        @if(request('edit_id') && ($editTarget = \App\Models\Place::with('categories')->find(request('edit_id'))))
            openEditPlaceModal({
                id: '{{ $editTarget->places_id }}',
                name: '{{ addslashes($editTarget->name) }}',
                cat: '{{ $editTarget->categories->first()?->categories_id ?? "" }}',
                kecamatan: '{{ addslashes($editTarget->kecamatan ?? "") }}',
                lat: '{{ $editTarget->lat }}',
                lng: '{{ $editTarget->lng }}',
                address: '{{ addslashes(str_replace(["\r", "\n"], " ", $editTarget->address ?? "")) }}',
                cost: '{{ $editTarget->estimated_cost_idr }}',
                visit: '{{ $editTarget->estimated_visit_minutes }}',
                descId: '{{ addslashes(str_replace(["\r", "\n"], " ", $editTarget->description_override ?? $editTarget->description ?? "")) }}',
                descEn: '{{ addslashes(str_replace(["\r", "\n"], " ", $editTarget->description_en ?? "")) }}',
                outdoor: '{{ $editTarget->is_outdoor ? 1 : 0 }}'
            });
        @endif
    });
</script>
@endpush
