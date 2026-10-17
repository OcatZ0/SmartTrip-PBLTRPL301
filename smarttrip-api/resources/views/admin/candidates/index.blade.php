@extends('admin.layout')

@php
    $statusTabs = [
        'pending' => ['label' => 'Menunggu review', 'icon' => 'bi-hourglass-split'],
        'approved' => ['label' => 'Disetujui', 'icon' => 'bi-check-circle'],
        'rejected' => ['label' => 'Ditolak', 'icon' => 'bi-x-circle'],
    ];
    $typeBadges = [
        'attraction' => ['label' => 'Wisata', 'icon' => 'bi-geo-alt', 'class' => 'is-attraction'],
        'culinary' => ['label' => 'Kuliner', 'icon' => 'bi-cup-hot', 'class' => 'is-culinary'],
        'lodging' => ['label' => 'Penginapan', 'icon' => 'bi-building', 'class' => 'is-lodging'],
    ];
    $typeLabels = array_map(fn ($typeBadge) => $typeBadge['label'], $typeBadges);
    $canSelect = $selectedStatus !== 'approved';
@endphp

@section('title', 'Kandidat Tempat')

@section('subtitle', 'Tinjau tempat baru hasil Discovery sebelum masuk katalog.')

@section('topbar_actions')
    <button type="button" class="admin-topbar-action" id="cdDiscover" data-bs-toggle="modal" data-bs-target="#cdDiscoveryModal">
        <i class="bi bi-radar" aria-hidden="true"></i>
        <span id="cdDiscoverLabel">Jalankan Discovery</span>
    </button>
@endsection

