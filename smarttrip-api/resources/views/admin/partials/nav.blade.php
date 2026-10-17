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
    .admin-rail-user[aria-expanded="true"] { background: rgba(255, 255, 255, .1); }
    .admin-user-menu { position: fixed; z-index: 1060; min-width: 180px; padding: 6px; border: 1px solid #e2e8f0; border-radius: 14px; background: #fff; box-shadow: 0 16px 40px rgba(10, 36, 64, .22); font-family: 'Plus Jakarta Sans', system-ui, sans-serif; }
    .admin-user-menu[hidden] { display: none; }
    .admin-user-menu-item { display: flex; align-items: center; gap: 10px; width: 100%; height: 42px; padding: 0 12px; border: 0; border-radius: 10px; background: transparent; font: 600 14px/1 'Plus Jakarta Sans', system-ui, sans-serif; text-align: left; cursor: pointer; }
    .admin-user-menu-item svg { flex-shrink: 0; width: 19px; height: 19px; }
    .admin-user-menu-item.is-danger { color: #c0392b; }
    .admin-user-menu-item.is-danger:hover, .admin-user-menu-item.is-danger:focus-visible { background: #fdecea; outline: none; }
    /* Small screens: the rail leaves the layout and slides in over the page
       from the topbar's menu button, always at its full width with labels. */
    .admin-rail-backdrop { display: none; }
    .admin-menu-button { display: none; }
    @media (max-width: 767.98px) {
        /* .is-ready is listed too: the desktop ".admin-rail.is-ready { transition: width }"
           is more specific and would otherwise switch the slide animation off. */
        .admin-rail, .admin-rail.is-ready, .admin-rail.is-expanded {
            position: fixed; left: 0; top: 0; z-index: 1050; width: 260px;
            transform: translateX(-100%); box-shadow: none; will-change: transform;
            transition: transform .32s cubic-bezier(.22, .61, .36, 1), box-shadow .32s ease;
        }
        .admin-rail .admin-rail-label { opacity: 1; }
        .admin-rail-toggle { visibility: hidden; }
        .admin-rail.is-open { transform: translateX(0); box-shadow: 12px 0 40px rgba(10, 36, 64, .35); }
        /* Always rendered on small screens so it can fade in and out instead of popping. */
        .admin-rail-backdrop { display: block; position: fixed; inset: 0; z-index: 1040; background: rgba(10, 36, 64, .45);
            opacity: 0; visibility: hidden; transition: opacity .32s ease, visibility 0s linear .32s; }
        .admin-rail-backdrop.is-open { opacity: 1; visibility: visible; transition: opacity .32s ease, visibility 0s; }
        .admin-menu-button { display: inline-flex; align-items: center; justify-content: center; width: 44px; height: 44px; flex-shrink: 0; border: 0; border-radius: 12px; background: rgba(255, 255, 255, .12); color: #fff; cursor: pointer; }
        .admin-menu-button svg { width: 22px; height: 22px; }
    }
    @media (prefers-reduced-motion: reduce) { .admin-rail, .admin-rail.is-ready, .admin-rail *, .admin-rail-label, .admin-rail-backdrop { transition: none !important; } }
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
    <button type="button" class="admin-rail-user" id="adminUserButton" title="{{ $userName }}"
        aria-haspopup="menu" aria-expanded="false" aria-controls="adminUserMenu">
        <span class="admin-rail-avatar" aria-hidden="true">{{ $initials }}</span>
        <span class="admin-rail-label">{{ $userName }}<small>Admin</small></span>
    </button>
</nav>
<div class="admin-rail-backdrop" id="adminRailBackdrop" aria-hidden="true"></div>
{{-- Outside the rail: the rail clips its overflow, so the menu is placed with
     position: fixed next to the profile button when it opens. --}}
<div class="admin-user-menu" id="adminUserMenu" role="menu" aria-labelledby="adminUserButton" hidden>
    <form method="POST" action="{{ route('admin.logout') }}" class="admin-rail-logout">
        @csrf
        <button type="submit" class="admin-user-menu-item is-danger" role="menuitem">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 17l5-5-5-5M15 12H3"/>
            </svg>
            Keluar
        </button>
    </form>
</div>
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
            closeUserMenu();
        });

        // Profile dropdown: opens beside the profile button, bottom-aligned with it.
        var userButton = document.getElementById('adminUserButton');
        var userMenu = document.getElementById('adminUserMenu');

        function openUserMenu() {
            var rect = userButton.getBoundingClientRect();
            // Beside the button on the rail; above it in the slide-in menu, where there is no room beside.
            var stacked = window.matchMedia('(max-width: 767.98px)').matches;
            userMenu.style.left = (stacked ? rect.left : rect.right + 10) + 'px';
            userMenu.style.bottom = (window.innerHeight - (stacked ? rect.top - 8 : rect.bottom)) + 'px';
            userMenu.hidden = false;
            userButton.setAttribute('aria-expanded', 'true');
            userMenu.querySelector('[role="menuitem"]').focus();
        }
        function closeUserMenu(returnFocus) {
            if (userMenu.hidden) return;
            userMenu.hidden = true;
            userButton.setAttribute('aria-expanded', 'false');
            if (returnFocus) userButton.focus();
        }

        userButton.addEventListener('click', function (e) {
            e.stopPropagation();
            userMenu.hidden ? openUserMenu() : closeUserMenu();
        });
        document.addEventListener('click', function (e) {
            if (!userMenu.contains(e.target)) closeUserMenu();
        });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && !userMenu.hidden) {
                closeUserMenu(true);
                e.preventDefault(); // so the same Esc does not also close the slide-in menu
            }
        });
        window.addEventListener('resize', function () { closeUserMenu(); });

        // Small screens: slide-in menu, opened by the topbar's ☰ button.
        var backdrop = document.getElementById('adminRailBackdrop');
        var smallScreen = window.matchMedia('(max-width: 767.98px)');
        function setMenuOpen(open) {
            rail.classList.toggle('is-open', open);
            backdrop.classList.toggle('is-open', open);
            document.querySelectorAll('[data-admin-menu-open]').forEach(function (button) {
                button.setAttribute('aria-expanded', open ? 'true' : 'false');
            });
            document.body.style.overflow = open ? 'hidden' : '';
            if (!open) closeUserMenu();
        }
        // Delegated: the ☰ button lives in the topbar, which renders after this
        // script, so binding it directly here would find no button.
        document.addEventListener('click', function (e) {
            if (!e.target.closest('[data-admin-menu-open]')) return;
            setMenuOpen(true);
            rail.querySelector('a').focus();
        });
        backdrop.addEventListener('click', function () { setMenuOpen(false); });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && !e.defaultPrevented && rail.classList.contains('is-open')) setMenuOpen(false);
        });
        // Back to the normal rail when the window grows past the breakpoint.
        smallScreen.addEventListener('change', function () { if (!smallScreen.matches) setMenuOpen(false); });
    })();
</script>
