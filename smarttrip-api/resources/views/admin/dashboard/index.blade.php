@php
    $idNumber = fn ($n) => number_format((float) $n, 0, ',', '.');
    $typeLabel = fn ($type) => match ($type) { 'culinary' => 'Kuliner', 'lodging' => 'Hotel', default => 'Wisata' };

    $kpis = [
        ['label' => 'Kandidat menunggu', 'value' => $idNumber($pendingCandidates), 'note' => 'Perlu direview'],
        ['label' => 'Trip dibuat', 'value' => $idNumber($tripVolume), 'note' => 'Total semua pengguna'],
        ['label' => 'Rata-rata rating', 'value' => $averageInAppRating ? number_format($averageInAppRating, 1, ',', '.') : '-', 'note' => 'Dari ulasan di aplikasi'],
        ['label' => 'Kredit Geoapify', 'value' => $idNumber($quotaUsed), 'note' => 'dari ' . $idNumber($quotaLimit) . ' hari ini'],
    ];

    $columns = [
        [
            'title' => 'Kandidat baru',
            'items' => $recentCandidates,
            'total' => $pendingCandidates,
            'action' => 'Review',
            'tag' => 'bg-[#dceaf6] text-[#16476d]',
            'meta' => fn ($c) => ($c->search_area ?: '-') . ' · dari Geoapify',
            'chip' => fn ($c) => $typeLabel($c->type),
            'url' => fn ($c) => route('admin.candidates.index'),
            'all' => route('admin.candidates.index'),
        ],
        [
            'title' => 'Belum ada harga',
            'items' => $missingCostList,
            'total' => $placesMissingCost,
            'action' => 'Lengkapi',
            'tag' => 'bg-[#fff4df] text-[#7a4b00]',
            'meta' => fn ($p) => ($p->kecamatan ?: '-') . ' · ' . $typeLabel($p->type),
            'chip' => fn ($p) => match ($p->type) { 'culinary' => 'Biaya makan', 'lodging' => 'Harga kamar', default => 'Tiket masuk' },
            'url' => fn ($p) => route('admin.places.edit', $p),
            'all' => route('admin.places.index'),
        ],
        [
            'title' => 'Tag belum dicek',
            'items' => $untaggedList,
            'total' => $placesTagsNotReviewed,
            'action' => 'Cek tag',
            'tag' => 'bg-[#eef2f8] text-[#14212f]',
            'meta' => fn ($p) => 'Usulan: ' . ($p->categories->pluck('name_id')->join(', ') ?: '-'),
            'chip' => fn ($p) => $p->categories->count() . ' tag',
            'url' => fn ($p) => route('admin.places.edit', $p),
            'all' => route('admin.places.index'),
        ],
    ];

    $formatTime = fn ($time) => $time->translatedFormat('j M Y, H.i');
    $syncStatus = collect([
        $lastDiscoveryAt ? 'Discovery terakhir ' . $formatTime($lastDiscoveryAt) : 'Discovery belum pernah dijalankan',
        $lastEnrichmentAt ? 'Pelengkapan data terakhir ' . $formatTime($lastEnrichmentAt) : 'Data belum pernah dilengkapi',
        $idNumber($pendingCandidates) . ' kandidat menunggu',
    ])->join(' · ');

    $cables = collect([412, 1012])->flatMap(fn ($x) => collect(range(1, 6))->map(fn ($k) => "M{$x} 175L" . ($x - $k * 48) . " 372M{$x} 175L" . ($x + $k * 48) . ' 372'))->join('');
