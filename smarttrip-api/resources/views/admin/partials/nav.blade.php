@php
    $navItems = [
        ['label' => 'Dashboard', 'route' => 'admin.dashboard', 'pattern' => 'admin.dashboard', 'd' => 'M3 3h7v9H3zM14 3h7v5h-7zM14 12h7v9h-7zM3 16h7v5H3z'],
        ['label' => 'Kandidat Tempat', 'route' => 'admin.candidates.index', 'pattern' => 'admin.candidates.*', 'd' => 'M9 11l3 3 8-8M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9'],
        ['label' => 'Kelola Tempat', 'route' => 'admin.places.index', 'pattern' => 'admin.places.*', 'd' => 'M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21zM12 7a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z'],
        ['label' => 'Kelola Kategori', 'route' => 'admin.categories.index', 'pattern' => 'admin.categories.*', 'd' => 'M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8zM7.5 7.5h.01'],
    ];
    $userName = auth()->user()->name;
    $initials = \Illuminate\Support\Str::of($userName)->explode(' ')->take(2)->map(fn ($word) => mb_substr($word, 0, 1))->join('');
@endphp
{{-- Plain CSS instead of Tailwind or Bootstrap classes, since the rail is shared by the Tailwind dashboard and the Bootstrap pages. --}}
<style>
    .admin-rail { position: sticky; top: 0; z-index: 1000; display: flex; flex-direction: column; align-items: stretch; gap: 8px; box-sizing: border-box; width: 76px; height: 100vh; flex-shrink: 0; padding: 20px 14px; overflow: hidden; background: #0a2440; color: #fff; font-family: 'Plus Jakarta Sans', system-ui, sans-serif; }
    .admin-rail.is-ready { transition: width .2s ease; }
    .admin-rail.is-expanded { width: 240px; }
    .admin-rail a, .admin-rail button { display: flex; flex-shrink: 0; align-items: center; gap: 12px; box-sizing: border-box; text-decoration: none; transition: background-color .15s ease, color .15s ease; }
    .admin-rail-label { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; opacity: 0; transition: opacity .15s ease; }
    .admin-rail.is-expanded .admin-rail-label { opacity: 1; }
    .admin-rail-brand { height: 44px; margin-bottom: 16px; padding: 0 2px; color: #fff; font-size: 17px; font-weight: 800; }
    .admin-rail-brand:hover { color: #fff; }
    .admin-rail-logo { display: flex; flex-shrink: 0; align-items: center; justify-content: center; width: 44px; height: 44px; border-radius: 14px; background: #fff; }
    .admin-rail-logo img { display: block; width: 24px; height: 24px; }
    .admin-rail-link, .admin-rail-toggle { width: 100%; height: 48px; padding: 0 13.5px; border: 0; border-radius: 14px; background: transparent; color: rgba(255, 255, 255, .7); font: 600 14px/1 'Plus Jakarta Sans', system-ui, sans-serif; cursor: pointer; }
    .admin-rail-link:hover, .admin-rail-toggle:hover { background: rgba(255, 255, 255, .1); color: #fff; }
    .admin-rail-link[aria-current="page"] { background: #2b6fab; color: #fff; }
    .admin-rail svg { flex-shrink: 0; width: 21px; height: 21px; }
    .admin-rail-toggle { margin-top: auto; }
    .admin-rail-toggle svg { transition: transform .2s ease; }
    .admin-rail.is-expanded .admin-rail-toggle svg { transform: rotate(180deg); }
    .admin-rail-logout { margin: 0; }
    .admin-rail-user { width: 100%; height: 48px; padding: 0 4px; border: 0; border-radius: 14px; background: transparent; color: #fff; font: 600 14px/1.25 'Plus Jakarta Sans', system-ui, sans-serif; text-align: left; cursor: pointer; }
    .admin-rail-user:hover { background: rgba(255, 255, 255, .1); }
    .admin-rail-avatar { display: flex; flex-shrink: 0; align-items: center; justify-content: center; width: 40px; height: 40px; border-radius: 50%; background: #2b6fab; font-size: 13px; font-weight: 800; }
    .admin-rail-user small { display: block; color: rgba(255, 255, 255, .7); font-size: 12px; font-weight: 500; }
    .admin-rail a:focus-visible, .admin-rail button:focus-visible { outline: 2px solid #f6b03c; outline-offset: 2px; }
    @media (prefers-reduced-motion: reduce) { .admin-rail.is-ready, .admin-rail *, .admin-rail-label { transition: none !important; } }
</style>
<nav aria-label="Navigasi admin" id="admin-rail" class="admin-rail">
    <a href="{{ route('admin.dashboard') }}" class="admin-rail-brand" aria-label="SmartTrip">
        <span class="admin-rail-logo"><img src="{{ asset('images/logo.png') }}" alt=""></span>
        <span class="admin-rail-label">SmartTrip</span>
    </a>
    @foreach ($navItems as $item)
        <a href="{{ route($item['route']) }}" class="admin-rail-link" title="{{ $item['label'] }}" @if (request()->routeIs($item['pattern'])) aria-current="page" @endif>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{ $item['d'] }}"/></svg>
            <span class="admin-rail-label">{{ $item['label'] }}</span>
        </a>
    @endforeach
    <button type="button" class="admin-rail-toggle" aria-controls="admin-rail" aria-expanded="false" title="Perbesar menu">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13 6l6 6-6 6M5 6l6 6-6 6"/></svg>
        <span class="admin-rail-label">Perkecil menu</span>
    </button>
    <form method="POST" action="{{ route('admin.logout') }}" class="admin-rail-logout">
        @csrf
        <button type="submit" class="admin-rail-user" title="Keluar">
            <span class="admin-rail-avatar" aria-hidden="true">{{ $initials }}</span>
            <span class="admin-rail-label">{{ $userName }}<small>Keluar</small></span>
        </button>
    </form>
</nav>
<script>
    (function () {
        var rail = document.getElementById('admin-rail');
        var toggle = rail.querySelector('.admin-rail-toggle');
        var key = 'smarttrip.admin.railExpanded';

        function apply(expanded) {
            rail.classList.toggle('is-expanded', expanded);
            toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
            toggle.title = expanded ? 'Perkecil menu' : 'Perbesar menu';
            toggle.querySelector('.admin-rail-label').textContent = expanded ? 'Perkecil menu' : 'Perbesar menu';
        }

        var saved = false;
        try { saved = localStorage.getItem(key) === '1'; } catch (e) {}
        apply(saved);
        // Animate only user toggles, not the restored state on page load.
        requestAnimationFrame(function () { rail.classList.add('is-ready'); });

        toggle.addEventListener('click', function () {
            var expanded = !rail.classList.contains('is-expanded');
            apply(expanded);
            try { localStorage.setItem(key, expanded ? '1' : '0'); } catch (e) {}
        });
    })();
</script>
