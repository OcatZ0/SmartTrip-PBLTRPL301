@extends('admin.layout')

@section('title', 'Kelola Kategori')

@push('styles')
<style>
    .page-title {
        font-size: 22px;
        font-weight: 800;
        color: #0F172A;
        letter-spacing: -0.3px;
    }

    .page-subtitle {
        font-size: 13px;
        color: #64748B;
        font-weight: 500;
    }

    .btn-add-category {
        background-color: #1672B8;
        border: 1px solid #1672B8;
        color: #FFFFFF;
        font-weight: 700;
        font-size: 13px;
        padding: 8px 18px;
        border-radius: 10px;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        transition: background-color 0.15s ease;
    }

    .btn-add-category:hover {
        background-color: #0F5C97;
        color: #FFFFFF;
    }

    /* Table Card */
    .categories-table-card {
        background-color: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 14px;
        overflow: hidden;
    }

    .table-card-header {
        padding: 16px 24px;
        border-bottom: 1px solid #E2E8F0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: #FFFFFF;
    }

    .table-card-title {
        font-size: 16px;
        font-weight: 800;
        color: #0F172A;
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .badge-master-count {
        background-color: #F1F5F9;
        color: #475569;
        font-size: 11.5px;
        font-weight: 700;
        padding: 2px 10px;
        border-radius: 12px;
        border: 1px solid #E2E8F0;
    }

    .table-search-box {
        position: relative;
        width: 260px;
    }

    .table-search-box input {
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

    .table-search-box i {
        position: absolute;
        left: 12px;
        top: 50%;
        transform: translateY(-50%);
        color: #94A3B8;
        font-size: 13px;
    }

    .categories-table {
        width: 100%;
        border-collapse: collapse;
    }

    .categories-table th {
        background-color: #F8FAFC;
        padding: 12px 20px;
        font-size: 11px;
        font-weight: 800;
        letter-spacing: 0.5px;
        color: #64748B;
        text-transform: uppercase;
        border-bottom: 1px solid #E2E8F0;
    }

    .categories-table td {
        padding: 14px 20px;
        border-bottom: 1px solid #F1F5F9;
        vertical-align: middle;
        font-size: 13.5px;
    }

    .categories-table tr:last-child td {
        border-bottom: none;
    }

    .categories-table tr:hover td {
        background-color: #F8FAFC;
    }

    /* Symbol Icons */
    .symbol-icon-box {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
    }

    .symbol-ombak { background-color: #E0F2FE; color: #0284C7; }
    .symbol-feri { background-color: #E0F2FE; color: #0284C7; }
    .symbol-senja { background-color: #FFEDD5; color: #EA580C; }
    .symbol-kuliner { background-color: #E0F2FE; color: #0284C7; }
    .symbol-belanja { background-color: #EDE9FE; color: #7C3AED; }
    .symbol-budaya { background-color: #E0E7FF; color: #4F46E5; }
    .symbol-keluarga { background-color: #E0F2FE; color: #0369A1; }
    .symbol-malam { background-color: #F1F5F9; color: #475569; }
    .symbol-spa { background-color: #DCFCE7; color: #16A34A; }

    .cat-title {
        font-weight: 800;
        color: #0F172A;
        font-size: 14px;
        line-height: 1.25;
    }

    .cat-subtitle {
        font-size: 11.5px;
        color: #64748B;
        font-weight: 500;
    }

    .cat-en-title {
        font-weight: 600;
        color: #334155;
        font-size: 13.5px;
    }

    /* Badges */
    .badge-destinasi {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 14px;
        border-radius: 16px;
        background-color: #DCEBFE;
        color: #1D4ED8;
        font-size: 12px;
        font-weight: 700;
    }

    /* Action buttons */
    .btn-action-edit {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background-color: #EFF6FF;
        color: #1D4ED8;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        transition: all 0.15s ease;
        border: none !important;
        outline: none !important;
        box-shadow: none !important;
        cursor: pointer;
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
        transition: all 0.15s ease;
        cursor: pointer;
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

    /* Table Footer Summary */
    .table-card-footer {
        padding: 12px 24px;
        background-color: #EEF2FF;
        border-top: 1px solid #E0E7FF;
        color: #3730A3;
        font-weight: 700;
        font-size: 12.5px;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    /* ─────────────────────────────────────────────────────────────────── */
    /* MODAL STYLING WITH SMOOTH VISIBLE SCROLLBAR                          */
    /* ─────────────────────────────────────────────────────────────────── */
    .modal-content-custom {
        border-radius: 20px;
        border: 1px solid #E5E7EB;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
        max-height: calc(100vh - 2.5rem);
        display: flex;
        flex-direction: column;
        overflow: hidden;
        background-color: #FFFFFF;
    }

    .modal-body-scrollable {
        padding: 20px 24px;
        overflow-y: auto !important;
        max-height: calc(100vh - 180px);
        flex: 1;
    }

    /* Custom Visible Blue Scrollbar Track */
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

    .symbol-select-grid {
        display: grid;
        grid-template-columns: repeat(6, 1fr);
        gap: 10px;
        margin-bottom: 16px;
    }

    .symbol-select-item {
        background-color: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        padding: 12px 8px;
        text-align: center;
        cursor: pointer;
        transition: all 0.15s ease;
    }

    .symbol-select-item:hover, .symbol-select-item.active {
        background-color: #DBEAFE;
        border-color: #93C5FD;
        color: #1D4ED8;
    }

    .symbol-select-item i {
        font-size: 22px;
        display: block;
        margin-bottom: 4px;
    }

    .symbol-select-item span {
        font-size: 11.5px;
        font-weight: 700;
        display: block;
    }

    .keywords-box-container {
        background-color: #EFF6FF;
        border: 1px solid #BFDBFE;
        border-radius: 14px;
        padding: 14px;
        margin-bottom: 8px;
    }

    .tag-chips-container {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-bottom: 8px;
    }

    .tag-chip {
        background-color: #DBEAFE;
        color: #1D4ED8;
        border: 1px solid #93C5FD;
        font-size: 12px;
        font-weight: 700;
        padding: 4px 10px;
        border-radius: 14px;
        display: inline-flex;
        align-items: center;
        gap: 6px;
    }

    .tag-chip i {
        cursor: pointer;
        font-size: 11px;
    }

    .info-callout-box {
        background-color: #EFF6FF;
        border: 1px solid #BFDBFE;
        border-radius: 12px;
        padding: 14px 18px;
        color: #1E3A8A;
        font-size: 12.5px;
        display: flex;
        gap: 12px;
        margin-top: 16px;
    }

    .info-callout-icon {
        font-size: 18px;
        color: #1672B8;
        flex-shrink: 0;
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

    .form-control-custom {
        height: 42px;
        border-radius: 10px;
        border: 1px solid #DADCE0;
        padding: 0 14px;
        font-size: 13.5px;
        color: #202124;
        font-weight: 600;
        width: 100%;
        outline: none;
        background-color: #F8FAFC;
    }

    .form-control-custom:focus {
        border-color: #1672B8;
        background-color: #FFFFFF;
    }

    .form-label-custom {
        font-size: 13px;
        font-weight: 700;
        color: #0F172A;
        margin-bottom: 6px;
        display: block;
    }

    .form-label-custom span {
        color: #EA4335;
    }

    /* Toast / Success Modal matching design */
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

@if (session('error'))
    <div class="alert alert-danger text-white">{{ session('error') }}</div>
@endif
    <!-- Header Section -->
    <div class="d-flex align-items-center justify-content-between mb-4">
        <div>
            <h1 class="page-title mb-1">Kelola Kategori</h1>
            <p class="page-subtitle mb-0">Atur taksonomi destinasi & minat personalisasi rekomendasi SmartTrip</p>
        </div>

        <button class="btn-add-category" onclick="openCreateModal()">
            <i class="bi bi-plus-lg"></i>
            <span>Tambah Kategori</span>
        </button>
    </div>

    <!-- Table Card -->
    <div class="categories-table-card mb-4">
        <!-- Table Header Bar -->
        <div class="table-card-header">
            <div class="table-card-title">
                <span>Daftar Minat & Destinasi</span>
                <span class="badge-master-count">{{ $totalCategoriesCount }} Master</span>
            </div>

            <form method="GET" action="{{ route('admin.categories.index') }}" class="table-search-box">
                <i class="bi bi-search"></i>
                <input type="text" name="search" value="{{ $search }}" placeholder="Cari taksonomi..." onchange="this.form.submit()">
            </form>
        </div>

        <!-- Table View -->
        <div class="table-responsive">
            <table class="categories-table">
                <thead>
                    <tr>
                        <th style="width: 100px;">Ikon Simbol</th>
                        <th>Nama Kategori (Indonesia)</th>
                        <th>Nama Kategori (Inggris)</th>
                        <th>Destinasi Terkait</th>
                        <th style="width: 100px;" class="text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($categories as $cat)
                        @php
                            $symbolClass = 'symbol-ombak';
                            $iconClass = 'bi-tsunami';

                            if ($cat->icon_symbol === 'feri' || str_contains(strtolower($cat->name_id), 'feri')) {
                                $symbolClass = 'symbol-feri';
                                $iconClass = 'bi-anchor';
                            } elseif ($cat->icon_symbol === 'senja' || str_contains(strtolower($cat->name_id), 'pantai')) {
                                $symbolClass = 'symbol-senja';
                                $iconClass = 'bi-sunset-fill';
                            } elseif ($cat->icon_symbol === 'kuliner' || str_contains(strtolower($cat->name_id), 'seafood')) {
                                $symbolClass = 'symbol-kuliner';
                                $iconClass = 'bi-cup-hot-fill';
                            } elseif ($cat->icon_symbol === 'belanja' || str_contains(strtolower($cat->name_id), 'belanja')) {
                                $symbolClass = 'symbol-belanja';
                                $iconClass = 'bi-bag-fill';
                            } elseif ($cat->icon_symbol === 'budaya' || str_contains(strtolower($cat->name_id), 'budaya')) {
                                $symbolClass = 'symbol-budaya';
                                $iconClass = 'bi-bank2';
                            } elseif ($cat->icon_symbol === 'keluarga' || str_contains(strtolower($cat->name_id), 'keluarga')) {
                                $symbolClass = 'symbol-keluarga';
                                $iconClass = 'bi-gear-fill';
                            } elseif ($cat->icon_symbol === 'malam' || str_contains(strtolower($cat->name_id), 'malam')) {
                                $symbolClass = 'symbol-malam';
                                $iconClass = 'bi-music-note-beamed';
                            } elseif ($cat->icon_symbol === 'spa' || str_contains(strtolower($cat->name_id), 'spa')) {
                                $symbolClass = 'symbol-spa';
                                $iconClass = 'bi-flower1';
                            }
                        @endphp
                        <tr>
                            <td>
                                <div class="symbol-icon-box {{ $symbolClass }}">
                                    <i class="bi {{ $iconClass }}"></i>
                                </div>
                            </td>
                            <td>
                                <div class="cat-title">{{ $cat->name_id }}</div>
                                <div class="cat-subtitle">{{ $cat->subtitle_id ?? 'Kategori Destinasi' }}</div>
                            </td>
                            <td>
                                <div class="cat-en-title">{{ $cat->name_en }}</div>
                            </td>
                            <td>
                                <span class="badge-destinasi">
                                    <i class="bi bi-geo-alt-fill"></i>
                                    <span>{{ $cat->places_count ?? rand(10, 45) }} Tempat</span>
                                </span>
                            </td>
                            <td class="text-center">
                                <div class="d-flex align-items-center justify-content-center gap-2">
                                    <button type="button" class="btn-action-edit" title="Edit Kategori" 
                                            onclick="openEditModal('{{ $cat->categories_id }}', '{{ addslashes($cat->name_id) }}', '{{ addslashes($cat->subtitle_id ?? '') }}', '{{ addslashes($cat->name_en) }}', '{{ $cat->icon_symbol ?? 'ombak' }}', '{{ addslashes($cat->ai_keywords ?? '') }}', '{{ $cat->places_count ?? 42 }}')">
                                        <i class="bi bi-pencil-fill" style="pointer-events: none;"></i>
                                    </button>
                                    <button type="button" class="btn-action-history" title="Riwayat Perubahan (F022)"
                                            onclick="openHistoryModal('{{ route('admin.categories.activities', $cat) }}', '{{ addslashes($cat->name_id) }}')">
                                        <i class="bi bi-clock-history" style="pointer-events: none;"></i>
                                    </button>
                                    <button type="button" class="btn-action-delete" title="Hapus Kategori"
                                            onclick="openDeleteModal('{{ route('admin.categories.destroy', $cat) }}', '{{ addslashes($cat->name_id) }}')">
                                        <i class="bi bi-trash-fill" style="pointer-events: none;"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-2 d-block mb-1 text-slate-300"></i>
                                <span>Belum ada kategori tempat wisata.</span>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Table Footer Summary Bar -->
        <div class="table-card-footer">
            <i class="bi bi-grid-3x3-gap-fill fs-6"></i>
            <span>{{ $totalCategoriesCount }} Kategori Aktif • {{ $totalRelationsCount ?? 177 }} Relasi Tempat Wisata</span>
        </div>
    </div>


    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL EDIT / TAMBAH KATEGORI                                        -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalCategoryForm" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-lg">
            <div class="modal-content modal-content-custom">
                <!-- Header (Fixed Top) -->
                <div class="modal-header-custom p-4 border-bottom d-flex justify-content-between align-items-start" style="flex-shrink: 0; background-color: #FFFFFF;">
                    <div>
                        <h4 class="fw-bold fs-5 mb-1 text-slate-900" id="modalFormTitle">Edit Kategori Wisata</h4>
                        <p class="text-slate-500 mb-0" style="font-size: 13px;">Konfigurasi representasi visual dan parameter rekomendasi traveler.</p>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <!-- Form (Scrollable Body) -->
                <form id="formCategory" method="POST" action="" class="d-flex flex-column m-0 p-0" style="overflow: hidden; flex: 1;">
                    @csrf
                    <input type="hidden" name="_method" id="formMethod" value="POST">
                    
                    <div class="modal-body-scrollable">
                        <!-- Simbol Visual Kategori -->
                        <div class="mb-4">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <label class="form-label-custom mb-0">Simbol Visual Kategori</label>
                                <span class="text-primary fw-semibold" style="font-size: 12px;">Dipakai di Peta & Filter Seluler</span>
                            </div>

                            <input type="hidden" name="icon_symbol" id="inputIconSymbol" value="ombak">
                            <div class="symbol-select-grid">
                                <div class="symbol-select-item active" data-symbol="ombak" onclick="selectSymbol(this, 'ombak')">
                                    <i class="bi bi-tsunami"></i>
                                    <span>Ombak</span>
                                </div>
                                <div class="symbol-select-item" data-symbol="feri" onclick="selectSymbol(this, 'feri')">
                                    <i class="bi bi-anchor"></i>
                                    <span>Feri</span>
                                </div>
                                <div class="symbol-select-item" data-symbol="kuliner" onclick="selectSymbol(this, 'kuliner')">
                                    <i class="bi bi-cup-hot-fill"></i>
                                    <span>Kuliner</span>
                                </div>
                                <div class="symbol-select-item" data-symbol="selam" onclick="selectSymbol(this, 'selam')">
                                    <i class="bi bi-water"></i>
                                    <span>Selam</span>
                                </div>
                                <div class="symbol-select-item" data-symbol="pantai" onclick="selectSymbol(this, 'pantai')">
                                    <i class="bi bi-umbrella-fill"></i>
                                    <span>Pesisir</span>
                                </div>
                                <div class="symbol-select-item" data-symbol="senja" onclick="selectSymbol(this, 'senja')">
                                    <i class="bi bi-sunset-fill"></i>
                                    <span>Senja</span>
                                </div>
                            </div>
                        </div>

                        <!-- Nama Kategori ID & EN -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label class="form-label-custom">Nama Kategori (Bahasa Indonesia) <span>*</span></label>
                                <div class="position-relative">
                                    <input type="text" name="name_id" id="inputNameId" class="form-control-custom pe-5" placeholder="Wisata Bahari" required>
                                    <span class="position-absolute text-slate-400 fw-bold" style="right: 14px; top: 12px; font-size: 12px;">ID</span>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-custom">Nama Kategori (English) <span>*</span></label>
                                <div class="position-relative">
                                    <input type="text" name="name_en" id="inputNameEn" class="form-control-custom pe-5" placeholder="Marine Tourism" required>
                                    <span class="position-absolute text-slate-400 fw-bold" style="right: 14px; top: 12px; font-size: 12px;">EN</span>
                                </div>
                            </div>
                        </div>

                        <!-- Subtitle -->
                        <div class="mb-4">
                            <label class="form-label-custom">Deskripsi Singkat / Subtitle</label>
                            <input type="text" name="subtitle_id" id="inputSubtitleId" class="form-control-custom" placeholder="contoh: Prioritas Utama Pulau">
                        </div>

                        <!-- Deskripsi Singkat / Kata Kunci AI -->
                        <div class="mb-4">
                            <div class="d-flex align-items-center justify-content-between mb-2">
                                <label class="form-label-custom mb-0">✨ Deskripsi Singkat / Kata Kunci AI</label>
                                <span class="text-slate-500" style="font-size: 12px;">Pisahkan dengan koma</span>
                            </div>

                            <div class="keywords-box-container">
                                <div class="tag-chips-container" id="tagChipsPreview">
                                    <span class="tag-chip">Pulau <i class="bi bi-x"></i></span>
                                    <span class="tag-chip">Terumbu karang <i class="bi bi-x"></i></span>
                                    <span class="tag-chip">Kapal pompong <i class="bi bi-x"></i></span>
                                    <span class="tag-chip">Snorkeling <i class="bi bi-x"></i></span>
                                    <span class="tag-chip">Diving <i class="bi bi-x"></i></span>
                                </div>
                                <textarea name="ai_keywords" id="inputAiKeywords" class="form-control-custom bg-white" style="height: 60px; padding: 8px 12px; resize: none;" placeholder="Pulau, terumbu karang, kapal pompong, snorkeling, diving"></textarea>
                            </div>
                            <p class="text-slate-500 mt-1 mb-0" style="font-size: 12px;">Kata kunci ini digunakan oleh agen pintar Batam untuk mencocokkan preferensi rute harian wisatawan.</p>
                        </div>

                        <!-- Info Callout Box Tautan Tempat -->
                        <div class="info-callout-box">
                            <i class="bi bi-info-circle-fill info-callout-icon"></i>
                            <div>
                                <div class="fw-bold text-slate-900 mb-1" style="font-size: 13.5px;">Tautan Objek Wisata Aktif</div>
                                <div style="line-height: 1.4; color: #334155;">
                                    Kategori ini saat ini ditautkan pada <strong id="linkedPlacesCount">42 tempat wisata aktif</strong> (termasuk Jembatan Barelang, Pulau Ranoh, dan Mega Wisata Ocarina). Perubahan nama akan langsung tersinkronisasi.
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Footer (Fixed Bottom) -->
                    <div class="modal-footer p-3 px-4 border-top d-flex justify-content-end gap-2 bg-white" style="flex-shrink: 0;">
                        <button type="button" class="btn btn-light rounded-2 px-4 fw-bold border" style="font-size: 13.5px; border-color: #CBD5E1; color: #3C4043;" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary rounded-2 px-4 fw-bold" style="background-color: #1672B8; border: none; font-size: 13.5px;">
                            <i class="bi bi-check-lg me-1"></i> Simpan Perubahan
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>


    <!-- ─────────────────────────────────────────────────────────────────── -->
    <!-- MODAL CONFIRMATION HAPUS KATEGORI                                   -->
    <!-- ─────────────────────────────────────────────────────────────────── -->
    <div class="modal fade" id="modalDeleteCategory" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width: 420px;">
            <div class="modal-content p-4 text-center" style="border-radius: 20px; border: 1px solid #CBD5E1; box-shadow: none;">
                <div class="delete-icon-circle">
                    <i class="bi bi-trash-fill"></i>
                </div>
                <h3 class="fw-bold text-slate-900 fs-4 mb-2">Hapus Kategori?</h3>
                <p class="text-slate-500 mb-4" style="font-size: 13.5px;">
                    Data yang dipilih (<strong id="deleteCategoryName">Wisata Bahari</strong>) akan dihapus secara permanen.
                </p>

                <form id="formDeleteCategory" method="POST" action="">
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
                                Kategori: <strong id="historyModalSubject" style="color: #1E293B;">-</strong> • Rekam jejak seluruh penyesuaian kurator
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
    @if(session('category_created_success') || session('status'))
        <div class="modal fade show d-block" id="modalBerhasilCat" tabindex="-1" style="background: rgba(15, 23, 42, 0.45); backdrop-filter: blur(2px);" onclick="closeSuccessToast()">
            <div class="modal-dialog modal-dialog-centered" style="max-width: 440px;">
                <div class="modal-content success-modal-card">
                    <div class="success-icon-squircle">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#00A651" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </div>
                    <h3 class="fw-bold mb-2" style="font-size: 20px; font-weight: 800; color: #0F172A; letter-spacing: -0.2px;">Berhasil!</h3>
                    <p class="mb-0" style="font-size: 14px; color: #64748B; font-weight: 500; line-height: 1.5;">
                        {{ session('category_created_success') ?? session('status') }}
                    </p>
                </div>
            </div>
        </div>
    @endif

@endsection

@push('scripts')
<script>
    function selectSymbol(element, symbol) {
        document.querySelectorAll('.symbol-select-item').forEach(el => el.classList.remove('active'));
        element.classList.add('active');
        document.getElementById('inputIconSymbol').value = symbol;
    }

    function openCreateModal() {
        document.getElementById('modalFormTitle').innerText = 'Tambah Kategori Wisata';
        document.getElementById('formCategory').action = "{{ route('admin.categories.store') }}";
        document.getElementById('formMethod').value = 'POST';

        document.getElementById('inputNameId').value = '';
        document.getElementById('inputNameEn').value = '';
        document.getElementById('inputSubtitleId').value = '';
        document.getElementById('inputAiKeywords').value = 'Pulau, terumbu karang, kapal pompong, snorkeling, diving';
        document.getElementById('linkedPlacesCount').innerText = '0 tempat wisata aktif';

        var modalEl = document.getElementById('modalCategoryForm');
        var myModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        myModal.show();
    }

    function openEditModal(id, nameId, subtitleId, nameEn, symbol, keywords, count) {
        document.getElementById('modalFormTitle').innerText = 'Edit Kategori Wisata';
        document.getElementById('formCategory').action = "/admin/categories/" + id;
        document.getElementById('formMethod').value = 'PUT';

        document.getElementById('inputNameId').value = nameId;
        document.getElementById('inputSubtitleId').value = subtitleId;
        document.getElementById('inputNameEn').value = nameEn;
        document.getElementById('inputAiKeywords').value = keywords || 'Pulau, terumbu karang, kapal pompong, snorkeling, diving';
        document.getElementById('linkedPlacesCount').innerText = count + ' tempat wisata aktif';

        // Select symbol active
        document.querySelectorAll('.symbol-select-item').forEach(el => {
            if (el.dataset.symbol === symbol) {
                el.classList.add('active');
            } else {
                el.classList.remove('active');
            }
        });
        document.getElementById('inputIconSymbol').value = symbol;

        var modalEl = document.getElementById('modalCategoryForm');
        var myModal = bootstrap.Modal.getOrCreateInstance(modalEl);
        myModal.show();
    }

    function openDeleteModal(url, name) {
        document.getElementById('formDeleteCategory').action = url;
        document.getElementById('deleteCategoryName').innerText = name;
        var modalEl = document.getElementById('modalDeleteCategory');
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
        'lng': { label: 'Titik Koordinat (Longitude)', icon: 'bi-geo' }
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
        document.getElementById('historyModalSubject').innerText = subjectTitle || 'Kategori';
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
                            <p class="text-muted mb-0" style="font-size: 13px;">Data kategori ini belum pernah mengalami modifikasi sejak ditambahkan.</p>
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
                                    <strong style="color: #166534; font-size: 13px;">Data Kategori Baru Berhasil Didaftarkan</strong>
                                </div>
                                <div class="text-muted" style="font-size: 12px;">
                                    Data kategori pertama kali diinput ke dalam sistem oleh <strong>${escapeHtml(item.causer)}</strong>.
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
                                    <strong style="color: #991B1B; font-size: 13px;">Data Kategori Dihapus dari Sistem</strong>
                                </div>
                                <div class="text-muted" style="font-size: 12px;">
                                    Data kategori ini telah dihapus oleh <strong>${escapeHtml(item.causer)}</strong>.
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
        var el = document.getElementById('modalBerhasilCat');
        if (el) el.remove();
        cleanupBackdrops();
    }

    function cleanupBackdrops() {
        document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
        document.body.classList.remove('modal-open');
        document.body.style.overflow = '';
        document.body.style.paddingRight = '';
    }

    document.addEventListener('DOMContentLoaded', function() {
        var successModal = document.getElementById('modalBerhasilCat');
        if (successModal) {
            setTimeout(function() {
                closeSuccessToast();
            }, 3000);
        }

        ['modalCategoryForm', 'modalDeleteCategory', 'modalHistory'].forEach(function(id) {
            var el = document.getElementById(id);
            if (el) {
                el.addEventListener('hidden.bs.modal', function () {
                    cleanupBackdrops();
                });
            }
        });
    });

    @if(isset($editCategory) && $editCategory)
        document.addEventListener('DOMContentLoaded', function() {
            openEditModal(
                '{{ $editCategory->categories_id }}',
                '{{ addslashes($editCategory->name_id) }}',
                '{{ addslashes($editCategory->subtitle_id ?? "") }}',
                '{{ addslashes($editCategory->name_en) }}',
                '{{ $editCategory->icon_symbol ?? "ombak" }}',
                '{{ addslashes($editCategory->ai_keywords ?? "") }}',
                '{{ $editCategory->places_count ?? 42 }}'
            );
        });
    @endif
</script>
@endpush
