@php
    $navItems = [
        ['label' => 'Dashboard', 'route' => 'admin.dashboard', 'pattern' => 'admin.dashboard', 'd' => 'M3 3h7v9H3zM14 3h7v5h-7zM14 12h7v9h-7zM3 16h7v5H3z'],
        ['label' => 'Kandidat Tempat', 'route' => 'admin.candidates.index', 'pattern' => 'admin.candidates.*', 'd' => 'M9 11l3 3 8-8M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9'],
        ['label' => 'Kelola Tempat', 'route' => 'admin.places.index', 'pattern' => 'admin.places.*', 'd' => 'M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21zM12 7a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z'],
        ['label' => 'Kelola Kategori', 'route' => 'admin.categories.index', 'pattern' => 'admin.categories.*', 'd' => 'M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8zM7.5 7.5h.01'],
    ];
    $initials = \Illuminate\Support\Str::of(auth()->user()->name)->explode(' ')->take(2)->map(fn ($w) => mb_substr($w, 0, 1))->join('');
@endphp
{{-- Plain CSS instead of Tailwind or Bootstrap classes, since the rail is shared by the Tailwind dashboard and the Bootstrap pages. --}}
<style>
    .admin-rail { position: sticky; top: 0; z-index: 1000; display: flex; flex-direction: column; align-items: center; gap: 8px; box-sizing: border-box; width: 76px; height: 100vh; flex-shrink: 0; padding: 20px 0; background: #0a2440; }
    .admin-rail a, .admin-rail button { display: flex; align-items: center; justify-content: center; text-decoration: none; transition: background-color .15s ease, color .15s ease; }
    .admin-rail-logo { width: 44px; height: 44px; margin-bottom: 16px; border-radius: 14px; background: #fff; }
    .admin-rail-logo img { display: block; width: 24px; height: 24px; }
    .admin-rail-link { width: 48px; height: 48px; border-radius: 14px; color: rgba(255, 255, 255, .7); }
    .admin-rail-link:hover { background: rgba(255, 255, 255, .1); color: #fff; }
    .admin-rail-link[aria-current="page"] { background: #2b6fab; color: #fff; }
    .admin-rail-link svg { width: 21px; height: 21px; }
    .admin-rail-logout { margin: auto 0 0; }
    .admin-rail-user { width: 40px; height: 40px; padding: 0; border: 0; border-radius: 50%; background: #2b6fab; color: #fff; font: 800 13px/1 'Plus Jakarta Sans', system-ui, sans-serif; cursor: pointer; }
    .admin-rail a:focus-visible, .admin-rail button:focus-visible { outline: 2px solid #f6b03c; outline-offset: 2px; }
</style>
<nav aria-label="Navigasi admin" class="admin-rail">
    <a href="{{ route('admin.dashboard') }}" class="admin-rail-logo" aria-label="SmartTrip">
        <img src="{{ asset('images/logo.png') }}" alt="SmartTrip">
    </a>
    @foreach ($navItems as $item)
        <a href="{{ route($item['route']) }}" class="admin-rail-link" aria-label="{{ $item['label'] }}" title="{{ $item['label'] }}" @if (request()->routeIs($item['pattern'])) aria-current="page" @endif>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{ $item['d'] }}"/></svg>
        </a>
    @endforeach
    <form method="POST" action="{{ route('admin.logout') }}" class="admin-rail-logout">
        @csrf
        <button type="submit" class="admin-rail-user" title="Keluar" aria-label="Keluar ({{ auth()->user()->name }})">{{ $initials }}</button>
    </form>
</nav>
