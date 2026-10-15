@extends('admin.layout')

@php
    $idNumber = fn ($number) => number_format((float) $number, 0, ',', '.');
    $typeLabel = match ($place->type) { 'culinary' => 'Kuliner', 'lodging' => 'Hotel', default => 'Wisata' };
    [$costLabel, $costHint] = match ($place->type) {
        'culinary' => ['Biaya makan per orang', 'Perkiraan sekali makan.'],
        'lodging' => ['Harga kamar per malam', 'Harga kamar standar.'],
        default => ['Biaya masuk per orang', 'Isi 0 kalau gratis.'],
    };
    $statusLabel = match ($place->business_status) {
        'closed_temporarily' => 'Tutup sementara',
        'closed_permanently' => 'Tutup permanen',
        default => 'Aktif di katalog',
    };
    $sourceLabel = match (true) {
        str_starts_with((string) $place->external_place_id, 'osm:') => 'Data dari OpenStreetMap',
        $place->source === 'google' => 'Data dari Google Maps',
        default => 'Ditambahkan manual oleh admin',
    };
    $primaryPhoto = $place->photos->first()?->photo_url ?? $place->photo_url;
    $photoCount = $place->photos->count();
    $hasCoordinates = $place->lat !== null && $place->lng !== null;

    $checks = [
        ['label' => 'Biaya', 'done' => $place->estimated_cost_idr !== null,
            'state' => ($place->estimated_cost_idr === null ? 'Belum' : ($place->estimated_cost_idr == 0 ? 'Gratis' : 'Rp ' . $idNumber($place->estimated_cost_idr)))
                . ($place->estimated_cost_is_ai ? ' (AI)' : '')],
        ['label' => 'Lama kunjungan', 'done' => (bool) $place->estimated_visit_minutes,
            'state' => $place->estimated_visit_minutes ? $place->estimated_visit_minutes . ' menit' : 'Belum'],
        ['label' => 'Tag kategori dicek', 'done' => $place->category_tags_reviewed, 'state' => $place->category_tags_reviewed ? 'Sudah' : 'Belum'],
        ['label' => 'Deskripsi English', 'done' => filled($place->description_en), 'state' => filled($place->description_en) ? 'Ada' : 'Belum'],
        ['label' => 'Foto utama', 'done' => $photoCount > 0, 'state' => $photoCount > 0 ? $photoCount . ' foto' : 'Belum'],
    ];
    $doneCount = collect($checks)->where('done', true)->count();

    $fieldLabels = [
        'name' => 'nama', 'type' => 'jenis', 'kecamatan' => 'kecamatan', 'address' => 'alamat', 'estimated_cost_idr' => 'biaya',
        'estimated_visit_minutes' => 'lama kunjungan', 'is_outdoor' => 'area', 'category_tags_reviewed' => 'status tag',
        'description_override' => 'deskripsi', 'description_en' => 'deskripsi English', 'photo_url' => 'foto utama',
    ];
    $formatValue = fn ($field, $value) => match ($field) {
        'estimated_visit_minutes' => $value . ' menit',
        'estimated_cost_idr' => $value === null ? 'kosong' : ($value == 0 ? 'gratis' : 'Rp ' . $idNumber($value)),
        'is_outdoor' => $value ? 'Outdoor' : 'Indoor',
        'category_tags_reviewed' => $value ? 'sudah dicek' : 'belum dicek',
        default => (string) $value,
    };
    $describeActivity = function ($activity) use ($fieldLabels, $formatValue) {
        if ($activity->event === 'created') {
            return 'menambahkan tempat ini';
        }
        if ($activity->event === 'deleted') {
            return 'menghapus tempat ini';
        }
        $new = collect($activity->attribute_changes?->get('attributes') ?? []);
        $old = collect($activity->attribute_changes?->get('old') ?? []);
        $fields = $new->keys();
        if ($fields->count() === 1 && in_array($fields->first(), ['estimated_cost_idr', 'estimated_visit_minutes', 'is_outdoor', 'category_tags_reviewed', 'kecamatan', 'name'], true)) {
            $field = $fields->first();

            return 'mengubah ' . $fieldLabels[$field] . ' ' . $formatValue($field, $old->get($field)) . ' → ' . $formatValue($field, $new->get($field));
        }

        return 'mengubah ' . ($fields->map(fn ($field) => $fieldLabels[$field] ?? $field)->join(', ') ?: 'data');
    };
@endphp

@section('title', 'Edit ' . $place->name)
@section('heading', 'Edit tempat')
@section('subtitle', $statusLabel)
@section('back_url', route('admin.places.index'))
@section('back_label', 'Kelola Tempat')

