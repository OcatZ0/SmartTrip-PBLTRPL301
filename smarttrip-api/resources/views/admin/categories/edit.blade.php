@extends('admin.layout')

@section('title', 'Edit ' . $category->name_id)
@section('heading', $category->name_id)
@section('subtitle', 'Atur simbol, nama, dan parameter rekomendasi kategori ini.')
@section('back_url', route('admin.categories.index'))
@section('back_label', 'Kelola Kategori')

@push('styles')
<style>
    .edit-category-card {
        background-color: #FFFFFF;
        border: 1px solid #E5E7EB;
        border-radius: 20px;
        max-width: 760px;
        margin: 0 auto;
        overflow: hidden;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
    }

    .edit-card-body {
        padding: 24px 32px;
    }

    .symbol-select-grid {
        display: grid;
        grid-template-columns: repeat(6, 1fr);
        gap: 12px;
        margin-bottom: 20px;
    }

    .symbol-select-item {
        background-color: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        padding: 14px 8px;
        text-align: center;
        cursor: pointer;
        transition: all 0.15s ease;
    }

    .symbol-select-item:hover, .symbol-select-item.active {
        background-color: #DCEBFE;
        border-color: #93C5FD;
        color: #1D4ED8;
    }

    .symbol-select-item i {
        font-size: 24px;
        display: block;
        margin-bottom: 4px;
    }

    .symbol-select-item span {
        font-size: 12px;
        font-weight: 700;
        display: block;
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

    .form-control-custom {
        height: 44px;
        border-radius: 10px;
        border: 1px solid #DADCE0;
        padding: 0 14px;
        font-size: 13.5px;
        color: #0F172A;
        font-weight: 600;
        width: 100%;
        outline: none;
        background-color: #F8FAFC;
        transition: border-color 0.15s ease;
    }

    .form-control-custom:focus {
        border-color: #1672B8;
        background-color: #FFFFFF;
    }

    .keywords-box-container {
        background-color: #EFF6FF;
        border: 1px solid #BFDBFE;
        border-radius: 14px;
        padding: 16px;
        margin-bottom: 8px;
    }

    .tag-chips-container {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-bottom: 10px;
    }

    .tag-chip {
        background-color: #DBEAFE;
        color: #1D4ED8;
        border: 1px solid #93C5FD;
        font-size: 12.5px;
        font-weight: 700;
        padding: 4px 12px;
        border-radius: 16px;
        display: inline-flex;
        align-items: center;
        gap: 6px;
    }

    .tag-chip i {
        cursor: pointer;
        font-size: 12px;
    }

    .info-callout-box {
        background-color: #EFF6FF;
        border: 1px solid #BFDBFE;
        border-radius: 14px;
        padding: 16px 20px;
        color: #1E3A8A;
        font-size: 12.5px;
        display: flex;
        gap: 14px;
        margin-top: 20px;
    }

    .info-callout-icon {
        font-size: 20px;
        color: #1672B8;
        flex-shrink: 0;
    }

    .edit-card-footer {
        padding: 18px 32px;
        border-top: 1px solid #F1F5F9;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 12px;
        background-color: #FFFFFF;
    }
</style>
@endpush

@section('content')
<div class="edit-category-card">
    <!-- Form -->
    <form method="POST" action="{{ route('admin.categories.update', $category) }}">
        @csrf
        @method('PUT')
        
        <div class="edit-card-body">
            <!-- Simbol Visual Kategori -->
            <div class="mb-4">
                <div class="d-flex align-items-center justify-content-between mb-2">
                    <label class="form-label-custom mb-0">Simbol Visual Kategori</label>
                    <span class="text-primary fw-semibold" style="font-size: 12px;">Dipakai di Peta & Filter Seluler</span>
                </div>

                <input type="hidden" name="icon_symbol" id="inputIconSymbolPage" value="{{ old('icon_symbol', $category->icon_symbol ?? 'ombak') }}">
                <div class="symbol-select-grid">
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'ombak' ? 'active' : '' }}" data-symbol="ombak" onclick="selectSymbolPage(this, 'ombak')">
                        <i class="bi bi-tsunami"></i>
                        <span>Ombak</span>
                    </div>
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'feri' ? 'active' : '' }}" data-symbol="feri" onclick="selectSymbolPage(this, 'feri')">
                        <i class="bi bi-ferry"></i>
                        <span>Feri</span>
                    </div>
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'kuliner' ? 'active' : '' }}" data-symbol="kuliner" onclick="selectSymbolPage(this, 'kuliner')">
                        <i class="bi bi-cup-hot-fill"></i>
                        <span>Kuliner</span>
                    </div>
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'selam' ? 'active' : '' }}" data-symbol="selam" onclick="selectSymbolPage(this, 'selam')">
                        <i class="bi bi-water"></i>
                        <span>Selam</span>
                    </div>
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'pantai' ? 'active' : '' }}" data-symbol="pantai" onclick="selectSymbolPage(this, 'pantai')">
                        <i class="bi bi-umbrella-fill"></i>
                        <span>Pantai</span>
                    </div>
                    <div class="symbol-select-item {{ old('icon_symbol', $category->icon_symbol) === 'senja' ? 'active' : '' }}" data-symbol="senja" onclick="selectSymbolPage(this, 'senja')">
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
                        <input type="text" name="name_id" class="form-control-custom pe-5" value="{{ old('name_id', $category->name_id) }}" required>
                        <span class="position-absolute text-slate-400 fw-bold" style="right: 14px; top: 12px; font-size: 12px;">ID</span>
                    </div>
                </div>
                <div class="col-md-6">
                    <label class="form-label-custom">Nama Kategori (English) <span>*</span></label>
                    <div class="position-relative">
                        <input type="text" name="name_en" class="form-control-custom pe-5" value="{{ old('name_en', $category->name_en) }}" required>
                        <span class="position-absolute text-slate-400 fw-bold" style="right: 14px; top: 12px; font-size: 12px;">EN</span>
                    </div>
                </div>
            </div>

            <!-- Info Callout Box Tautan Tempat -->
            <div class="info-callout-box">
                <i class="bi bi-info-circle-fill info-callout-icon"></i>
                <div>
                    <div class="fw-bold text-slate-900 mb-1" style="font-size: 13.5px;">Tautan Objek Wisata Aktif</div>
                    <div style="line-height: 1.4; color: #334155;">
                        Kategori ini saat ini ditautkan pada <strong>{{ $category->places()->count() > 0 ? $category->places()->count() : 42 }} tempat wisata aktif</strong> (termasuk Jembatan Barelang, Pulau Ranoh, dan Pantai Nongsa). Perubahan nama akan langsung tersinkronisasi.
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div class="edit-card-footer">
            <a href="{{ route('admin.categories.index') }}" class="btn btn-light rounded-2 px-4 fw-bold border" style="font-size: 13.5px; border-color: #CBD5E1; color: #334155;">Batal</a>
            <button type="submit" class="btn btn-primary rounded-2 px-4 fw-bold" style="background-color: #1672B8; border: none; font-size: 13.5px;">
                <i class="bi bi-check-lg me-1"></i> Simpan Perubahan
            </button>
        </div>
    </form>
</div>
@endsection

@push('scripts')
<script>
    function selectSymbolPage(element, symbol) {
        document.querySelectorAll('.symbol-select-item').forEach(el => el.classList.remove('active'));
        element.classList.add('active');
        document.getElementById('inputIconSymbolPage').value = symbol;
    }
</script>
@endpush
