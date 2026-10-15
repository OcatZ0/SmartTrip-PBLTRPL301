@php
    $idNumber = fn ($number) => number_format((float) $number, 0, ',', '.');
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
            'meta' => fn ($candidate) => ($candidate->search_area ?: '-') . ' · dari Geoapify',
            'chip' => fn ($candidate) => $typeLabel($candidate->type),
            'url' => fn ($candidate) => route('admin.candidates.index'),
            'all' => route('admin.candidates.index'),
        ],
        [
            'title' => 'Belum ada harga',
            'items' => $missingCostList,
            'total' => $placesMissingCost,
            'action' => 'Lengkapi',
            'tag' => 'bg-[#fff4df] text-[#7a4b00]',
            'meta' => fn ($place) => ($place->kecamatan ?: '-') . ' · ' . $typeLabel($place->type),
            'chip' => fn ($place) => match ($place->type) { 'culinary' => 'Biaya makan', 'lodging' => 'Harga kamar', default => 'Tiket masuk' },
            'url' => fn ($place) => route('admin.places.edit', $place),
            'all' => route('admin.places.index'),
        ],
        [
            'title' => 'Tag belum dicek',
            'items' => $untaggedList,
            'total' => $placesTagsNotReviewed,
            'action' => 'Cek tag',
            'tag' => 'bg-[#eef2f8] text-[#14212f]',
            'meta' => fn ($place) => 'Usulan: ' . ($place->categories->pluck('name_id')->join(', ') ?: '-'),
            'chip' => fn ($place) => $place->categories->count() . ' tag',
            'url' => fn ($place) => route('admin.places.edit', $place),
            'all' => route('admin.places.index'),
        ],
    ];

    $formatTime = fn ($time) => $time->translatedFormat('j M Y, H.i');
    $syncStatus = [
        $lastDiscoveryAt ? 'Discovery terakhir ' . $formatTime($lastDiscoveryAt) : 'Discovery belum pernah dijalankan',
        $lastEnrichmentAt ? 'Pelengkapan data terakhir ' . $formatTime($lastEnrichmentAt) : 'Data belum pernah dilengkapi',
        $idNumber($pendingCandidates) . ' kandidat menunggu',
    ];

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
        <x-admin.topbar title="Dashboard" :subtitle="$syncStatus">
            <form method="POST" action="{{ route('admin.candidates.discover') }}">
                @csrf
                <button type="submit" class="admin-topbar-action">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
                    Jalankan Discovery
                </button>
            </form>
        </x-admin.topbar>

        <main class="flex flex-col gap-7 px-6 pb-10 sm:px-8">
            <div class="relative -mt-12 grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-4">
                @foreach ($kpis as $kpi)
                    <div class="flex flex-col gap-1 rounded-[18px] bg-white px-5 py-[18px] shadow-[0_18px_40px_-16px_rgba(10,36,64,0.3)]">
                        <span class="text-[13px] font-semibold text-[#5d6b7c]">{{ $kpi['label'] }}</span>
                        <span class="text-[30px] font-extrabold leading-9">{{ $kpi['value'] }}</span>
                        <span class="text-xs text-[#5d6b7c]">{{ $kpi['note'] }}</span>
                    </div>
                @endforeach
            </div>

            @if (session('status'))
                <div role="status" class="rounded-xl bg-[#e3f6ec] px-4 py-3 text-sm font-semibold text-[#1d7a55]">{{ session('status') }}</div>
            @endif

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