@push('styles')
<style>
    .pe-page { --pe-ink: #14212f; --pe-muted: #5d6b7c; --pe-soft: #3a4757; --pe-line: #dbe2ec; --pe-fill: #eef2f8; --pe-blue: #2b6fab; --pe-link: #1f5f99;
        display: flex; flex-direction: column; gap: 20px; padding-bottom: 96px; color: var(--pe-ink); }
    .pe-page a { color: var(--pe-link); }
    .pe-page a:hover { color: #16476d; }
    .pe-alert { margin: 0; padding: 12px 16px; border-radius: 14px; font-size: 14px; font-weight: 600; }
    .pe-alert.is-ok { background: #e3f6ec; color: #1d7a55; }
    .pe-alert.is-error { background: #fdecea; color: #b42318; }
    .pe-alert ul { margin: 0; padding-left: 18px; }
    .pe-grid { display: flex; flex-wrap: wrap; align-items: flex-start; gap: 24px; }
    .pe-main { flex: 999 1 560px; min-width: 0; display: flex; flex-direction: column; gap: 20px; }
    .pe-aside { flex: 1 1 320px; min-width: 0; display: flex; flex-direction: column; gap: 20px; }
    .pe-card { padding: 22px; border-radius: 20px; background: #fff; box-shadow: 0 4px 16px rgba(10, 36, 64, .06); display: flex; flex-direction: column; gap: 14px; }
    .pe-card h2 { margin: 0; font-size: 17px; line-height: 24px; font-weight: 700; color: var(--pe-ink); }
    .pe-aside .pe-card { padding: 20px; }
    .pe-aside .pe-card h2 { font-size: 16px; }
    .pe-card-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
    .pe-card-sub { font-size: 13px; color: var(--pe-muted); }

    .pe-summary { flex-direction: row; flex-wrap: wrap; gap: 20px; padding: 20px; }
    .pe-photo { position: relative; width: 200px; height: 140px; flex-shrink: 0; border-radius: 16px; overflow: hidden; background: var(--pe-fill); }
    .pe-photo img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .pe-photo-empty { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; color: var(--pe-muted); font-size: 13px; }
    .pe-photo-empty i { font-size: 26px; }
    .pe-page .pe-photo-link { position: absolute; left: 8px; bottom: 8px; padding: 4px 10px; border-radius: 999px; background: rgba(10, 36, 64, .72); color: #fff; font-size: 11px; font-weight: 700; text-decoration: none; }
    .pe-page .pe-photo-link:hover { background: #0a2440; color: #fff; }
    .pe-facts { flex: 1 1 280px; min-width: 0; display: flex; flex-direction: column; gap: 8px; }
    .pe-name { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
    .pe-name h2 { font-size: 22px; line-height: 28px; font-weight: 800; }
    .pe-rating { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 999px; background: #fff4df; font-size: 12px; font-weight: 700; }
    .pe-rating i { color: #f6b03c; }
    .pe-fact { font-size: 13px; color: var(--pe-soft); }
    .pe-fact.is-muted { color: var(--pe-muted); }
    .pe-lock { align-self: flex-start; display: inline-flex; align-items: center; gap: 6px; margin-top: 4px; padding: 5px 10px; border-radius: 10px; background: var(--pe-fill); font-size: 12px; color: var(--pe-soft); }

    .pe-fields { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
    .pe-field { display: flex; flex-direction: column; gap: 6px; }
    .pe-label { font-size: 13px; font-weight: 600; color: var(--pe-ink); margin: 0; }
    .pe-hint { font-size: 12px; color: var(--pe-muted); }
    .pe-box { height: 48px; display: flex; align-items: center; gap: 8px; padding: 0 14px; border-radius: 12px; background: var(--pe-fill); box-sizing: border-box; }
    .pe-box:focus-within { box-shadow: 0 0 0 3px rgba(43, 111, 171, .35); }
    .pe-box input { flex: 1; min-width: 0; border: 0; background: transparent; font-size: 15px; font-weight: 600; color: var(--pe-ink); outline: none; }
    .pe-box input::-webkit-inner-spin-button, .pe-box input::-webkit-outer-spin-button { -webkit-appearance: none; margin: 0; }
    .pe-box input[type=number] { -moz-appearance: textfield; appearance: textfield; }
    .pe-prefix { font-size: 14px; font-weight: 700; color: var(--pe-muted); }
    .pe-stepper { padding: 0 4px; gap: 0; }
    .pe-stepper input { text-align: center; font-weight: 700; }
    .pe-stepper span { font-size: 13px; color: var(--pe-muted); margin-right: 8px; }
    .pe-step { width: 40px; height: 40px; border: 0; border-radius: 10px; background: #fff; font-size: 18px; font-weight: 700; color: var(--pe-ink); line-height: 1; }
    .pe-step:hover { background: #f5f7fb; }
    .pe-segment { height: 48px; display: flex; padding: 4px; border: 0; border-radius: 12px; background: var(--pe-fill); box-sizing: border-box; margin: 0; }
    .pe-segment label { flex: 1; position: relative; display: flex; align-items: center; justify-content: center; margin: 0; border-radius: 9px; font-size: 13px; font-weight: 600; color: var(--pe-muted); cursor: pointer; }
    .pe-segment input { position: absolute; opacity: 0; pointer-events: none; }
    .pe-segment label:has(input:checked) { background: #fff; box-shadow: 0 1px 4px rgba(10, 36, 64, .12); font-weight: 700; color: var(--pe-ink); }
    .pe-segment label:has(input:focus-visible) { outline: 3px solid rgba(43, 111, 171, .45); }

    .pe-reviewed { display: flex; align-items: center; gap: 8px; margin: 0; padding: 8px 12px; border-radius: 10px; background: #fff4df; font-size: 13px; font-weight: 600; color: #7a4b00; cursor: pointer; }
    .pe-reviewed:has(input:checked) { background: #e3f6ec; color: #1d7a55; }
    .pe-reviewed input { width: 18px; height: 18px; margin: 0; accent-color: var(--pe-blue); }
    .pe-chips { display: flex; flex-wrap: wrap; gap: 8px; }
    .pe-chip { position: relative; display: inline-flex; align-items: center; gap: 6px; height: 38px; padding: 0 14px; margin: 0; border: 1px solid var(--pe-line); border-radius: 999px; background: #fff; color: var(--pe-soft); font-size: 13px; font-weight: 600; cursor: pointer; user-select: none; }
    .pe-chip:hover { border-color: #9fb6cf; }
    .pe-chip input { position: absolute; opacity: 0; pointer-events: none; }
    .pe-chip i { display: none; }
    .pe-chip:has(input:checked) { border-color: var(--pe-blue); background: var(--pe-blue); color: #fff; font-weight: 700; }
    .pe-chip:has(input:checked) i { display: inline; }
    .pe-chip:has(input:focus-visible) { outline: 3px solid rgba(43, 111, 171, .45); outline-offset: 2px; }

    .pe-tabs { display: flex; padding: 3px; border-radius: 999px; background: var(--pe-fill); }
    .pe-tab { height: 30px; padding: 0 14px; border: 0; border-radius: 999px; background: transparent; font-size: 12px; font-weight: 600; color: var(--pe-muted); }
    .pe-tab[aria-selected=true] { background: #fff; font-weight: 700; color: var(--pe-ink); }
    .pe-textarea { width: 100%; box-sizing: border-box; padding: 14px; border: 1px solid var(--pe-line); border-radius: 14px; resize: vertical; font-size: 14px; line-height: 22px; color: var(--pe-ink); }
    .pe-textarea:focus { outline: none; border-color: var(--pe-blue); box-shadow: 0 0 0 3px rgba(43, 111, 171, .2); }
    .pe-desc-foot { display: flex; justify-content: space-between; gap: 12px; font-size: 12px; color: var(--pe-muted); }

    .pe-meter { height: 8px; border-radius: 999px; background: var(--pe-fill); overflow: hidden; }
    .pe-meter div { height: 100%; border-radius: 999px; background: var(--pe-blue); }
    .pe-checks { margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 10px; }
    .pe-checks li { display: flex; align-items: center; gap: 10px; font-size: 13px; }
    .pe-dot { width: 22px; height: 22px; flex-shrink: 0; border-radius: 999px; display: flex; align-items: center; justify-content: center; background: #d48806; color: #fff; font-size: 12px; }
    .pe-dot.is-done { background: #22a06b; }
    .pe-stats { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
    .pe-stat { padding: 14px; border-radius: 14px; background: #f5f7fb; }
    .pe-stat span { display: block; font-size: 12px; color: var(--pe-muted); }
    .pe-stat b { font-size: 22px; }
    .pe-map { padding: 0; gap: 0; overflow: hidden; }
    .pe-map iframe { display: block; width: 100%; height: 160px; border: 0; }
    .pe-map-foot { padding: 12px 16px; display: flex; justify-content: space-between; align-items: center; gap: 12px; font-size: 13px; }
    .pe-map-foot a { font-weight: 700; text-decoration: none; }
    .pe-log { display: flex; flex-direction: column; gap: 2px; padding-left: 12px; border-left: 2px solid var(--pe-line); }
    .pe-log span { font-size: 13px; }
    .pe-log small { font-size: 12px; color: var(--pe-muted); }

    .pe-page #photos { border: 0; border-radius: 20px; box-shadow: 0 4px 16px rgba(10, 36, 64, .06); overflow: hidden; margin-top: 0 !important; }
    .pe-page #photos > .card-header { padding: 18px 22px 0; border: 0; background: #fff; font-size: 17px; font-weight: 700; }
    .pe-page #photos > .card-body { padding: 16px 22px 22px; }
    .pe-ai-badge { align-self: flex-start; display: inline-flex; align-items: center; gap: 6px; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 600; background: #f3ecfd; color: #6a3fb5; }
    .pe-price-button { align-self: flex-start; display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border: 1px solid var(--pe-line); border-radius: 10px; background: #fff; font-size: 13px; font-weight: 600; color: var(--pe-link); }
    .pe-price-button:hover { background: var(--pe-fill); }
    .pe-price-button:disabled { opacity: .6; }
    .pe-price-result { display: flex; flex-direction: column; gap: 10px; padding: 14px 16px; border-radius: 14px; background: var(--pe-fill); font-size: 14px; }
    .pe-price-result p { margin: 0; white-space: pre-line; }
    .pe-price-result.is-error { background: #fdecea; color: #b42318; }
    .pe-price-sources { margin: 0; padding-left: 18px; font-size: 13px; }
    .pe-price-note { font-size: 12px; color: var(--pe-muted); }
    .pe-timeline { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; }
    .pe-entry { position: relative; display: flex; gap: 14px; padding-bottom: 20px; }
    .pe-entry:last-child { padding-bottom: 0; }
    .pe-entry:not(:last-child)::before { content: ""; position: absolute; left: 15px; top: 34px; bottom: 2px; width: 2px; background: var(--pe-line); }
    .pe-entry-icon { width: 32px; height: 32px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; border-radius: 50%; font-size: 14px; background: var(--pe-fill); color: var(--pe-blue); }
    .pe-entry.is-created .pe-entry-icon { background: #e3f6ec; color: #1d7a55; }
    .pe-entry.is-deleted .pe-entry-icon { background: #fdecea; color: #b42318; }
    .pe-entry-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 10px; padding-top: 5px; }
    .pe-entry-head { display: flex; flex-wrap: wrap; align-items: center; gap: 6px 10px; font-size: 14px; }
    .pe-entry-head time { margin-left: auto; font-size: 12px; color: var(--pe-muted); white-space: nowrap; }
    .pe-entry-badge { padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; background: var(--pe-fill); color: var(--pe-blue); }
    .pe-entry.is-created .pe-entry-badge { background: #e3f6ec; color: #1d7a55; }
    .pe-entry.is-deleted .pe-entry-badge { background: #fdecea; color: #b42318; }
    .pe-fields { margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 8px; }
    .pe-fields > div { padding: 8px 12px; border-radius: 10px; background: var(--pe-fill); min-width: 0; }
    .pe-fields dt { font-size: 11px; font-weight: 600; color: var(--pe-muted); text-transform: uppercase; letter-spacing: .04em; }
    .pe-fields dd { margin: 2px 0 0; font-size: 13px; color: var(--pe-ink); overflow-wrap: anywhere; }
    .pe-diffs { list-style: none; margin: 0; padding: 0; border: 1px solid var(--pe-line); border-radius: 12px; overflow: hidden; }
    .pe-diffs li { display: flex; gap: 12px; padding: 10px 14px; font-size: 13px; }
    .pe-diffs li + li { border-top: 1px solid var(--pe-line); }
    .pe-diff-field { flex: 0 0 140px; font-weight: 600; color: var(--pe-soft); }
    .pe-diff-values { flex: 1; min-width: 0; display: flex; flex-wrap: wrap; align-items: baseline; gap: 4px 8px; }
    .pe-diff-values .bi { color: var(--pe-muted); }
    .pe-diff-old, .pe-diff-new { padding: 1px 6px; border-radius: 6px; overflow-wrap: anywhere; display: -webkit-box; -webkit-line-clamp: 4; -webkit-box-orient: vertical; overflow: hidden; }
    .pe-diff-old { background: #fdecea; color: #8a2a20; text-decoration: line-through; text-decoration-color: rgba(138, 42, 32, .4); }
    .pe-diff-new { background: #e3f6ec; color: #17603f; }

    .pe-savebar { position: fixed; left: 76px; right: 0; bottom: 0; z-index: 900; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; padding: 14px 32px; background: rgba(255, 255, 255, .94); border-top: 1px solid #dbe2ec; -webkit-backdrop-filter: blur(8px); backdrop-filter: blur(8px); transition: left .2s ease; }
    .admin-shell:has(.admin-rail.is-expanded) .pe-savebar { left: 240px; }
    .pe-delete { height: 44px; padding: 0 12px; border: 0; border-radius: 12px; background: transparent; font-size: 14px; font-weight: 700; color: #b42318; }
    .pe-delete:hover { background: #fdecea; }
    .pe-dirty { flex: 1; text-align: right; font-size: 13px; color: #5d6b7c; }
    .pe-dirty.is-dirty { color: #7a4b00; font-weight: 600; }
    .pe-btn { height: 44px; padding: 0 18px; border: 0; border-radius: 12px; display: inline-flex; align-items: center; font-size: 14px; font-weight: 700; text-decoration: none; }
    .pe-btn.is-quiet { background: #eef2f8; color: #14212f; }
    .pe-btn.is-quiet:hover { background: #e2e8f1; color: #14212f; }
    .pe-btn.is-primary { padding: 0 20px; background: #2b6fab; color: #fff; }
    .pe-btn.is-primary:hover { background: #245f93; }
    .pe-page button:focus-visible, .pe-savebar button:focus-visible, .pe-savebar a:focus-visible { outline: 3px solid rgba(43, 111, 171, .45); outline-offset: 2px; }
    @media (max-width: 640px) {
        .pe-savebar { padding: 12px 16px; }
        .pe-dirty { flex-basis: 100%; order: -1; text-align: left; }
        .pe-photo { width: 100%; }
    }
    @media (prefers-reduced-motion: reduce) { .pe-savebar { transition: none; } }
</style>
@endpush

@section('content')
<div class="pe-page">
    @if (session('status'))
        <p class="pe-alert is-ok" role="status">{{ session('status') }}</p>
    @endif
    @if (session('error'))
        <p class="pe-alert is-error" role="alert">{{ session('error') }}</p>
    @endif
    @if ($errors->any())
        <div class="pe-alert is-error" role="alert">
            <ul>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="pe-grid">
        <form method="POST" action="{{ route('admin.places.update', $place) }}" id="formEditPlace" class="pe-main">
            @csrf
            @method('PUT')

            <section class="pe-card pe-summary">
                <div class="pe-photo">
                    @if ($primaryPhoto)
                        <img src="{{ $primaryPhoto }}" alt="Foto utama {{ $place->name }}">
                    @else
                        <div class="pe-photo-empty"><i class="bi bi-image" aria-hidden="true"></i>Belum ada foto</div>
                    @endif
                    <a href="#photos" class="pe-photo-link">Kelola foto ({{ $photoCount }})</a>
                </div>
                <div class="pe-facts">
                    <div class="pe-name">
                        <h2>{{ $place->name }}</h2>
                        @if ($place->rating !== null)
                            <span class="pe-rating">
                                <i class="bi bi-star-fill" aria-hidden="true"></i>
                                {{ number_format((float) $place->rating, 1, ',', '.') }}@if ($place->review_count) · {{ $idNumber($place->review_count) }} ulasan @endif
                            </span>
                        @endif
                    </div>
                    <span class="pe-fact">{{ collect([$place->address, $place->kecamatan])->filter()->join(' · ') ?: 'Alamat belum ada' }}</span>
                    <span class="pe-fact is-muted">
                        @if ($hasCoordinates){{ number_format((float) $place->lat, 5, '.', '') }}, {{ number_format((float) $place->lng, 5, '.', '') }} · @endif{{ $typeLabel }}
                    </span>
                    <span class="pe-lock"><i class="bi bi-lock" aria-hidden="true"></i>{{ $sourceLabel }} · nama dan alamat tidak bisa diubah di sini</span>
                </div>
            </section>

            <section class="pe-card">
                <div>
                    <h2>Data kurasi</h2>
                    <span class="pe-card-sub">Dipakai saat membuat rekomendasi itinerary.</span>
                </div>
                <div class="pe-fields">
                    <div class="pe-field">
                        <label for="peCost" class="pe-label">{{ $costLabel }}</label>
                        <div class="pe-box">
                            <span class="pe-prefix" aria-hidden="true">Rp</span>
                            <input id="peCost" type="number" name="estimated_cost_idr" min="0" step="1000" inputmode="numeric" placeholder="Belum ada"
                                value="{{ old('estimated_cost_idr', $place->estimated_cost_idr) }}">
                        </div>
                        <span class="pe-hint">{{ $costHint }}</span>
                        @if ($place->estimated_cost_is_ai)
                            <span class="pe-ai-badge"><i class="bi bi-stars" aria-hidden="true"></i> Perkiraan AI, ubah kalau sudah tahu harga sebenarnya</span>
                        @endif
                        <button type="button" id="pePriceSearch" class="pe-price-button" data-url="{{ route('admin.places.price-search', $place) }}">
                            <i class="bi bi-search" aria-hidden="true"></i> Cari harga di Google
                        </button>
                    </div>
                    <div class="pe-field">
                        <label for="peMinutes" class="pe-label">Lama kunjungan</label>
                        <div class="pe-box pe-stepper">
                            <button type="button" class="pe-step" data-step="-15" aria-label="Kurangi 15 menit">&minus;</button>
                            <input id="peMinutes" type="number" name="estimated_visit_minutes" min="15" step="15" inputmode="numeric"
                                value="{{ old('estimated_visit_minutes', $place->estimated_visit_minutes ?? 60) }}">
                            <span>menit</span>
                            <button type="button" class="pe-step" data-step="15" aria-label="Tambah 15 menit">+</button>
                        </div>
                        <span class="pe-hint">Naik atau turun per 15 menit.</span>
                    </div>
                    <fieldset class="pe-field" style="border: 0; padding: 0; margin: 0;">
                        <legend class="pe-label" style="float: none; width: auto; margin-bottom: 6px;">Area</legend>
                        <div class="pe-segment">
                            <label><input type="radio" name="is_outdoor" value="1" @checked((bool) old('is_outdoor', $place->is_outdoor ?? true))>Outdoor</label>
                            <label><input type="radio" name="is_outdoor" value="0" @checked(! (bool) old('is_outdoor', $place->is_outdoor ?? true))>Indoor</label>
                        </div>
                        <span class="pe-hint">Outdoor ikut peringatan cuaca.</span>
                    </fieldset>
                </div>
                <div id="pePriceResult" class="pe-price-result" hidden aria-live="polite"></div>
            </section>

            <section class="pe-card">
                <div class="pe-card-head">
                    <div>
                        <h2>Kategori</h2>
                        <span class="pe-card-sub">Biru berarti terpasang. Klik untuk memasang atau melepas.</span>
                    </div>
                    <label class="pe-reviewed">
                        <input type="hidden" name="category_tags_reviewed" value="0">
                        <input type="checkbox" name="category_tags_reviewed" value="1" @checked(old('category_tags_reviewed', $place->category_tags_reviewed))>
                        Tandai tag sudah dicek
                    </label>
                </div>
                @php $attachedIds = collect(old('category_ids', $place->categories->pluck('categories_id')->all()))->map(fn ($id) => (int) $id); @endphp
                <div class="pe-chips">
                    @foreach ($categories as $category)
                        <label class="pe-chip">
                            <input type="checkbox" name="category_ids[]" value="{{ $category->categories_id }}" @checked($attachedIds->contains($category->categories_id))>
                            <i class="bi bi-check-lg" aria-hidden="true"></i>{{ $category->name_id }}
                        </label>
                    @endforeach
                </div>
            </section>

            <section class="pe-card">
                <div class="pe-card-head">
                    <h2 id="peDescTitle">Deskripsi</h2>
                    <div class="pe-tabs" role="tablist" aria-labelledby="peDescTitle">
                        <button type="button" class="pe-tab" role="tab" id="peTabId" aria-controls="pePanelId" aria-selected="true">Indonesia</button>
                        <button type="button" class="pe-tab" role="tab" id="peTabEn" aria-controls="pePanelEn" aria-selected="false" tabindex="-1">English</button>
                    </div>
                </div>
                <div id="pePanelId" role="tabpanel" aria-labelledby="peTabId">
                    <textarea name="description_override" class="pe-textarea" rows="6" aria-labelledby="peTabId"
                        placeholder="{{ $place->description ?: 'Tulis deskripsi tempat ini.' }}">{{ old('description_override', $place->description_override) }}</textarea>
                </div>
                <div id="pePanelEn" role="tabpanel" aria-labelledby="peTabEn" hidden>
                    <textarea name="description_en" class="pe-textarea" rows="6" aria-labelledby="peTabEn"
                        placeholder="Write the English description of this place.">{{ old('description_en', $place->description_en) }}</textarea>
                </div>
                <div class="pe-desc-foot">
                    <span id="peDescHint">Kosongkan untuk memakai deskripsi otomatis dari Gemini.</span>
                    <span id="peDescCount" aria-live="polite"></span>
                </div>
            </section>
        </form>

        <aside class="pe-aside">
            <section class="pe-card">
                <div class="pe-card-head"><h2>Kelengkapan</h2><b>{{ $doneCount }} / {{ count($checks) }}</b></div>
                <div class="pe-meter" role="meter" aria-label="Kelengkapan data" aria-valuemin="0" aria-valuemax="{{ count($checks) }}" aria-valuenow="{{ $doneCount }}">
                    <div style="width: {{ round($doneCount / count($checks) * 100) }}%"></div>
                </div>
                <ul class="pe-checks">
                    @foreach ($checks as $check)
                        <li>
                            <span class="pe-dot {{ $check['done'] ? 'is-done' : '' }}" aria-hidden="true"><i class="bi {{ $check['done'] ? 'bi-check-lg' : 'bi-exclamation-lg' }}"></i></span>
                            <span style="flex: 1">{{ $check['label'] }}</span>
                            <span class="pe-card-sub" style="font-size: 12px">{{ $check['state'] }}</span>
                        </li>
                    @endforeach
                </ul>
            </section>

            <section class="pe-card">
                <h2>Popularitas</h2>
                <div class="pe-stats">
                    <div class="pe-stat"><span>Disimpan ke wishlist</span><b>{{ $idNumber($place->wishlisted_in_count) }}</b></div>
                    <div class="pe-stat"><span>Masuk itinerary</span><b>{{ $idNumber($place->itinerary_items_count) }}</b></div>
                </div>
            </section>

            @if ($hasCoordinates)
                @php
                    $lat = (float) $place->lat;
                    $lng = (float) $place->lng;
                    $embedUrl = 'https://www.openstreetmap.org/export/embed.html?' . http_build_query([
                        'bbox' => implode(',', [$lng - 0.006, $lat - 0.004, $lng + 0.006, $lat + 0.004]),
                        'layer' => 'mapnik',
                        'marker' => $lat . ',' . $lng,
                    ]);
                @endphp
                <section class="pe-card pe-map">
                    <iframe src="{{ $embedUrl }}" title="Peta lokasi {{ $place->name }}" loading="lazy"></iframe>
                    <div class="pe-map-foot">
                        <span class="pe-card-sub">{{ $place->kecamatan ?: 'Batam' }}</span>
                        <a href="https://www.openstreetmap.org/?mlat={{ $lat }}&amp;mlon={{ $lng }}#map=17/{{ $lat }}/{{ $lng }}" target="_blank" rel="noopener">Buka di peta</a>
                    </div>
                </section>
            @endif

            <section class="pe-card">
                <h2>Riwayat perubahan</h2>
                @forelse ($activities->take(3) as $activity)
                    <div class="pe-log">
                        <span><b>{{ $activity->causer?->name ?? 'Sistem' }}</b> {{ $describeActivity($activity) }}</span>
                        <small>{{ $activity->created_at->translatedFormat('j M Y, H.i') }}</small>
                    </div>
                @empty
                    <span class="pe-card-sub">Belum ada perubahan.</span>
                @endforelse
                @if ($activities->count() > 3)
                    <a href="#riwayat" style="font-size: 13px; font-weight: 700; text-decoration: none">Lihat semua riwayat ({{ $activities->count() }})</a>
                @endif
            </section>
        </aside>
    </div>

    @include('admin.places.photos', ['place' => $place])

    <section class="pe-card pe-history" id="riwayat">
        @include('admin.partials.activity-log', [
            'activities' => $activities,
            'fieldLabels' => $fieldLabels,
            'formatValue' => $formatValue,
            'describeActivity' => $describeActivity,
        ])
    </section>
</div>

<form id="formDeletePlaceAction" method="POST" action="{{ route('admin.places.destroy', $place) }}" class="d-none">
    @csrf
    @method('DELETE')
</form>

<div class="pe-savebar">
    <button type="button" class="pe-delete" id="peDelete">Hapus dari katalog</button>
    <span class="pe-dirty" id="peDirty" aria-live="polite">Belum ada perubahan</span>
    <a href="{{ route('admin.places.index') }}" class="pe-btn is-quiet">Batal</a>
    <button type="submit" form="formEditPlace" class="pe-btn is-primary">Simpan perubahan</button>
</div>
@endsection

@push('scripts')
<script>
    (function () {
        var form = document.getElementById('formEditPlace');
        var minutes = document.getElementById('peMinutes');

        document.querySelectorAll('.pe-step').forEach(function (button) {
            button.addEventListener('click', function () {
                var step = parseInt(button.dataset.step, 10);
                minutes.value = Math.max(15, (parseInt(minutes.value, 10) || 60) + step);
                minutes.dispatchEvent(new Event('input', { bubbles: true }));
            });
        });

        var tabs = [document.getElementById('peTabId'), document.getElementById('peTabEn')];
        var count = document.getElementById('peDescCount');
        var hint = document.getElementById('peDescHint');
        function activePanel() {
            return document.getElementById(tabs.find(function (t) { return t.getAttribute('aria-selected') === 'true'; }).getAttribute('aria-controls'));
        }
        function updateCount() {
            var length = activePanel().querySelector('textarea').value.length;
            count.textContent = length.toLocaleString('id-ID') + ' karakter';
        }
        function selectTab(tab) {
            tabs.forEach(function (t) {
                var selected = t === tab;
                t.setAttribute('aria-selected', selected ? 'true' : 'false');
                t.tabIndex = selected ? 0 : -1;
                document.getElementById(t.getAttribute('aria-controls')).hidden = !selected;
            });
            hint.textContent = tab.id === 'peTabId'
                ? 'Kosongkan untuk memakai deskripsi otomatis dari Gemini.'
                : 'Ditampilkan saat aplikasi memakai bahasa Inggris.';
            updateCount();
        }
        tabs.forEach(function (tab, i) {
            tab.addEventListener('click', function () { selectTab(tab); });
            tab.addEventListener('keydown', function (e) {
                if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
                    var next = tabs[(i + 1) % tabs.length];
                    selectTab(next);
                    next.focus();
                }
            });
        });
        form.addEventListener('input', function (e) { if (e.target.tagName === 'TEXTAREA') updateCount(); });
        updateCount();

        function snapshot() {
            var values = {};
            Array.prototype.forEach.call(form.elements, function (el) {
                if (!el.name || el.name === '_token' || el.name === '_method' || el.type === 'hidden') return;
                if ((el.type === 'checkbox' || el.type === 'radio') && !el.checked) {
                    values[el.name] = values[el.name] || [];
                    return;
                }
                (values[el.name] = values[el.name] || []).push(el.value);
            });
            Object.keys(values).forEach(function (k) { values[k] = values[k].join(','); });
            return values;
        }
        var initial = snapshot();
        var dirty = document.getElementById('peDirty');
        var submitting = false;
        function changedCount() {
            var current = snapshot();
            return Object.keys(current).filter(function (k) { return current[k] !== initial[k]; }).length;
        }
        function updateDirty() {
            var n = changedCount();
            dirty.textContent = n === 0 ? 'Belum ada perubahan' : n + ' perubahan belum disimpan';
            dirty.classList.toggle('is-dirty', n > 0);
        }
        form.addEventListener('input', updateDirty);
        form.addEventListener('change', updateDirty);
        form.addEventListener('submit', function () { submitting = true; });
        window.addEventListener('beforeunload', function (e) {
            if (!submitting && changedCount() > 0) {
                e.preventDefault();
                e.returnValue = '';
            }
        });

        var priceButton = document.getElementById('pePriceSearch');
        var priceResult = document.getElementById('pePriceResult');
        function priceMessage(text, isError) {
            var paragraph = document.createElement('p');
            paragraph.textContent = text;
            priceResult.classList.toggle('is-error', isError);
            priceResult.replaceChildren(paragraph);
            priceResult.hidden = false;
        }
        // Built with textContent only; the Search Suggestions are Google's own
        // markup, shown unaltered as the Gemini terms require, in a shadow root
        // so their styles stay apart from the page.
        function showPrice(body) {
            priceMessage(body.text || 'Gemini tidak memberi jawaban, coba lagi.', false);
            if (body.sources && body.sources.length) {
                var list = document.createElement('ol');
                list.className = 'pe-price-sources';
                body.sources.forEach(function (source) {
                    var link = document.createElement('a');
                    link.href = source.url;
                    link.target = '_blank';
                    link.rel = 'noopener';
                    link.textContent = source.title;
                    var item = document.createElement('li');
                    item.appendChild(link);
                    list.appendChild(item);
                });
                priceResult.appendChild(list);
            }
            if (body.search_suggestions) {
                var host = document.createElement('div');
                host.attachShadow({ mode: 'open' }).innerHTML = body.search_suggestions;
                priceResult.appendChild(host);
            }
            var note = document.createElement('span');
            note.className = 'pe-price-note';
            note.textContent = 'Jawaban ini tidak disimpan. Ketik sendiri harganya di kolom di atas.';
            priceResult.appendChild(note);
        }
        priceButton.addEventListener('click', function () {
            priceButton.disabled = true;
            priceResult.classList.remove('is-error');
            priceResult.innerHTML = '<p><span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Mencari harga...</p>';
            priceResult.hidden = false;
            fetch(priceButton.dataset.url, { headers: { Accept: 'application/json' } })
                .then(function (response) {
                    return response.json().then(function (body) {
                        if (!response.ok) throw new Error(body.message || 'Pencarian harga gagal, coba lagi.');
                        return body;
                    });
                })
                .then(showPrice)
                .catch(function (error) { priceMessage(error.message || 'Pencarian harga gagal, coba lagi.', true); })
                .finally(function () { priceButton.disabled = false; });
        });

        document.getElementById('peDelete').addEventListener('click', function () {
            if (confirm(@json('Hapus "' . $place->name . '" dari katalog? Tempat ini tidak akan muncul lagi di aplikasi.'))) {
                submitting = true;
                document.getElementById('formDeletePlaceAction').submit();
            }
        });
    })();
</script>
@endpush