@push('styles')
<style>
    .cd-page { --cd-ink: #14212f; --cd-muted: #5d6b7c; --cd-line: #e2e8f0; --cd-fill: #f1f5f9; --cd-blue: #2b6fab;
        display: flex; flex-direction: column; gap: 16px; color: var(--cd-ink); }
    .cd-alert { margin: 0; padding: 12px 16px; border-radius: 14px; font-size: 14px; font-weight: 600; display: flex; gap: 10px; align-items: flex-start; }
    .cd-alert.is-ok { background: #e3f6ec; color: #1d7a55; }
    .cd-alert.is-error { background: #fdecea; color: #b42318; }
    /* One row: status tabs on the left, search and filters on the right; the
       filters drop to their own full-width row only when there is no room. */
    .cd-toolbar { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px 16px; padding: 12px 14px; border-radius: 16px; background: #fff; border: 1px solid var(--cd-line); }
    .cd-tabs { display: flex; flex-wrap: wrap; gap: 4px; padding: 4px; border-radius: 12px; background: var(--cd-fill); }
    .cd-tab { display: inline-flex; align-items: center; gap: 8px; padding: 7px 12px; border-radius: 9px; font-size: 13.5px; font-weight: 600; color: var(--cd-muted); text-decoration: none; white-space: nowrap; }
    .cd-tab:hover { background: #fff; color: var(--cd-ink); }
    .cd-tab.is-active { background: #fff; color: var(--cd-blue); box-shadow: 0 1px 3px rgba(15, 23, 42, .08); }
    .cd-tab-count { min-width: 22px; padding: 1px 7px; border-radius: 999px; background: #fff; font-size: 12px; text-align: center; color: var(--cd-muted); }
    .cd-tab.is-active .cd-tab-count { background: var(--cd-blue); color: #fff; }
    .cd-filters { flex: 1 1 520px; display: flex; flex-wrap: wrap; align-items: center; justify-content: flex-end; gap: 8px; }
    .cd-search { position: relative; flex: 1 1 220px; max-width: 320px; }
    .cd-search .bi { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 14px; }
    .cd-search input { height: 40px; width: 100%; padding: 0 12px 0 36px; border: 1px solid var(--cd-line); border-radius: 10px; font-size: 13.5px; color: var(--cd-ink); }
    .cd-search input:focus, .cd-select:focus { outline: none; border-color: var(--cd-blue); box-shadow: 0 0 0 3px rgba(43, 111, 171, .15); }
    .cd-reset { border-color: var(--cd-line); color: var(--cd-muted); }
    .cd-reset:hover { background: var(--cd-fill); color: var(--cd-ink); }
    /* Bootstrap's .form-select is width: 100%, which put each select on its own row. */
    .cd-select.form-select { flex: 0 0 auto; width: auto; height: 40px; min-width: 160px; padding: 0 36px 0 12px; border: 1px solid var(--cd-line); border-radius: 10px; font-size: 13.5px; color: var(--cd-ink); background-color: #fff; }
    @media (max-width: 640px) {
        .cd-search { max-width: none; flex-basis: 100%; }
        .cd-select.form-select { flex: 1 1 140px; }
    }
    .cd-card { border-radius: 16px; background: #fff; border: 1px solid var(--cd-line); overflow: hidden; }
    .cd-bulk { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; padding: 12px 16px; border-bottom: 1px solid var(--cd-line); background: #f8fafc; }
    .cd-bulk-count { font-size: 13px; color: var(--cd-muted); margin-right: auto; }
    .cd-btn { height: 36px; padding: 0 14px; border: 1px solid transparent; border-radius: 10px; display: inline-flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 700; text-decoration: none; white-space: nowrap; }
    .cd-btn:disabled { opacity: .5; cursor: not-allowed; }
    .cd-btn.is-approve { background: #1d7a55; color: #fff; }
    .cd-btn.is-approve:hover:not(:disabled) { background: #16613f; }
    .cd-btn.is-reject { background: #fff; border-color: #f3c3bd; color: #b42318; }
    .cd-btn.is-reject:hover:not(:disabled) { background: #fdecea; }
    .cd-btn.is-icon { width: 36px; padding: 0; justify-content: center; }
    .cd-table { width: 100%; margin: 0; border-collapse: collapse; font-size: 14px; }
    .cd-table th { padding: 12px 16px; font-size: 11.5px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; color: var(--cd-muted); border-bottom: 1px solid var(--cd-line); white-space: nowrap; }
    .cd-table td { padding: 14px 16px; border-bottom: 1px solid var(--cd-line); vertical-align: middle; }
    .cd-table tbody tr:last-child td { border-bottom: 0; }
    .cd-table tbody tr:hover { background: #fafcfe; }
    .cd-table tbody tr.is-selected { background: #f2f7fc; }
    .cd-check { width: 18px; height: 18px; margin: 0; accent-color: var(--cd-blue); cursor: pointer; }
    .cd-name { font-weight: 700; }
    .cd-id { font-size: 12px; color: #94a3b8; }
    .cd-type { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; }
    .cd-type.is-attraction { background: #dbeafe; color: #1d4ed8; }
    .cd-type.is-culinary { background: #ffedd5; color: #c2410c; }
    .cd-type.is-lodging { background: #ede9fe; color: #6d28d9; }
    .cd-muted { font-size: 13px; color: var(--cd-muted); white-space: nowrap; }
    .cd-status { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; }
    .cd-status.is-pending { background: #fef3c7; color: #a15c07; }
    .cd-status.is-approved { background: #e3f6ec; color: #1d7a55; }
    .cd-status.is-rejected { background: #fdecea; color: #b42318; }
    .cd-actions { display: flex; justify-content: flex-end; align-items: center; gap: 6px; }
    .cd-map { color: var(--cd-blue); }
    .cd-empty { padding: 48px 16px; text-align: center; color: var(--cd-muted); }
    .cd-empty .bi { display: block; margin-bottom: 8px; font-size: 36px; color: #cbd5e1; }
    .cd-bulk-all { display: none; }
    /* ── Small screens: each candidate row becomes a card (same pattern as Kelola Tempat) ── */
    @media (max-width: 767.98px) {
        .cd-bulk-all { display: inline-flex; }
        /* Status tabs stack, each one full width (the selected one was cut short). */
        .cd-tabs { flex-direction: column; flex: 1 1 100%; }
        .cd-tab { width: 100%; padding: 10px 12px; }
        /* Each candidate is its own white card on the page background, 12px apart;
           the bulk bar and the footer are cards too. */
        .cd-card { background: transparent; border: 0; border-radius: 0; overflow: visible; display: flex; flex-direction: column; gap: 12px; }
        .cd-bulk { padding: 10px 12px; gap: 8px; border: 1px solid var(--cd-line); border-radius: 14px; }
        .cd-bulk-count { flex-basis: 100%; }
        .cd-bulk .cd-btn { flex: 1 1 auto; justify-content: center; }
        .cd-card .table-responsive { overflow: visible; }
        .cd-table, .cd-table tbody { display: block; width: 100%; }
        .cd-table thead { display: none; }
        /* Checkbox, name and status on top; then one "label: value" line each; actions at the bottom. */
        .cd-table tbody { display: flex !important; flex-direction: column; gap: 12px; }
        .cd-table tbody tr { display: grid; grid-template-columns: auto minmax(0, 1fr) auto; column-gap: 10px; row-gap: 8px; padding: 14px; background: #fff; border: 1px solid var(--cd-line); border-radius: 14px; box-shadow: 0 6px 18px -12px rgba(10, 36, 64, .25); }
        .cd-table td { display: block; padding: 0; border: 0; }
        .cd-table td.cd-c-check { grid-column: 1; grid-row: 1; padding-top: 2px; }
        .cd-table td.cd-c-name { grid-column: 2; grid-row: 1; min-width: 0; overflow-wrap: anywhere; }
        .cd-table td.cd-c-status { grid-column: 3; grid-row: 1; }
        .cd-table td.cd-c-type, .cd-table td.cd-c-area, .cd-table td.cd-c-found {
            grid-column: 1 / -1; display: flex; align-items: center; justify-content: space-between; gap: 12px;
            padding-top: 8px; border-top: 1px dashed var(--cd-line); white-space: normal; text-align: right;
        }
        .cd-table td[data-label]::before { content: attr(data-label); flex-shrink: 0; font-size: 12px; font-weight: 700; color: var(--cd-muted); text-align: left; }
        .cd-table td.cd-c-actions { grid-column: 1 / -1; padding-top: 4px; }
        .cd-table td.cd-c-actions .cd-actions { justify-content: stretch; }
        .cd-table td.cd-c-actions .cd-btn:not(.is-icon) { flex: 1 1 auto; justify-content: center; }
        .cd-table td.cd-empty { grid-column: 1 / -1; }
        /* .cd-card prefix: the base .cd-foot rule comes later in this sheet. */
        .cd-card .cd-foot { flex-direction: column; align-items: stretch; text-align: center; background: #fff; border: 1px solid var(--cd-line); border-radius: 14px; }
        .cd-card .cd-foot .pagination { justify-content: center; flex-wrap: wrap; }
        .cd-dt-map { height: 200px; }
    }
    .cd-foot { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 12px; padding: 12px 16px; border-top: 1px solid var(--cd-line); font-size: 13px; color: var(--cd-muted); }
    .cd-dm .modal-content { border: 0; border-radius: 20px; box-shadow: 0 24px 64px rgba(10, 36, 64, .22); }
    @media (max-width: 575.98px) {
        /* modal-fullscreen-sm-down: square corners, and the footer buttons may wrap. */
        .cd-dm .modal-content { border-radius: 0; box-shadow: none; }
        .cd-dm-head, .cd-dm-body { padding-left: 16px; padding-right: 16px; }
        .cd-dm .cd-dm-foot { flex-wrap: wrap; padding: 12px 16px 16px; }
        .cd-dm .cd-dm-foot .cd-btn { flex: 1 1 auto; justify-content: center; }
        .cd-dm-stats { grid-template-columns: 1fr; }
        /* Approve and reject first; the OpenStreetMap link drops to its own row. */
        .cd-dm #cdDtOsmLink { order: 2; flex-basis: 100%; margin-right: 0 !important; }
    }
    .cd-dm-head { display: flex; align-items: center; gap: 14px; padding: 20px 24px; border-bottom: 1px solid #e2e8f0; }
    .cd-dm-icon { width: 44px; height: 44px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; border-radius: 12px; background: #eaf2fa; color: #2b6fab; font-size: 20px; }
    .cd-dm-icon.is-finished { background: #e3f6ec; color: #1d7a55; }
    .cd-dm-icon.is-failed { background: #fdecea; color: #b42318; }
    .cd-dm-title { margin: 0; font-size: 18px; font-weight: 700; color: #14212f; }
    .cd-dm-sub { margin: 2px 0 0; font-size: 13px; color: #5d6b7c; }
    .cd-dm-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; }
    .cd-dm-intro { margin: 0; font-size: 14px; color: #3a4757; line-height: 1.6; }
    .cd-dm-last { padding: 12px 14px; border-radius: 12px; background: #f1f5f9; font-size: 13px; color: #5d6b7c; }
    .cd-dm-progress-head { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; font-size: 13px; color: #5d6b7c; }
    .cd-dm-progress-head b { font-size: 15px; color: #14212f; }
    .cd-dm-bar { height: 10px; border-radius: 999px; background: #e2e8f0; overflow: hidden; }
    .cd-dm-bar > div { height: 100%; width: 0; border-radius: 999px; background: #2b6fab; transition: width .4s ease; }
    .cd-dm-bar.is-finished > div { background: #1d7a55; }
    .cd-dm-bar.is-failed > div { background: #b42318; }
    .cd-dm-current { display: flex; align-items: center; gap: 8px; font-size: 13.5px; color: #14212f; }
    .cd-dm-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
    .cd-dm-stat { padding: 12px 14px; border-radius: 12px; background: #f8fafc; border: 1px solid #e2e8f0; }
    .cd-dm-stat span { display: block; font-size: 12px; color: #5d6b7c; }
    .cd-dm-stat b { font-size: 22px; line-height: 28px; color: #14212f; }
    .cd-dm-stat.is-new b { color: #1d7a55; }
    .cd-dm-stat.is-fail b { color: #b42318; }
    .cd-dm-error { margin: 0; padding: 12px 14px; border-radius: 12px; background: #fdecea; color: #b42318; font-size: 13.5px; font-weight: 600; }
    .cd-dm-log-title { margin: 0; font-size: 12px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; color: #5d6b7c; }
    .cd-dm-log { max-height: 240px; overflow-y: auto; margin: 0; padding: 0; list-style: none; border: 1px solid #e2e8f0; border-radius: 12px; }
    .cd-dm-log li { display: flex; align-items: center; gap: 10px; padding: 9px 14px; font-size: 13px; }
    .cd-dm-log li + li { border-top: 1px solid #eef2f6; }
    .cd-dm-log .bi-check-circle-fill { color: #1d7a55; }
    .cd-dm-log .bi-x-circle-fill { color: #b42318; }
    .cd-dm-log-step { flex: 1; min-width: 0; font-weight: 600; color: #14212f; }
    .cd-dm-log-result { color: #5d6b7c; text-align: right; overflow-wrap: anywhere; }
    .cd-dm-log li.is-error .cd-dm-log-result { color: #b42318; }
    .cd-dm-foot { display: flex; justify-content: flex-end; gap: 10px; padding: 14px 24px 20px; }
    .cd-dm-foot .cd-btn { height: 40px; padding: 0 18px; }
    .cd-btn.is-quiet { background: #eef2f8; color: #14212f; }
    .cd-btn.is-quiet:hover { background: #e2e8f1; }
    .cd-name-link { padding: 0; border: 0; background: none; text-align: left; cursor: pointer; }
    .cd-name-link:hover { color: var(--cd-blue); text-decoration: underline; }
    .cd-dt-badges { display: flex; flex-wrap: wrap; gap: 8px; }
    .cd-dt-map { height: 240px; border-radius: 14px; overflow: hidden; border: 1px solid #e2e8f0; background: #eef2f6; }
    .cd-dt-map iframe { width: 100%; height: 100%; border: 0; }
    .cd-dt-facts { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; margin: 0; }
    .cd-dt-facts > div { padding: 10px 14px; border-radius: 12px; background: #f8fafc; border: 1px solid #e2e8f0; min-width: 0; }
    .cd-dt-facts dt { font-size: 12px; font-weight: 600; color: #5d6b7c; }
    .cd-dt-facts dd { margin: 2px 0 0; font-size: 14px; font-weight: 600; color: #14212f; overflow-wrap: anywhere; }
    .cd-btn.is-primary { background: #2b6fab; color: #fff; }
    .cd-btn.is-primary:hover:not(:disabled) { background: #245f93; }
    .cd-page button:focus-visible, .cd-page a:focus-visible { outline: 3px solid rgba(43, 111, 171, .45); outline-offset: 2px; }
</style>
@endpush

@section('content')
<div class="cd-page">
    @if (session('status'))
        <p class="cd-alert is-ok" role="status"><i class="bi bi-check-circle-fill" aria-hidden="true"></i>{{ session('status') }}</p>
    @endif
    @if (session('error'))
        <p class="cd-alert is-error" role="alert"><i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>{{ session('error') }}</p>
    @endif
    @if ($errors->any())
        <p class="cd-alert is-error" role="alert"><i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>Pilih minimal satu kandidat dulu.</p>
    @endif

    <div class="cd-toolbar">
        <nav class="cd-tabs" aria-label="Status kandidat">
            @foreach ($statusTabs as $status => $tab)
                <a href="{{ route('admin.candidates.index', array_filter(['status' => $status, 'search' => $search, 'search_area' => $selectedArea, 'type' => $selectedType])) }}"
                    class="cd-tab {{ $selectedStatus === $status ? 'is-active' : '' }}" @if ($selectedStatus === $status) aria-current="page" @endif>
                    <i class="bi {{ $tab['icon'] }}" aria-hidden="true"></i>{{ $tab['label'] }}
                    <span class="cd-tab-count">{{ number_format($statusCounts[$status] ?? 0, 0, ',', '.') }}</span>
                </a>
            @endforeach
        </nav>
        <form method="GET" action="{{ route('admin.candidates.index') }}" class="cd-filters" id="cdFilterForm">
            <input type="hidden" name="status" value="{{ $selectedStatus }}">
            <div class="cd-search">
                <i class="bi bi-search" aria-hidden="true"></i>
                <label for="cdSearch" class="visually-hidden">Cari kandidat</label>
                <input type="search" name="search" id="cdSearch" value="{{ $search }}" maxlength="100" placeholder="Cari nama atau ID OSM..." autocomplete="off">
            </div>
            <label for="cdType" class="visually-hidden">Jenis tempat</label>
            <select name="type" id="cdType" class="cd-select form-select" onchange="this.form.submit()">
                <option value="">Semua jenis</option>
                @foreach ($typeBadges as $typeValue => $typeBadge)
                    <option value="{{ $typeValue }}" @selected($selectedType === $typeValue)>{{ $typeBadge['label'] }}</option>
                @endforeach
            </select>
            <label for="cdArea" class="visually-hidden">Kecamatan</label>
            <select name="search_area" id="cdArea" class="cd-select form-select" onchange="this.form.submit()">
                <option value="">Semua kecamatan</option>
                @foreach ($areas as $area)
                    <option value="{{ $area }}" @selected($selectedArea === $area)>{{ $area }}</option>
                @endforeach
            </select>
            @if ($search !== '' || $selectedType !== '' || $selectedArea !== '')
                <a href="{{ route('admin.candidates.index', ['status' => $selectedStatus]) }}" class="cd-btn is-icon cd-reset" title="Atur ulang filter" aria-label="Atur ulang filter">
                    <i class="bi bi-arrow-counterclockwise" aria-hidden="true"></i>
                </a>
            @endif
        </form>
    </div>

    <form method="POST" id="cdBulkForm" class="cd-card">
        @csrf
        @if ($canSelect && $candidates->isNotEmpty())
            <div class="cd-bulk">
                <span class="cd-bulk-count" id="cdBulkCount" aria-live="polite">Belum ada yang dipilih</span>
                {{-- Small screens only: the table header (with "select all") is hidden there. --}}
                <button type="button" class="cd-btn is-quiet cd-bulk-all" onclick="document.getElementById('cdCheckAll').click()">
                    <i class="bi bi-check2-all" aria-hidden="true"></i>Pilih semua
                </button>
                <button type="submit" formaction="{{ route('admin.candidates.bulk-approve') }}" class="cd-btn is-approve" data-bulk-button
                    data-busy-label="Menyetujui..." disabled>
                    <i class="bi bi-check-lg" aria-hidden="true"></i>Setujui terpilih
                </button>
                @if ($selectedStatus === 'pending')
                    <button type="submit" formaction="{{ route('admin.candidates.bulk-reject') }}" class="cd-btn is-reject" data-bulk-button
                        data-busy-label="Menolak..." disabled>
                        <i class="bi bi-x-lg" aria-hidden="true"></i>Tolak terpilih
                    </button>
                @endif
            </div>
        @endif

        <div class="table-responsive">
            <table class="cd-table">
                <thead>
                    <tr>
                        @if ($canSelect)
                            <th style="width: 48px;"><input type="checkbox" class="cd-check" id="cdCheckAll" aria-label="Pilih semua kandidat di halaman ini"></th>
                        @endif
                        <th>Nama tempat</th>
                        <th>Jenis</th>
                        <th>Kecamatan</th>
                        <th>Ditemukan</th>
                        <th>Status</th>
                        <th class="text-end">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($candidates as $candidate)
                        @php
                            $type = $typeBadges[$candidate->type] ?? ['label' => $candidate->type, 'icon' => 'bi-geo-alt', 'class' => 'is-attraction'];
                            $status = $statusTabs[$candidate->status] ?? $statusTabs['pending'];
                            // Everything the detail modal shows; read with JSON.parse, no extra request.
                            $detail = [
                                'id' => $candidate->place_candidates_id,
                                'name' => $candidate->name,
                                'osm' => $candidate->external_place_id,
                                'type' => $type,
                                'area' => $candidate->search_area,
                                'lat' => (float) $candidate->lat,
                                'lng' => (float) $candidate->lng,
                                'found' => $candidate->created_at?->translatedFormat('d M Y, H:i'),
                                'updated' => $candidate->updated_at?->translatedFormat('d M Y, H:i'),
                                'status' => ['key' => $candidate->status] + $status,
                                'can_approve' => $candidate->status !== 'approved',
                                'can_reject' => $candidate->status === 'pending',
                            ];
                        @endphp
                        <tr>
                            @if ($canSelect)
                                <td class="cd-c-check">
                                    @if ($candidate->status !== 'approved')
                                        <input type="checkbox" class="cd-check candidate-check" name="ids[]" value="{{ $candidate->place_candidates_id }}"
                                            aria-label="Pilih {{ $candidate->name }}">
                                    @endif
                                </td>
                            @endif
                            <td class="cd-c-name">
                                <button type="button" class="cd-name cd-name-link" data-candidate="{{ json_encode($detail) }}">{{ $candidate->name }}</button>
                                <div class="cd-id">{{ $candidate->external_place_id }}</div>
                            </td>
                            <td class="cd-c-type" data-label="Jenis"><span class="cd-type {{ $type['class'] }}"><i class="bi {{ $type['icon'] }}" aria-hidden="true"></i>{{ $type['label'] }}</span></td>
                            <td class="cd-muted cd-c-area" data-label="Kecamatan"><i class="bi bi-geo-alt me-1" aria-hidden="true"></i>{{ $candidate->search_area }}</td>
                            <td class="cd-muted cd-c-found" data-label="Ditemukan">{{ $candidate->created_at?->format('d/m/Y') }}</td>
                            <td class="cd-c-status"><span class="cd-status is-{{ $candidate->status }}"><i class="bi {{ $status['icon'] }}" aria-hidden="true"></i>{{ $status['label'] }}</span></td>
                            <td class="cd-c-actions">
                                <div class="cd-actions">
                                    <button type="button" class="cd-btn is-icon cd-map" data-candidate="{{ json_encode($detail) }}"
                                        title="Lihat detail" aria-label="Lihat detail {{ $candidate->name }}">
                                        <i class="bi bi-eye" aria-hidden="true"></i>
                                    </button>
                                    @if ($candidate->status !== 'approved')
                                        <button type="submit" form="cdApprove{{ $candidate->place_candidates_id }}" class="cd-btn is-approve" data-busy-label="Menyetujui...">
                                            <i class="bi bi-check-lg" aria-hidden="true"></i>Setujui
                                        </button>
                                    @endif
                                    @if ($candidate->status === 'pending')
                                        <button type="submit" form="cdReject{{ $candidate->place_candidates_id }}" class="cd-btn is-reject is-icon" title="Tolak" aria-label="Tolak {{ $candidate->name }}">
                                            <i class="bi bi-x-lg" aria-hidden="true"></i>
                                        </button>
                                    @endif
                                    @if ($candidate->status === 'approved')
                                        <span class="cd-muted"><i class="bi bi-check2-circle me-1" aria-hidden="true"></i>Sudah di katalog</span>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="{{ $canSelect ? 7 : 6 }}" class="cd-empty">
                                <i class="bi bi-inbox" aria-hidden="true"></i>
                                @if ($search !== '' || $selectedType !== '' || $selectedArea !== '')
                                    Tidak ada kandidat yang cocok dengan filter ini.
                                @elseif ($selectedStatus === 'pending')
                                    Tidak ada kandidat yang menunggu review. Jalankan Discovery untuk mencari tempat baru.
                                @else
                                    Tidak ada kandidat dengan status ini.
                                @endif
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if ($candidates->total() > 0)
            <div class="cd-foot">
                <span>Menampilkan {{ $candidates->firstItem() }}–{{ $candidates->lastItem() }} dari {{ $candidates->total() }} kandidat</span>
                {{ $candidates->links('admin.partials.pagination') }}
            </div>
        @endif
    </form>

    <div class="modal fade cd-dm" id="cdDiscoveryModal" tabindex="-1" aria-labelledby="cdDmTitle" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg modal-fullscreen-sm-down">
            <div class="modal-content">
                <div class="cd-dm-head">
                    <span class="cd-dm-icon" id="cdDmIcon" aria-hidden="true"><i class="bi bi-radar"></i></span>
                    <div class="flex-grow-1">
                        <h2 class="cd-dm-title" id="cdDmTitle">Discovery tempat baru</h2>
                        <p class="cd-dm-sub" id="cdDmSub">Cari kandidat tempat dari Geoapify (OpenStreetMap).</p>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>
                <div class="cd-dm-body" id="cdDmBody" aria-live="polite"></div>
                <div class="cd-dm-foot" id="cdDmFoot"></div>
            </div>
        </div>
    </div>

    {{-- Candidate detail, filled from the row's data-candidate by openCandidateDetail(). --}}
    <div class="modal fade cd-dm" id="cdDetailModal" tabindex="-1" aria-labelledby="cdDtTitle" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg modal-fullscreen-sm-down">
            <div class="modal-content">
                <div class="cd-dm-head">
                    <span class="cd-dm-icon" aria-hidden="true"><i class="bi bi-geo-alt" id="cdDtIcon"></i></span>
                    <div class="flex-grow-1 min-w-0">
                        <h2 class="cd-dm-title text-truncate" id="cdDtTitle"></h2>
                        <p class="cd-dm-sub" id="cdDtSub"></p>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>
                <div class="cd-dm-body">
                    <div class="cd-dt-badges">
                        <span class="cd-type" id="cdDtType"></span>
                        <span class="cd-status" id="cdDtStatus"></span>
                    </div>
                    <div class="cd-dt-map">
                        <iframe id="cdDtMap" title="Peta lokasi kandidat" loading="lazy" referrerpolicy="no-referrer"></iframe>
                    </div>
                    <dl class="cd-dt-facts">
                        <div><dt>Kecamatan</dt><dd id="cdDtArea"></dd></div>
                        <div><dt>Koordinat</dt><dd id="cdDtCoords"></dd></div>
                        <div><dt>ID OpenStreetMap</dt><dd id="cdDtOsm"></dd></div>
                        <div><dt>Ditemukan</dt><dd id="cdDtFound"></dd></div>
                        <div><dt>Terakhir diubah</dt><dd id="cdDtUpdated"></dd></div>
                    </dl>
                    <p class="cd-dm-last mb-0" id="cdDtNote">Setujui untuk memasukkan tempat ini ke katalog: sistem mengambil detail lengkap dari Geoapify lalu melengkapi deskripsi, kategori, biaya, dan kata kunci dengan Gemini.</p>
                </div>
                <div class="cd-dm-foot">
                    <a href="#" target="_blank" rel="noopener" class="cd-btn is-quiet me-auto" id="cdDtOsmLink">
                        <i class="bi bi-box-arrow-up-right" aria-hidden="true"></i>Buka di OpenStreetMap
                    </a>
                    <button type="submit" class="cd-btn is-reject" id="cdDtReject" data-busy-label="Menolak...">
                        <i class="bi bi-x-lg" aria-hidden="true"></i>Tolak
                    </button>
                    <button type="submit" class="cd-btn is-approve" id="cdDtApprove" data-busy-label="Menyetujui...">
                        <i class="bi bi-check-lg" aria-hidden="true"></i>Setujui
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- Outside the bulk form: forms cannot nest. --}}
    @foreach ($candidates as $candidate)
        @if ($candidate->status !== 'approved')
            <form method="POST" action="{{ route('admin.candidates.approve', $candidate) }}" id="cdApprove{{ $candidate->place_candidates_id }}" class="d-none">@csrf</form>
        @endif
        @if ($candidate->status === 'pending')
            <form method="POST" action="{{ route('admin.candidates.reject', $candidate) }}" id="cdReject{{ $candidate->place_candidates_id }}" class="d-none">@csrf</form>
        @endif
    @endforeach
</div>
@endsection

@push('scripts')
<script>
    (function () {
        var checks = Array.prototype.slice.call(document.querySelectorAll('.candidate-check'));
        var checkAll = document.getElementById('cdCheckAll');
        var countLabel = document.getElementById('cdBulkCount');
        var bulkButtons = document.querySelectorAll('[data-bulk-button]');

        function updateSelection() {
            var picked = checks.filter(function (check) { return check.checked; }).length;
            checks.forEach(function (check) { check.closest('tr').classList.toggle('is-selected', check.checked); });
            bulkButtons.forEach(function (button) { button.disabled = picked === 0; });
            if (countLabel) countLabel.textContent = picked === 0 ? 'Belum ada yang dipilih' : picked + ' kandidat dipilih';
            if (checkAll) {
                checkAll.checked = picked > 0 && picked === checks.length;
                checkAll.indeterminate = picked > 0 && picked < checks.length;
            }
        }
        checks.forEach(function (check) { check.addEventListener('change', updateSelection); });
        if (checkAll) {
            checkAll.addEventListener('change', function () {
                checks.forEach(function (check) { check.checked = checkAll.checked; });
                updateSelection();
            });
        }

        var filterForm = document.getElementById('cdFilterForm');
        var searchInput = document.getElementById('cdSearch');
        var searchTimer = null;
        searchInput.addEventListener('input', function () {
            clearTimeout(searchTimer);
            searchTimer = setTimeout(function () { filterForm.submit(); }, 500);
        });
        // Every search reloads the page, so the cursor goes back to the end of the text.
        if (searchInput.value !== '') {
            searchInput.focus();
            searchInput.setSelectionRange(searchInput.value.length, searchInput.value.length);
        }

        // Approving fetches place details and runs Gemini, so it can take a while.
        document.addEventListener('submit', function (event) {
            var button = event.submitter;
            if (!button || !button.dataset.busyLabel) return;
            setTimeout(function () {
                button.disabled = true;
                button.innerHTML = '<span class="spinner-border spinner-border-sm" aria-hidden="true"></span>' + button.dataset.busyLabel;
            });
        });

        // Candidate detail modal. Text goes in with textContent: names come from OpenStreetMap.
        var detailModal = document.getElementById('cdDetailModal');
        function openCandidateDetail(candidate) {
            var lat = candidate.lat, lng = candidate.lng, pad = 0.004;
            document.getElementById('cdDtTitle').textContent = candidate.name;
            document.getElementById('cdDtSub').textContent = candidate.area ? 'Kecamatan ' + candidate.area : '';
            document.getElementById('cdDtIcon').className = 'bi ' + candidate.type.icon;

            var type = document.getElementById('cdDtType');
            type.className = 'cd-type ' + candidate.type.class;
            type.innerHTML = '<i class="bi ' + candidate.type.icon + '" aria-hidden="true"></i>';
            type.appendChild(document.createTextNode(candidate.type.label));
            var status = document.getElementById('cdDtStatus');
            status.className = 'cd-status is-' + candidate.status.key;
            status.innerHTML = '<i class="bi ' + candidate.status.icon + '" aria-hidden="true"></i>';
            status.appendChild(document.createTextNode(candidate.status.label));

            document.getElementById('cdDtArea').textContent = candidate.area || '-';
            document.getElementById('cdDtCoords').textContent = lat.toFixed(5) + ', ' + lng.toFixed(5);
            document.getElementById('cdDtOsm').textContent = candidate.osm || '-';
            document.getElementById('cdDtFound').textContent = candidate.found || '-';
            document.getElementById('cdDtUpdated').textContent = candidate.updated || '-';
            document.getElementById('cdDtMap').src = 'https://www.openstreetmap.org/export/embed.html?layer=mapnik'
                + '&bbox=' + [lng - pad, lat - pad, lng + pad, lat + pad].join(',')
                + '&marker=' + lat + ',' + lng;
            document.getElementById('cdDtOsmLink').href = 'https://www.openstreetmap.org/?mlat=' + lat + '&mlon=' + lng + '#map=18/' + lat + '/' + lng;

            var approve = document.getElementById('cdDtApprove');
            var reject = document.getElementById('cdDtReject');
            approve.hidden = !candidate.can_approve;
            reject.hidden = !candidate.can_reject;
            approve.setAttribute('form', 'cdApprove' + candidate.id);
            reject.setAttribute('form', 'cdReject' + candidate.id);
            document.getElementById('cdDtNote').hidden = !candidate.can_approve;

            bootstrap.Modal.getOrCreateInstance(detailModal).show();
        }
        document.querySelectorAll('[data-candidate]').forEach(function (trigger) {
            trigger.addEventListener('click', function () { openCandidateDetail(JSON.parse(trigger.dataset.candidate)); });
        });
        // Stop loading the map once the modal is closed.
        detailModal.addEventListener('hidden.bs.modal', function () { document.getElementById('cdDtMap').removeAttribute('src'); });

        // Discovery progress: polls the latest run while it is queued or running.
        var discovery = {
            run: @json($discoveryRun),
            startUrl: @json(route('admin.candidates.discover')),
            statusUrl: @json(route('admin.candidates.discovery')),
            csrf: @json(csrf_token()),
            steps: @json(\App\Services\Places\PlaceDiscoveryService::stepCount()),
            areas: @json(count(\App\Services\Places\PlaceDiscoveryService::AREAS)),
            types: @json($typeLabels),
            timer: null,
            starting: false,
        };
        var modalEl = document.getElementById('cdDiscoveryModal');
        var dmBody = document.getElementById('cdDmBody');
        var dmFoot = document.getElementById('cdDmFoot');

        function isActive(run) { return run && (run.status === 'queued' || run.status === 'running'); }
        function el(tag, className, text) {
            var node = document.createElement(tag);
            if (className) node.className = className;
            if (text !== undefined) node.textContent = text;
            return node;
        }
        function number(value) { return Number(value || 0).toLocaleString('id-ID'); }
        function stepLabel(step) {
            if (!step) return '';
            var parts = step.split(' x ');
            return parts[0] + ' · ' + (discovery.types[parts[1]] || parts[1]);
        }
        function dateLabel(iso) {
            return iso ? new Date(iso).toLocaleString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '';
        }
        function duration(run) {
            if (!run.started_at) return '';
            var seconds = Math.max(0, Math.round(((run.finished_at ? new Date(run.finished_at) : new Date()) - new Date(run.started_at)) / 1000));
            var minutes = Math.floor(seconds / 60);
            return (minutes > 0 ? minutes + ' menit ' : '') + (seconds % 60) + ' detik';
        }
        function button(className, iconClass, text, onClick) {
            var node = el('button', 'cd-btn ' + className);
            node.type = 'button';
            if (iconClass) node.appendChild(el('i', 'bi ' + iconClass));
            node.appendChild(document.createTextNode(text));
            if (onClick) node.addEventListener('click', onClick);
            return node;
        }
        function setHead(icon, iconClass, title, sub) {
            var iconBox = document.getElementById('cdDmIcon');
            iconBox.className = 'cd-dm-icon ' + (iconClass || '');
            iconBox.innerHTML = '<i class="bi ' + icon + '"></i>';
            document.getElementById('cdDmTitle').textContent = title;
            document.getElementById('cdDmSub').textContent = sub;
        }

        function renderIdle() {
            setHead('bi-radar', '', 'Discovery tempat baru', 'Cari kandidat tempat dari Geoapify (OpenStreetMap).');
            dmBody.replaceChildren(el('p', 'cd-dm-intro',
                'Discovery mencari tempat di ' + discovery.areas + ' kecamatan untuk 3 jenis tempat (' + discovery.steps
                + ' pencarian, sekitar ' + discovery.steps + ' kredit Geoapify dari 3.000 per hari). Prosesnya berjalan di latar belakang: '
                + 'halaman ini boleh ditutup, progresnya bisa dilihat lagi kapan saja. Tempat yang sudah ada di katalog atau pernah ditolak dilewati.'));
            var run = discovery.run;
            if (run && (run.status === 'finished' || run.status === 'failed')) {
                dmBody.appendChild(el('div', 'cd-dm-last', 'Terakhir dijalankan ' + dateLabel(run.created_at)
                    + (run.started_by ? ' oleh ' + run.started_by : '') + ': '
                    + (run.status === 'failed' ? 'gagal.' : number(run.inserted) + ' kandidat baru, ' + number(run.skipped) + ' dilewati, ' + number(run.failed_steps) + ' gagal.')));
            }
            dmFoot.replaceChildren(
                button('is-quiet', 'bi-x-lg', 'Batal', function () { bootstrap.Modal.getOrCreateInstance(modalEl).hide(); }),
                button('is-primary', 'bi-play-fill', 'Mulai Discovery', start)
            );
        }

        function renderRun(run) {
            var percent = run.total_steps ? Math.round(run.done_steps / run.total_steps * 100) : 0;
            if (run.status === 'queued') {
                setHead('bi-hourglass-split', '', 'Menunggu worker', 'Discovery masuk antrean, biasanya mulai dalam 1 menit.');
            } else if (run.status === 'running') {
                setHead('bi-radar', '', 'Discovery berjalan', 'Halaman ini boleh ditutup, Discovery tetap jalan di server.');
            } else if (run.status === 'finished') {
                setHead('bi-check-lg', 'is-finished', 'Discovery selesai', 'Selesai dalam ' + duration(run) + '.');
            } else {
                setHead('bi-exclamation-triangle', 'is-failed', 'Discovery gagal', 'Kandidat yang sudah ditemukan tetap tersimpan.');
            }

            var nodes = [];
            var head = el('div', 'cd-dm-progress-head');
            var count = el('span');
            count.appendChild(el('b', '', number(run.done_steps) + ' / ' + number(run.total_steps)));
            count.appendChild(document.createTextNode(' pencarian'));
            head.appendChild(count);
            head.appendChild(el('span', '', percent + '%' + (isActive(run) && run.started_at ? ' · ' + duration(run) : '')));
            nodes.push(head);
            var bar = el('div', 'cd-dm-bar ' + (run.status === 'finished' ? 'is-finished' : run.status === 'failed' ? 'is-failed' : ''));
            bar.setAttribute('role', 'progressbar');
            bar.setAttribute('aria-valuemin', '0');
            bar.setAttribute('aria-valuemax', String(run.total_steps));
            bar.setAttribute('aria-valuenow', String(run.done_steps));
            var fill = el('div');
            fill.style.width = percent + '%';
            bar.appendChild(fill);
            nodes.push(bar);

            if (isActive(run)) {
                var current = el('div', 'cd-dm-current');
                current.innerHTML = '<span class="spinner-border spinner-border-sm text-primary" aria-hidden="true"></span>';
                current.appendChild(document.createTextNode(run.status === 'queued'
                    ? 'Menunggu giliran di antrean...'
                    : (run.current_step ? 'Terakhir selesai: ' + stepLabel(run.current_step) : 'Memulai pencarian pertama...')));
                nodes.push(current);
            }

            var stats = el('div', 'cd-dm-stats');
            [['is-new', 'Kandidat baru', run.inserted], ['', 'Dilewati (sudah ada)', run.skipped], ['is-fail', 'Pencarian gagal', run.failed_steps]].forEach(function (item) {
                var box = el('div', 'cd-dm-stat ' + item[0]);
                box.appendChild(el('span', '', item[1]));
                box.appendChild(el('b', '', number(item[2])));
                stats.appendChild(box);
            });
            nodes.push(stats);

            if (run.error) nodes.push(el('p', 'cd-dm-error', run.error));

            if (run.log && run.log.length) {
                nodes.push(el('h3', 'cd-dm-log-title', 'Rincian per pencarian'));
                var list = el('ul', 'cd-dm-log');
                run.log.slice().reverse().forEach(function (entry) {
                    var item = el('li', entry.error ? 'is-error' : '');
                    item.appendChild(el('i', 'bi ' + (entry.error ? 'bi-x-circle-fill' : 'bi-check-circle-fill')));
                    item.appendChild(el('span', 'cd-dm-log-step', entry.area + ' · ' + (discovery.types[entry.type] || entry.type)));
                    item.appendChild(el('span', 'cd-dm-log-result', entry.error
                        ? entry.error
                        : '+' + number(entry.inserted) + ' baru · ' + number(entry.skipped) + ' dilewati'));
                    list.appendChild(item);
                });
                nodes.push(list);
            }
            dmBody.replaceChildren.apply(dmBody, nodes);

            if (isActive(run)) {
                dmFoot.replaceChildren(button('is-quiet', 'bi-box-arrow-right', 'Tutup, biarkan berjalan', function () { bootstrap.Modal.getOrCreateInstance(modalEl).hide(); }));
            } else {
                dmFoot.replaceChildren(
                    button('is-quiet', 'bi-arrow-repeat', 'Jalankan lagi', renderIdle),
                    button('is-primary', 'bi-list-check', 'Lihat kandidat', function () { window.location.reload(); })
                );
            }
        }

        function updateTopbar() {
            var run = discovery.run;
            var label = document.getElementById('cdDiscoverLabel');
            var topbarButton = document.getElementById('cdDiscover');
            var spinner = topbarButton.querySelector('.spinner-border');
            if (isActive(run)) {
                label.textContent = run.status === 'queued' ? 'Discovery mengantre' : 'Discovery ' + run.done_steps + '/' + run.total_steps;
                if (!spinner) topbarButton.insertAdjacentHTML('afterbegin', '<span class="spinner-border spinner-border-sm" aria-hidden="true"></span>');
                topbarButton.querySelector('.bi-radar')?.classList.add('d-none');
            } else {
                label.textContent = 'Jalankan Discovery';
                if (spinner) spinner.remove();
                topbarButton.querySelector('.bi-radar')?.classList.remove('d-none');
            }
        }

        function render() {
            updateTopbar();
            if (discovery.run && (isActive(discovery.run) || discovery.showResult)) {
                renderRun(discovery.run);
            } else {
                renderIdle();
            }
        }

        function poll() {
            clearTimeout(discovery.timer);
            if (!isActive(discovery.run)) return;
            var modalOpen = modalEl.classList.contains('show');
            discovery.timer = setTimeout(function () {
                fetch(discovery.statusUrl, { headers: { Accept: 'application/json' } })
                    .then(function (response) { return response.json(); })
                    .then(function (body) {
                        var wasActive = isActive(discovery.run);
                        discovery.run = body.run;
                        if (wasActive && !isActive(body.run)) discovery.showResult = true;
                        render();
                        poll();
                    })
                    .catch(poll);
            }, modalOpen ? 2000 : 6000);
        }

        function start() {
            if (discovery.starting) return;
            discovery.starting = true;
            dmFoot.querySelectorAll('button').forEach(function (node) { node.disabled = true; });
            fetch(discovery.startUrl, {
                method: 'POST',
                headers: { Accept: 'application/json', 'X-CSRF-TOKEN': discovery.csrf },
            })
                .then(function (response) { return response.json(); })
                .then(function (body) {
                    discovery.run = body.run;
                    discovery.showResult = true;
                    render();
                    poll();
                })
                .catch(function () {
                    dmBody.replaceChildren(el('p', 'cd-dm-error', 'Discovery tidak bisa dimulai, coba lagi.'));
                    renderIdleFoot();
                })
                .finally(function () { discovery.starting = false; });
        }
        function renderIdleFoot() {
            dmFoot.replaceChildren(button('is-primary', 'bi-play-fill', 'Coba lagi', start));
        }

        modalEl.addEventListener('show.bs.modal', function () {
            discovery.showResult = discovery.showResult || isActive(discovery.run);
            render();
            poll();
        });
        modalEl.addEventListener('hidden.bs.modal', function () {
            if (!isActive(discovery.run)) discovery.showResult = false;
            poll();
        });
        render();
        poll();
    })();
</script>
@endpush
