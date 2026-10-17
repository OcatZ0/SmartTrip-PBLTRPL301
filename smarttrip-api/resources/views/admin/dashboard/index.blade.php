@php
    $idNumber = fn ($number) => number_format((float) $number, 0, ',', '.');
    $typeLabel = fn ($type) => match ($type) { 'culinary' => 'Kuliner', 'lodging' => 'Hotel', default => 'Wisata' };

    $kpis = [
        ['label' => 'Kandidat menunggu', 'value' => $idNumber($pendingCandidates), 'note' => 'Perlu direview'],
        ['label' => 'Trip dibuat', 'value' => $idNumber($tripVolume), 'note' => 'Total semua pengguna'],
        ['label' => 'Rata-rata rating', 'value' => $averageInAppRating ? number_format($averageInAppRating, 1, ',', '.') : '-', 'note' => 'Dari ulasan di aplikasi'],
        ['label' => 'Tempat di katalog', 'value' => $idNumber($placeCount), 'note' => 'Wisata, kuliner dan hotel'],
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

    // Bar colour by how much of the free quota is gone.
    $quotaTone = fn (?int $percent) => match (true) {
        $percent === null => ['bar' => 'bg-[#c3cddb]', 'chip' => 'bg-[#eef2f8] text-[#5d6b7c]'],
        $percent >= 90 => ['bar' => 'bg-[#c0392b]', 'chip' => 'bg-[#fdecea] text-[#912018]'],
        $percent >= 70 => ['bar' => 'bg-[#f6b03c]', 'chip' => 'bg-[#fff4df] text-[#7a4b00]'],
        default => ['bar' => 'bg-[#2e9e6b]', 'chip' => 'bg-[#e3f6ec] text-[#1d7a55]'],
    };

    // Stored in UTC (config app.timezone); shown in Batam time.
    $formatTime = fn ($time) => $time->copy()->timezone('Asia/Jakarta')->translatedFormat('j M Y, H.i') . ' WIB';
    $syncStatus = [
        $lastDiscoveryAt ? 'Discovery terakhir ' . $formatTime($lastDiscoveryAt) : 'Discovery belum pernah dijalankan',
        $lastApprovedAt ? 'Tempat terakhir disetujui ' . $formatTime($lastApprovedAt) : 'Belum ada tempat yang disetujui',
        $idNumber($pendingCandidates) . ' kandidat menunggu',
    ];

@endphp
<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard · SmartTrip Admin</title>
    <link rel="icon" href="{{ asset('images/logo.svg') }}" type="image/svg+xml">
    <link rel="icon" href="{{ asset('images/logo.png') }}" type="image/png">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="m-0 bg-[#f5f7fb] font-['Plus_Jakarta_Sans',system-ui,sans-serif] text-[#14212f] antialiased">
<div class="flex min-h-screen">
    @include('admin.partials.nav')

    <div class="flex min-w-0 flex-1 flex-col">
        {{-- Discovery is started from Kandidat Tempat, where its progress modal lives. --}}
        <x-admin.topbar title="Dashboard" :subtitle="$syncStatus" />

        {{-- Phones: 2 KPI columns, a smaller overlap into the (shorter) topbar, 16px sides. --}}
        <main class="flex flex-col gap-6 px-4 pb-10 sm:gap-7 sm:px-8">
            <div class="relative -mt-6 grid grid-cols-2 gap-3 md:-mt-12 md:grid-cols-[repeat(auto-fit,minmax(200px,1fr))] md:gap-4">
                @foreach ($kpis as $kpi)
                    <div class="flex min-w-0 flex-col gap-1 rounded-[18px] bg-white px-4 py-4 shadow-[0_18px_40px_-16px_rgba(10,36,64,0.3)] sm:px-5 sm:py-[18px]">
                        <span class="text-[12px] font-semibold text-[#5d6b7c] sm:text-[13px]">{{ $kpi['label'] }}</span>
                        <span class="text-[24px] font-extrabold leading-8 sm:text-[30px] sm:leading-9">{{ $kpi['value'] }}</span>
                        <span class="text-xs text-[#5d6b7c]">{{ $kpi['note'] }}</span>
                    </div>
                @endforeach
            </div>

            @if (session('status'))
                <div role="status" class="rounded-xl bg-[#e3f6ec] px-4 py-3 text-sm font-semibold text-[#1d7a55]">{{ session('status') }}</div>
            @endif

            <div class="grid grid-cols-[repeat(auto-fit,minmax(min(280px,100%),1fr))] items-start gap-4 sm:gap-5">
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
            <div class="grid items-start gap-4 sm:gap-5 lg:grid-cols-2">
            <section class="flex flex-col gap-1 rounded-[20px] bg-white p-5 shadow-[0_18px_40px_-16px_rgba(10,36,64,0.18)]">
                <h2 class="m-0 mb-2 text-[15px] font-bold leading-[22px]">Paling banyak di-wishlist</h2>
                @forelse ($mostWishlistedPlaces as $place)
                    <div class="flex items-center gap-3 border-t border-[#eef2f8] py-2.5 first-of-type:border-t-0">
                        <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#dceaf6] text-xs font-extrabold text-[#16476d]">{{ $loop->iteration }}</span>
                        <div class="flex min-w-0 flex-1 flex-col">
                            <a href="{{ route('admin.places.edit', $place) }}" class="truncate text-sm font-bold text-[#14212f] no-underline hover:text-[#1f5f99]">{{ $place->name }}</a>
                            <span class="text-xs text-[#5d6b7c]">{{ ($place->kecamatan ?: '-') . ' · ' . $typeLabel($place->type) }}</span>
                        </div>
                        <span class="shrink-0 whitespace-nowrap text-[13px] font-bold">{{ $idNumber($place->wishlisted_in_count) }} wishlist</span>
                    </div>
                @empty
                    <p class="m-0 text-[13px] text-[#5d6b7c]">Belum ada tempat yang masuk wishlist.</p>
                @endforelse
            </section>

            <section class="flex flex-col gap-3 rounded-[20px] bg-white p-5 shadow-[0_18px_40px_-16px_rgba(10,36,64,0.18)]" aria-labelledby="apiQuotaTitle">
                <div class="flex items-baseline justify-between gap-3">
                    <h2 id="apiQuotaTitle" class="m-0 text-[15px] font-bold leading-[22px]">Kuota API</h2>
                    <span class="text-xs text-[#5d6b7c]">Paket gratis</span>
                </div>
                <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    @foreach ($apiQuotas as $quota)
                        @php
                            $percent = $quota['used'] === null || $quota['limit'] <= 0 ? null : (int) min(100, round($quota['used'] / $quota['limit'] * 100));
                            $tone = $quotaTone($percent);
                        @endphp
                        <div class="flex min-w-0 flex-col gap-2 rounded-[14px] bg-[#f5f7fb] p-3.5">
                            <div class="flex items-center justify-between gap-2">
                                <b class="text-sm">{{ $quota['name'] }}</b>
                                <span class="rounded-full px-2 py-0.5 text-[11px] font-bold {{ $tone['chip'] }}">{{ $percent === null ? '-' : $percent . '%' }}</span>
                            </div>
                            <span class="text-xs text-[#5d6b7c]">{{ $quota['purpose'] }}</span>
                            <div class="text-[20px] font-extrabold leading-7">
                                {{ $quota['used'] === null ? '-' : $idNumber($quota['used']) }}
                                <span class="text-[13px] font-semibold text-[#5d6b7c]">/ {{ $idNumber($quota['limit']) }} {{ $quota['period'] }}</span>
                            </div>
                            <div class="h-2 overflow-hidden rounded-full bg-[#e3e9f2]" role="progressbar" aria-label="Pemakaian {{ $quota['name'] }}"
                                 aria-valuemin="0" aria-valuemax="100" aria-valuenow="{{ $percent ?? 0 }}">
                                <div class="h-full rounded-full {{ $tone['bar'] }}" style="width: {{ $percent ?? 0 }}%"></div>
                            </div>
                            <span class="text-[11px] text-[#5d6b7c]">{{ $quota['resets'] }}</span>
                        </div>
                    @endforeach
                </div>
                <p class="m-0 text-[11px] leading-4 text-[#5d6b7c]">SerpApi dibaca langsung dari akunnya. Gemini, Geoapify dan OpenRouteService dihitung dari pemakaian aplikasi ini, jadi pemakaian di luar aplikasi (misalnya AI Studio) tidak ikut terhitung.</p>
            </section>
            </div>
        </main>
    </div>
</div>
</body>
</html>