@endphp
<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard · SmartTrip Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="m-0 bg-[#f5f7fb] font-['Plus_Jakarta_Sans',system-ui,sans-serif] text-[#14212f] antialiased">
<div class="flex min-h-screen">
    @include('admin.partials.nav')

    <div class="flex min-w-0 flex-1 flex-col">
        <header class="relative h-[230px] overflow-hidden bg-[#0a2440] text-white">
            <svg viewBox="0 0 1440 600" preserveAspectRatio="xMidYMax slice" aria-hidden="true" class="absolute inset-0 h-full w-full">
                <defs>
                    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a2440"/><stop offset="0.55" stop-color="#16476d"/><stop offset="1" stop-color="#4f8fb8"/></linearGradient>
                    <radialGradient id="glow" cx="1240" cy="440" r="520" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f6b03c" stop-opacity="0.55"/><stop offset="1" stop-color="#f6b03c" stop-opacity="0"/></radialGradient>
                    <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16476d"/><stop offset="1" stop-color="#0a2440"/></linearGradient>
                </defs>
                <rect width="1440" height="440" fill="url(#sky)"/>
                <rect width="1440" height="440" fill="url(#glow)"/>
                <circle cx="1240" cy="440" r="70" fill="#f6b03c"/>
                <rect y="440" width="1440" height="160" fill="url(#sea)"/>
                <g fill="#0a2440"><rect x="-20" y="372" width="1480" height="10"/><rect x="160" y="382" width="12" height="58"/><rect x="706" y="382" width="12" height="58"/><rect x="1240" y="382" width="12" height="58"/><rect x="404" y="150" width="16" height="290"/><rect x="1004" y="150" width="16" height="290"/></g>
                <path d="{{ $cables }}" stroke="#0a2440" stroke-width="2" fill="none"/>
            </svg>
            <div class="absolute inset-0 bg-gradient-to-r from-[#0a2440]/85 to-[#0a2440]/20"></div>
            <div class="relative flex flex-wrap justify-between gap-4 px-6 pt-8 sm:px-8">
                <div class="flex flex-col gap-1.5">
                    <span class="text-xs font-bold tracking-[0.08em] text-[#f6b03c]">PANEL KURASI</span>
                    <h1 class="m-0 text-[30px] font-extrabold leading-9 tracking-[-0.02em]">Dashboard</h1>
                    <p class="m-0 text-sm text-white/85">{{ $syncStatus }}</p>
                </div>
                <form method="POST" action="{{ route('admin.candidates.discover') }}" class="self-start">
                    @csrf
                    <button type="submit" class="flex h-11 items-center gap-2 rounded-xl border-0 bg-[#f6b03c] px-4 text-sm font-bold text-[#0a2440] transition hover:bg-[#f8bf5c] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f6b03c]/40">
                        <svg class="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
                        Jalankan Discovery
                    </button>
                </form>
            </div>
        </header>

        <main class="flex flex-col gap-7 px-6 pb-10 sm:px-8">
            @if (session('status'))
                <div role="status" class="relative z-10 mt-4 rounded-xl bg-[#e3f6ec] px-4 py-3 text-sm font-semibold text-[#1d7a55]">{{ session('status') }}</div>
            @endif

            <div class="relative -mt-14 grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-4">
                @foreach ($kpis as $kpi)
                    <div class="flex flex-col gap-1 rounded-[18px] bg-white px-5 py-[18px] shadow-[0_18px_40px_-16px_rgba(10,36,64,0.3)]">
                        <span class="text-[13px] font-semibold text-[#5d6b7c]">{{ $kpi['label'] }}</span>
                        <span class="text-[30px] font-extrabold leading-9">{{ $kpi['value'] }}</span>
                        <span class="text-xs text-[#5d6b7c]">{{ $kpi['note'] }}</span>
                    </div>
                @endforeach
            </div>

            <div class="grid grid-cols-[repeat(auto-fit,minmax(280px,1fr))] items-start gap-5">
                @foreach ($columns as $col)
                    <section class="flex flex-col gap-2.5 rounded-[20px] bg-[#eef2f8] p-3.5">
                        <div class="flex items-center justify-between px-1.5 py-1">
                            <h2 class="m-0 text-[15px] font-bold leading-[22px]">{{ $col['title'] }}</h2>
                            <span class="rounded-full bg-white px-2.5 py-0.5 text-xs font-extrabold">{{ $col['total'] }}</span>
                        </div>
                        @forelse ($col['items'] as $item)
                            <div class="flex flex-col gap-2 rounded-[14px] bg-white p-3.5">
                                <b class="text-sm">{{ $item->name }}</b>
                                <span class="text-xs text-[#5d6b7c]">{{ $col['meta']($item) }}</span>
                                <div class="flex items-center justify-between">
                                    <span class="rounded-full px-2.5 py-0.5 text-[11px] font-bold {{ $col['tag'] }}">{{ $col['chip']($item) }}</span>
                                    <a href="{{ $col['url']($item) }}" class="text-[13px] font-bold text-[#1f5f99] no-underline hover:text-[#16476d]">{{ $col['action'] }}</a>
                                </div>
                            </div>
                        @empty
                            <p class="m-0 rounded-[14px] bg-white p-3.5 text-[13px] text-[#5d6b7c]">Tidak ada yang perlu dikerjakan.</p>
                        @endforelse
                        @if ($col['total'] > $col['items']->count())
                            <a href="{{ $col['all'] }}" class="px-1.5 py-2 text-[13px] font-bold text-[#1f5f99] no-underline hover:text-[#16476d]">Lihat semua</a>
                        @endif
                    </section>
                @endforeach
            </div>
            <section class="flex flex-col gap-1 rounded-[20px] bg-white p-5 shadow-[0_18px_40px_-16px_rgba(10,36,64,0.18)]">
                <h2 class="m-0 mb-2 text-[15px] font-bold leading-[22px]">Paling banyak di-wishlist</h2>
                @forelse ($mostWishlistedPlaces as $place)
                    <div class="flex items-center gap-3 border-t border-[#eef2f8] py-2.5 first-of-type:border-t-0">
                        <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#dceaf6] text-xs font-extrabold text-[#16476d]">{{ $loop->iteration }}</span>
                        <div class="flex min-w-0 flex-1 flex-col">
                            <a href="{{ route('admin.places.edit', $place) }}" class="truncate text-sm font-bold text-[#14212f] no-underline hover:text-[#1f5f99]">{{ $place->name }}</a>
                            <span class="text-xs text-[#5d6b7c]">{{ ($place->kecamatan ?: '-') . ' · ' . $typeLabel($place->type) }}</span>
                        </div>
                        <span class="shrink-0 text-[13px] font-bold">{{ $idNumber($place->wishlisted_in_count) }} wishlist</span>
                    </div>
                @empty
                    <p class="m-0 text-[13px] text-[#5d6b7c]">Belum ada tempat yang masuk wishlist.</p>
                @endforelse
            </section>
        </main>
    </div>
</div>
</body>
</html>
