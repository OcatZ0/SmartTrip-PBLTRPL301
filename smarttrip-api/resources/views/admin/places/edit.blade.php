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
    // Seven day rows; a stored OSM string they cannot show is listed above them.
    $hourRows = \App\Services\Places\OpeningHours::formRows($place->opening_hours);
    $unreadableHours = filled($place->openingHoursText()) && \App\Services\Places\OpeningHours::periods($place->opening_hours) === null
        ? $place->openingHoursText() : null;

    $checks = [
        ['label' => 'Biaya', 'done' => $place->estimated_cost_idr !== null,
            'state' => $place->estimated_cost_idr === null ? 'Belum' : ($place->estimated_cost_idr == 0 ? 'Gratis' : 'Rp ' . $idNumber($place->estimated_cost_idr))],
        ['label' => 'Lama kunjungan', 'done' => (bool) $place->estimated_visit_minutes,
            'state' => $place->estimated_visit_minutes ? $place->estimated_visit_minutes . ' menit' : 'Belum'],
        ['label' => 'Jam operasional', 'done' => filled($place->openingHoursText()), 'state' => filled($place->openingHoursText()) ? 'Ada' : 'Belum'],
        ['label' => 'Tag kategori dicek', 'done' => $place->category_tags_reviewed, 'state' => $place->category_tags_reviewed ? 'Sudah' : 'Belum'],
        ['label' => 'Deskripsi English', 'done' => filled($place->description_en), 'state' => filled($place->description_en) ? 'Ada' : 'Belum'],
        ['label' => 'Kata kunci pencarian', 'done' => filled($place->search_keywords),
            'state' => filled($place->search_keywords) ? count($place->searchKeywordList()) . ' kata' : 'Belum'],
        ['label' => 'Foto utama', 'done' => $photoCount > 0, 'state' => $photoCount > 0 ? $photoCount . ' foto' : 'Belum'],
    ];
    $doneCount = collect($checks)->where('done', true)->count();

    $fieldLabels = [
        'name' => 'nama', 'type' => 'jenis', 'kecamatan' => 'kecamatan', 'address' => 'alamat', 'estimated_cost_idr' => 'biaya',
        'estimated_visit_minutes' => 'lama kunjungan', 'is_outdoor' => 'area', 'category_tags_reviewed' => 'status tag',
        'description_override' => 'deskripsi', 'description_en' => 'deskripsi English', 'photo_url' => 'foto utama',
        'search_keywords' => 'kata kunci pencarian', 'opening_hours' => 'jam operasional', 'business_status' => 'status',
    ];
    $formatValue = fn ($field, $value) => match ($field) {
        'estimated_visit_minutes' => $value . ' menit',
        'estimated_cost_idr' => $value === null ? 'kosong' : ($value == 0 ? 'gratis' : 'Rp ' . $idNumber($value)),
        'is_outdoor' => $value ? 'Outdoor' : 'Indoor',
        'category_tags_reviewed' => $value ? 'sudah dicek' : 'belum dicek',
        'opening_hours' => is_array($value) ? implode('; ', array_filter(is_array($value['weekday_descriptions'] ?? null) ? $value['weekday_descriptions'] : [$value['osm'] ?? ''], 'is_string')) : (string) $value,
        'business_status' => match ($value) { 'closed_permanently' => 'tutup permanen', 'closed_temporarily' => 'tutup sementara', default => 'aktif' },
        default => is_array($value) ? json_encode($value, JSON_UNESCAPED_UNICODE) : (string) $value,
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
    .pe-kw-chips { display: flex; flex-wrap: wrap; gap: 6px; }
    .pe-kw-chip { display: inline-flex; align-items: center; gap: 4px; height: 30px; padding: 0 6px 0 12px; border-radius: 999px; background: #e7f0f9; color: #1f5f99; font-size: 12.5px; font-weight: 600; }
    .pe-kw-chip button { border: 0; background: transparent; color: inherit; padding: 0 4px; line-height: 1; font-size: 15px; }
    .pe-kw-empty { font-size: 12.5px; color: var(--pe-muted); }
    .pe-hint.is-error { color: #c0392b; font-weight: 600; }
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

    .pe-page #photos { border: 0; border-radius: 20px; box-shadow: 0 4px 16px rgba(10, 36, 64, .06); overflow: hidden; margin-top: 0 !important; }
    .pe-page #photos > .card-header { padding: 18px 22px 0; border: 0; background: #fff; font-size: 17px; font-weight: 700; }
    .pe-page #photos > .card-body { padding: 16px 22px 22px; }
    .pe-price-button { align-self: flex-start; display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border: 1px solid var(--pe-line); border-radius: 10px; background: #fff; font-size: 13px; font-weight: 600; color: var(--pe-link); }
    .pe-price-button:hover { background: var(--pe-fill); }
    .pe-price-button:disabled { opacity: .6; }
    .pe-price-result { display: flex; flex-direction: column; gap: 10px; padding: 14px 16px; border-radius: 14px; background: var(--pe-fill); font-size: 14px; }
    .pe-price-result p { margin: 0; white-space: pre-line; }
    .pe-price-result.is-error { background: #fdecea; color: #b42318; }
    .pe-price-use { align-self: flex-start; }
    .pe-price-note { font-size: 12px; color: var(--pe-muted); }
    /* "Perkiraan data dengan AI": one row per field, then the numbered sources. */
    .pe-hours-section { padding-top: 16px; border-top: 1px solid var(--pe-line); }
    /* Jam operasional: one tile per day, two columns on a wide card. Every tile
       keeps the same three cells (day, state, times or a note), so a day that
       is not "Buka" never shifts the others. */
    .pe-hours { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 430px), 1fr)); gap: 8px 12px; }
    .pe-hours-row { display: grid; grid-template-columns: 62px 128px minmax(0, 1fr); align-items: center; gap: 10px; min-height: 56px; padding: 8px 10px 8px 14px; border-radius: 12px; background: var(--pe-fill); box-sizing: border-box; }
    .pe-hours-row.is-closed { background: #fdf3f2; }
    .pe-hours-day { font-size: 14px; font-weight: 700; color: var(--pe-ink); }
    .pe-hours select, .pe-hours input[type="time"] { width: 100%; height: 40px; padding: 0 10px; border: 1px solid var(--pe-line); border-radius: 10px; background-color: #fff; font-size: 14px; color: var(--pe-ink); box-sizing: border-box; }
    .pe-hours select:focus, .pe-hours input[type="time"]:focus { outline: none; border-color: var(--pe-blue); box-shadow: 0 0 0 3px rgba(43, 111, 171, .2); }
    .pe-hours-slot { min-width: 0; }
    .pe-hours-times { display: grid; grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr); align-items: center; gap: 6px; }
    .pe-hours-times span { color: var(--pe-muted); }
    .pe-hours-times[hidden], .pe-hours-note[hidden] { display: none; }
    .pe-hours-note { font-size: 13px; color: var(--pe-muted); }
    .pe-hours-row.is-closed .pe-hours-note { color: #b42318; font-weight: 600; }
    .pe-hours-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
    .pe-hours-old { margin: 0; padding: 8px 12px; border-radius: 10px; background: var(--pe-fill); font-size: 12px; color: var(--pe-soft); }
    @media (max-width: 575.98px) {
        .pe-hours-row { grid-template-columns: 56px minmax(0, 1fr); padding: 10px; }
        .pe-hours-slot { grid-column: 1 / -1; }
        .pe-hours-note { padding-left: 2px; }
    }
    .pe-data-row { display: grid; grid-template-columns: 130px minmax(0, 1fr) auto; gap: 4px 12px; align-items: start; padding: 10px 0; border-top: 1px solid var(--pe-line); }
    .pe-data-row:first-of-type { border-top: 0; padding-top: 0; }
    .pe-data-label { font-size: 13px; font-weight: 700; color: var(--pe-soft); }
    .pe-data-value { font-weight: 700; color: var(--pe-ink); white-space: pre-line; }
    .pe-data-value.is-empty { font-weight: 500; color: var(--pe-muted); }
    .pe-data-note { display: block; margin-top: 2px; font-size: 12px; font-weight: 500; color: var(--pe-muted); }
    .pe-data-cite { margin-left: 4px; font-size: 11px; font-weight: 700; color: var(--pe-link); }
    .pe-data-closed { margin: 0; padding: 10px 12px; border-radius: 10px; background: #fdecea; color: #912018; font-size: 13px; font-weight: 600; }
    .pe-data-sources { margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 4px; font-size: 12px; }
    .pe-data-sources a { color: var(--pe-link); font-weight: 600; word-break: break-word; }
    .pe-data-sources span { color: var(--pe-muted); }
    .pe-data-actions { display: flex; flex-wrap: wrap; gap: 8px; }
    @media (max-width: 575.98px) {
        .pe-data-row { grid-template-columns: minmax(0, 1fr) auto; }
        .pe-data-label { grid-column: 1 / -1; }
    }
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
    .pe-entry-fields { margin: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 8px; }
    .pe-entry-fields > div { padding: 8px 12px; border-radius: 10px; background: var(--pe-fill); min-width: 0; }
    .pe-entry-fields dt { font-size: 11px; font-weight: 600; color: var(--pe-muted); text-transform: uppercase; letter-spacing: .04em; }
    .pe-entry-fields dd { margin: 2px 0 0; font-size: 13px; color: var(--pe-ink); overflow-wrap: anywhere; }
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
    /* Red at rest (what used to be the hover look); hover deepens it. */
    .pe-delete { width: 44px; height: 44px; padding: 0; border: 0; border-radius: 12px; background: #fdecea; display: inline-flex; align-items: center; justify-content: center; font-size: 18px; color: #b42318; transition: background-color .15s ease, color .15s ease; }
    .pe-delete:hover { background: #f8c9c3; color: #912018; }
    .pe-delete:focus-visible { outline: 3px solid rgba(180, 35, 24, .35); outline-offset: 2px; }
    .pe-dirty { flex: 1; text-align: right; font-size: 13px; color: #5d6b7c; }
    .pe-dirty.is-dirty { color: #7a4b00; font-weight: 600; }
    .pe-btn { height: 44px; padding: 0 18px; border: 0; border-radius: 12px; display: inline-flex; align-items: center; justify-content: center; gap: 8px; font-size: 14px; font-weight: 700; text-decoration: none; }
    .pe-btn.is-quiet { background: #eef2f8; color: #14212f; }
    .pe-btn.is-quiet:hover { background: #e2e8f1; color: #14212f; }
    .pe-btn.is-primary { padding: 0 20px; background: #2b6fab; color: #fff; }
    .pe-btn.is-primary:hover { background: #245f93; }
    .pe-page button:focus-visible, .pe-savebar button:focus-visible, .pe-savebar a:focus-visible { outline: 3px solid rgba(43, 111, 171, .45); outline-offset: 2px; }
    /* The rail is a slide-in menu below 768px, so the save bar spans the full width. */
    @media (max-width: 767.98px) {
        .pe-savebar, .admin-shell:has(.admin-rail.is-expanded) .pe-savebar { left: 0; }
        .pe-page { gap: 16px; padding-bottom: 140px; }
        .pe-card { padding: 16px; border-radius: 16px; }
        .pe-aside .pe-card { padding: 16px; }
        .pe-summary { padding: 16px; gap: 14px; }
        /* Riwayat Perubahan: field name above its old and new values, which stack full width. */
        .pe-entry { gap: 10px; }
        .pe-entry-head time { margin-left: 0; }
        .pe-diffs li { flex-direction: column; gap: 6px; padding: 10px 12px; }
        .pe-diff-field { flex: none; }
        .pe-diff-values { flex-direction: column; align-items: flex-start; gap: 4px; }
        .pe-diff-values .bi { transform: rotate(90deg); }
        .pe-diff-old, .pe-diff-new { max-width: 100%; }
        .pe-entry-fields { grid-template-columns: 1fr; }
    }
    @media (max-width: 640px) {
        .pe-savebar { padding: 12px 16px; }
        .pe-dirty { flex-basis: 100%; order: -1; text-align: left; }
        .pe-photo { width: 100%; }
        /* One row: delete and Batal at their size, Simpan takes the rest. */
        .pe-savebar { gap: 10px; }
        .pe-savebar .pe-delete { flex: none; }
        .pe-savebar .pe-btn.is-quiet { flex: none; padding: 0 14px; }
        .pe-savebar .pe-btn.is-primary { flex: 1 1 0; min-width: 0; padding: 0 12px; white-space: nowrap; }
    }
    /* Narrow phones: "Simpan" alone so the row still fits. */
    @media (max-width: 400px) {
        .pe-save-more { display: none; }
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
                <div class="pe-photo" data-photo-hero>
                    @if ($primaryPhoto)
                        <img src="{{ $primaryPhoto }}" alt="Foto utama {{ $place->name }}">
                    @else
                        <div class="pe-photo-empty"><i class="bi bi-image" aria-hidden="true"></i>Belum ada foto</div>
                    @endif
                    <a href="#photos" class="pe-photo-link"><i class="bi bi-images" aria-hidden="true"></i> Kelola foto (<span data-photo-count>{{ $photoCount }}</span>)</a>
                </div>
                <div class="pe-facts">
                    <div class="pe-name">
                        <h2>{{ $place->name }}</h2>
                        @if ($place->ratingBlend() !== null)
                            <span class="pe-rating">
                                <i class="bi bi-star-fill" aria-hidden="true"></i>
                                {{ number_format($place->ratingBlend(), 1, ',', '.') }} · {{ $idNumber($place->reviews_count) }} ulasan
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
                <div class="pe-card-head">
                    <div>
                        <h2>Data kurasi</h2>
                        <span class="pe-card-sub">Dipakai saat membuat rekomendasi itinerary.</span>
                    </div>
                    <button type="button" id="peDataEstimate" class="pe-price-button" data-url="{{ route('admin.places.data-estimate', $place) }}">
                        <i class="bi bi-stars" aria-hidden="true"></i> Perkiraan data dengan AI
                    </button>
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
                    <fieldset class="pe-field pe-hours-section" id="peHours" aria-labelledby="peHoursLabel" style="border: 0; padding: 0; margin: 0;">
                        <div class="pe-hours-head">
                            <span class="pe-label" id="peHoursLabel">Jam operasional</span>
                            <button type="button" class="pe-price-button" id="peHoursCopy"><i class="bi bi-files" aria-hidden="true"></i> Salin Senin ke semua hari</button>
                        </div>
                        @if ($unreadableHours)
                            <p class="pe-hours-old">Tersimpan dari OpenStreetMap: <b>{{ $unreadableHours }}</b>. Isi baris di bawah untuk menggantinya.</p>
                        @endif
                        {{-- 1 once a row changes: untouched rows leave the stored hours alone. --}}
                        <input type="hidden" name="opening_hours_changed" value="{{ old('opening_hours_changed', 0) }}" id="peHoursChanged">
                        <div class="pe-hours">
                            @foreach (\App\Services\Places\OpeningHours::DAYS as $day => $dayName)
                                @php
                                    $row = old('opening_hours.'.$day, $hourRows[$day]);
                                    $state = $row['state'] ?? '';
                                @endphp
                                <div class="pe-hours-row {{ $state === 'closed' ? 'is-closed' : '' }}" data-hours-row="{{ $day }}">
                                    <span class="pe-hours-day" id="peHoursDay{{ $day }}">{{ $dayName }}</span>
                                    <select name="opening_hours[{{ $day }}][state]" data-hours-state="{{ $day }}" aria-labelledby="peHoursDay{{ $day }}">
                                        <option value="" @selected($state === '')>Belum diisi</option>
                                        <option value="open" @selected($state === 'open')>Buka</option>
                                        <option value="24h" @selected($state === '24h')>Buka 24 jam</option>
                                        <option value="closed" @selected($state === 'closed')>Tutup</option>
                                    </select>
                                    <div class="pe-hours-slot">
                                        <div class="pe-hours-times" data-hours-times="{{ $day }}" @if ($state !== 'open') hidden @endif>
                                            <input type="time" name="opening_hours[{{ $day }}][open]" value="{{ $row['open'] ?? '' }}" aria-label="Jam buka {{ $dayName }}">
                                            <span aria-hidden="true">–</span>
                                            <input type="time" name="opening_hours[{{ $day }}][close]" value="{{ $row['close'] ?? '' }}" aria-label="Jam tutup {{ $dayName }}">
                                        </div>
                                        <span class="pe-hours-note" data-hours-note="{{ $day }}" @if ($state === 'open') hidden @endif>{{ match ($state) { 'closed' => 'Tutup seharian', '24h' => 'Buka sepanjang hari', default => 'Dianggap buka' } }}</span>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                        @error('opening_hours.*')
                            <span class="pe-hint" style="color: #b42318;">Lengkapi jam buka dan jam tutup untuk hari yang Buka (keduanya tidak boleh sama).</span>
                        @enderror
                        <span class="pe-hint">Tampil di aplikasi, dan rekomendasi itinerary tidak memakai tempat ini pada hari Tutup. Belum diisi berarti dianggap buka.</span>
                    </fieldset>
                <div id="peDataResult" class="pe-price-result" hidden aria-live="polite"></div>
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
                    <div>
                        <h2><label for="peKeywords" class="m-0">Kata Kunci Pencarian</label></h2>
                        <span class="pe-card-sub">Wisatawan yang mencari salah satu kata ini di katalog akan menemukan tempat ini. Pisahkan dengan koma.</span>
                    </div>
                    <button type="button" id="peKeywordSuggest" class="pe-price-button" data-url="{{ route('admin.places.keyword-suggestions', $place) }}">
                        <i class="bi bi-stars" aria-hidden="true"></i> <span>Sarankan dengan AI</span>
                    </button>
                </div>
                {{-- Filled from the textarea by the script below; the x removes that keyword. --}}
                <div class="pe-kw-chips" id="peKeywordChips" aria-live="polite"></div>
                <textarea id="peKeywords" name="search_keywords" class="pe-textarea" rows="2"
                    placeholder="contoh: snorkeling, pasir putih, sunset, keluarga">{{ old('search_keywords', $place->search_keywords) }}</textarea>
                <p id="peKeywordError" class="pe-hint is-error" hidden></p>
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
                        <a href="https://www.openstreetmap.org/?mlat={{ $lat }}&amp;mlon={{ $lng }}#map=17/{{ $lat }}/{{ $lng }}" target="_blank" rel="noopener"><i class="bi bi-box-arrow-up-right" aria-hidden="true"></i> Buka di peta</a>
                    </div>
                </section>
            @endif

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

<div class="pe-savebar">
    <button type="button" class="pe-delete" aria-label="Hapus dari katalog" title="Hapus dari katalog"
        data-confirm-url="{{ route('admin.places.destroy', $place) }}" data-confirm-title="Hapus {{ $place->name }}?" data-confirm-ok="Hapus dari katalog"
        data-confirm-text="Tempat ini tidak akan muncul lagi di aplikasi dan di rekomendasi itinerary.">
        <i class="bi bi-trash3" aria-hidden="true"></i>
    </button>
    <span class="pe-dirty" id="peDirty" aria-live="polite">Belum ada perubahan</span>
    <a href="{{ route('admin.places.index') }}" class="pe-btn is-quiet"><i class="bi bi-x-lg" aria-hidden="true"></i>Batal</a>
    <button type="submit" form="formEditPlace" class="pe-btn is-primary"><i class="bi bi-check2" aria-hidden="true"></i>Simpan<span class="pe-save-more">&nbsp;perubahan</span></button>
</div>

@include('admin.partials.confirm-modal')
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
        // Listened on the document, not the form: fields that belong to the
        // form through form="formEditPlace" (the main-photo radios in Foto
        // Tempat) sit outside it, so their events never reach the form element.
        function updateDirtyFor(e) { if (e.target.form === form) updateDirty(); }
        document.addEventListener('input', updateDirtyFor);
        document.addEventListener('change', updateDirtyFor);
        form.addEventListener('submit', function () { submitting = true; });
        // Foto Tempat redraws its cards after an upload or delete: an untouched
        // main-photo choice follows the new cards instead of counting as an edit.
        var primaryWasEdited = false;
        document.addEventListener('place-photos:before-change', function () {
            primaryWasEdited = snapshot().primary_photo_id !== initial.primary_photo_id;
        });
        document.addEventListener('place-photos:changed', function () {
            if (!primaryWasEdited) initial.primary_photo_id = snapshot().primary_photo_id;
            updateDirty();
        });
        window.addEventListener('beforeunload', function (e) {
            if (!submitting && changedCount() > 0) {
                e.preventDefault();
                e.returnValue = '';
            }
        });

        // "Perkiraan data dengan AI": Google Maps and web results (SerpApi),
        // read by Gemini. Each value shows its source numbers and is only put
        // in the form when the admin clicks Pakai; built with textContent only.
        // Jam operasional: times show only for "Buka"; any change marks the
        // rows for saving (opening_hours_changed), so untouched rows keep
        // whatever is stored.
        var hours = document.getElementById('peHours');
        var hoursChanged = document.getElementById('peHoursChanged');
        var hourNotes = { closed: 'Tutup seharian', '24h': 'Buka sepanjang hari', '': 'Dianggap buka' };
        function syncHourRow(day) {
            var state = hours.querySelector('[data-hours-state="' + day + '"]').value;
            var open = state === 'open';
            var times = hours.querySelector('[data-hours-times="' + day + '"]');
            var note = hours.querySelector('[data-hours-note="' + day + '"]');
            times.hidden = !open;
            note.hidden = open;
            note.textContent = hourNotes[state] || '';
            hours.querySelector('[data-hours-row="' + day + '"]').classList.toggle('is-closed', state === 'closed');
            times.querySelectorAll('input').forEach(function (input) { input.disabled = !open; input.required = open; });
        }
        function markHoursChanged() {
            if (hoursChanged.value !== '1') {
                hoursChanged.value = '1';
                hoursChanged.dispatchEvent(new Event('change', { bubbles: true }));
            }
        }
        function setHourRows(rows) {
            Object.keys(rows).forEach(function (day) {
                hours.querySelector('[data-hours-state="' + day + '"]').value = rows[day].state;
                hours.querySelector('input[name="opening_hours[' + day + '][open]"]').value = rows[day].open;
                hours.querySelector('input[name="opening_hours[' + day + '][close]"]').value = rows[day].close;
                syncHourRow(day);
            });
            markHoursChanged();
        }
        hours.querySelectorAll('[data-hours-state]').forEach(function (select) {
            syncHourRow(select.dataset.hoursState);
            select.addEventListener('change', function () { syncHourRow(select.dataset.hoursState); });
        });
        hours.addEventListener('input', markHoursChanged);
        hours.addEventListener('change', function (event) { if (event.target !== hoursChanged) markHoursChanged(); });
        document.getElementById('peHoursCopy').addEventListener('click', function () {
            var monday = {
                state: hours.querySelector('[data-hours-state="mon"]').value,
                open: hours.querySelector('input[name="opening_hours[mon][open]"]').value,
                close: hours.querySelector('input[name="opening_hours[mon][close]"]').value,
            };
            var rows = {};
            hours.querySelectorAll('[data-hours-state]').forEach(function (select) { rows[select.dataset.hoursState] = monday; });
            setHourRows(rows);
        });

        var dataButton = document.getElementById('peDataEstimate');
        var dataResult = document.getElementById('peDataResult');
        var dataFields = {
            estimated_cost_idr: { label: @json($costLabel), input: function () { return document.getElementById('peCost'); } },
            estimated_visit_minutes: { label: 'Lama kunjungan', input: function () { return document.getElementById('peMinutes'); } },
            is_outdoor: { label: 'Area' },
            opening_hours: { label: 'Jam operasional' },
        };

        function dataMessage(text, isError) {
            var paragraph = document.createElement('p');
            paragraph.textContent = text;
            dataResult.classList.toggle('is-error', isError);
            dataResult.replaceChildren(paragraph);
            dataResult.hidden = false;
        }

        function shownValue(field, value) {
            if (value === null || value === undefined) return 'Tidak ditemukan';
            if (field === 'estimated_cost_idr') return value === 0 ? 'Gratis' : 'Rp ' + value.toLocaleString('id-ID');
            if (field === 'estimated_visit_minutes') return value + ' menit';
            if (field === 'is_outdoor') return value ? 'Outdoor' : 'Indoor';
            return value.join('\n');
        }

        function applyValue(field, item) {
            var value = item.value;
            if (field === 'opening_hours') {
                setHourRows(item.rows);
                return;
            }
            if (field === 'is_outdoor') {
                var radio = form.querySelector('input[name="is_outdoor"][value="' + (value ? '1' : '0') + '"]');
                radio.checked = true;
                radio.dispatchEvent(new Event('change', { bubbles: true }));
                return;
            }
            var input = dataFields[field].input();
            input.value = value;
            input.dispatchEvent(new Event('input', { bubbles: true }));
        }

        function useButton(label, onClick) {
            var button = document.createElement('button');
            button.type = 'button';
            button.className = 'pe-price-button pe-price-use';
            button.innerHTML = '<i class="bi bi-check2" aria-hidden="true"></i> ';
            button.appendChild(document.createTextNode(label));
            button.addEventListener('click', onClick);
            return button;
        }

        function showData(body) {
            dataResult.classList.remove('is-error');
            dataResult.replaceChildren();

            if (body.closed) {
                var closed = document.createElement('p');
                closed.className = 'pe-data-closed';
                closed.textContent = body.closed === 'permanent'
                    ? 'Google Maps mencatat tempat ini TUTUP PERMANEN. Periksa dulu; kalau benar, tandai agar tidak masuk rekomendasi itinerary.'
                    : 'Google Maps mencatat tempat ini tutup sementara.';
                dataResult.appendChild(closed);
                if (body.closed === 'permanent') {
                    dataResult.appendChild(useButton('Tandai tutup permanen', function () {
                        var status = form.querySelector('input[name="business_status"]') || document.createElement('input');
                        status.type = 'hidden';
                        status.name = 'business_status';
                        status.value = 'closed_permanently';
                        form.appendChild(status);
                        status.dispatchEvent(new Event('change', { bubbles: true }));
                        this.disabled = true;
                        this.lastChild.textContent = 'Ditandai, tersimpan setelah Simpan perubahan';
                    }));
                }
            }

            var usable = [];
            Object.keys(dataFields).forEach(function (field) {
                var item = body.fields[field];
                var row = document.createElement('div');
                row.className = 'pe-data-row';

                var label = document.createElement('span');
                label.className = 'pe-data-label';
                label.textContent = dataFields[field].label;

                var value = document.createElement('span');
                value.className = 'pe-data-value' + (item.value === null ? ' is-empty' : '');
                value.textContent = shownValue(field, item.value);
                if (item.sources.length) {
                    var cite = document.createElement('span');
                    cite.className = 'pe-data-cite';
                    cite.textContent = '[' + item.sources.join(', ') + ']';
                    value.appendChild(cite);
                }
                if (item.note) {
                    var note = document.createElement('span');
                    note.className = 'pe-data-note';
                    note.textContent = item.note;
                    value.appendChild(note);
                }

                row.append(label, value);
                if (item.value !== null) {
                    usable.push(field);
                    row.appendChild(useButton('Pakai', function () { applyValue(field, item); }));
                }
                dataResult.appendChild(row);
            });

            if (usable.length > 1) {
                var actions = document.createElement('div');
                actions.className = 'pe-data-actions';
                actions.appendChild(useButton('Pakai semua', function () {
                    usable.forEach(function (field) { applyValue(field, body.fields[field]); });
                }));
                dataResult.appendChild(actions);
            }

            if (body.sources.length) {
                var list = document.createElement('ol');
                list.className = 'pe-data-sources';
                body.sources.forEach(function (source) {
                    var entry = document.createElement('li');
                    entry.appendChild(document.createTextNode('[' + source.number + '] '));
                    var link = document.createElement('a');
                    link.href = source.link;
                    link.target = '_blank';
                    link.rel = 'noopener noreferrer';
                    link.textContent = source.title;
                    entry.appendChild(link);
                    var meta = [source.source, source.date].filter(Boolean).join(', ');
                    if (meta) {
                        var small = document.createElement('span');
                        small.textContent = ' · ' + meta;
                        entry.appendChild(small);
                    }
                    list.appendChild(entry);
                });
                dataResult.appendChild(list);
            }

            var footnote = document.createElement('span');
            footnote.className = 'pe-price-note';
            footnote.textContent = body.sources.length
                ? 'Dari pencarian Google, dibaca AI. Klik sumbernya untuk memastikan. Data baru tersimpan setelah Simpan perubahan.'
                : 'Google tidak menemukan tempat ini, jadi tidak ada yang bisa diperkirakan.';
            dataResult.appendChild(footnote);
            dataResult.hidden = false;
        }

        dataButton.addEventListener('click', function () {
            dataButton.disabled = true;
            dataResult.classList.remove('is-error');
            dataResult.innerHTML = '<p><span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Mencari di Google dan membaca hasilnya...</p>';
            dataResult.hidden = false;
            fetch(dataButton.dataset.url, { headers: { Accept: 'application/json' } })
                .then(function (response) {
                    return response.json().catch(function () { return {}; }).then(function (body) {
                        if (!response.ok) throw new Error(body.message || 'Perkiraan data gagal, coba lagi.');
                        return body;
                    });
                })
                .then(showData)
                .catch(function (error) { dataMessage(error.message || 'Perkiraan data gagal, coba lagi.', true); })
                .finally(function () { dataButton.disabled = false; });
        });

        var keywordsField = document.getElementById('peKeywords');
        var keywordChips = document.getElementById('peKeywordChips');
        var keywordButton = document.getElementById('peKeywordSuggest');
        var keywordError = document.getElementById('peKeywordError');
        function keywordList() {
            var seen = {};
            return keywordsField.value.split(',').map(function (k) { return k.trim(); }).filter(function (k) {
                var key = k.toLowerCase();
                if (!k || seen[key]) return false;
                seen[key] = true;
                return true;
            });
        }
        function setKeywords(list) {
            keywordsField.value = list.join(', ');
            keywordsField.dispatchEvent(new Event('input', { bubbles: true }));
        }
        // Built with textContent only: keywords can come from Gemini.
        function renderKeywordChips() {
            var list = keywordList();
            keywordChips.replaceChildren();
            if (list.length === 0) {
                var empty = document.createElement('span');
                empty.className = 'pe-kw-empty';
                empty.textContent = 'Belum ada kata kunci.';
                keywordChips.appendChild(empty);
                return;
            }
            list.forEach(function (keyword) {
                var chip = document.createElement('span');
                chip.className = 'pe-kw-chip';
                chip.appendChild(document.createTextNode(keyword));
                var remove = document.createElement('button');
                remove.type = 'button';
                remove.setAttribute('aria-label', 'Hapus ' + keyword);
                remove.innerHTML = '<i class="bi bi-x" aria-hidden="true"></i>';
                remove.addEventListener('click', function () {
                    setKeywords(keywordList().filter(function (other) { return other.toLowerCase() !== keyword.toLowerCase(); }));
                });
                chip.appendChild(remove);
                keywordChips.appendChild(chip);
            });
        }
        keywordsField.addEventListener('input', renderKeywordChips);
        renderKeywordChips();

        // Adds Gemini's suggestions to what is already there; saved with Simpan perubahan.
        keywordButton.addEventListener('click', function () {
            var label = keywordButton.querySelector('span');
            keywordButton.disabled = true;
            keywordError.hidden = true;
            label.textContent = 'Meminta saran...';
            fetch(keywordButton.dataset.url, { headers: { Accept: 'application/json' } })
                .then(function (response) {
                    return response.json().then(function (body) {
                        if (!response.ok) throw new Error(body.message || 'Saran kata kunci gagal, coba lagi.');
                        return body;
                    });
                })
                .then(function (body) {
                    keywordsField.value = keywordList().concat(body.keywords || []).join(', ');
                    setKeywords(keywordList());
                })
                .catch(function (error) {
                    keywordError.textContent = error.message || 'Saran kata kunci gagal, coba lagi.';
                    keywordError.hidden = false;
                })
                .finally(function () {
                    keywordButton.disabled = false;
                    label.textContent = 'Sarankan dengan AI';
                });
        });

        // Deleting the place leaves the page for good; deleting a photo still
        // warns about unsaved edits.
        document.getElementById('confirmModalUrlForm').addEventListener('confirmed', function () { submitting = true; });
    })();
</script>
@endpush
