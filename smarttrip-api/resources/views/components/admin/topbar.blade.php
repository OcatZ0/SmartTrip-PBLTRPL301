@props(['title', 'subtitle' => null, 'backUrl' => null, 'backLabel' => null])
@php
    $subtitleItems = collect(is_array($subtitle) ? $subtitle : [$subtitle])->filter(fn ($item) => filled((string) $item));
    $cables = collect([640, 960])->flatMap(fn ($pylonX) => collect(range(1, 7))->map(fn ($cable) => sprintf('M%d %dL%d 168M%d %dL%d 168', $pylonX, 58 + $cable * 4, $pylonX - $cable * 22, $pylonX, 58 + $cable * 4, $pylonX + $cable * 22)))->join('');
@endphp
{{-- Plain CSS so the topbar renders the same on the Tailwind dashboard and the Bootstrap pages. --}}
<style>
    .admin-topbar { position: relative; overflow: hidden; display: flex; flex-wrap: wrap; align-items: flex-start; justify-content: space-between; gap: 16px 24px; box-sizing: border-box; min-height: 192px; padding: 28px 32px 32px; color: #fff; font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
        /* Same stops as the SVG sky and sea, so the scene continues seamlessly to the left of the illustration. */
        background: linear-gradient(180deg, #0a2440 0%, #16476d 37.5%, #4f8fb8 83.33%, #16476d 83.33%, #0a2440 100%); }
    .admin-topbar-scene { position: absolute; right: 0; bottom: 0; height: 100%; width: auto; max-width: none; aspect-ratio: 1100 / 240; }
    .admin-topbar::after { content: ''; position: absolute; inset: 0; background: linear-gradient(90deg, rgba(10, 36, 64, .9) 0%, rgba(10, 36, 64, .68) 38%, rgba(10, 36, 64, .12) 72%, rgba(10, 36, 64, 0) 100%); pointer-events: none; }
    .admin-topbar-text, .admin-topbar-actions { position: relative; z-index: 1; }
    .admin-topbar-text { display: flex; flex-direction: column; gap: 6px; min-width: 0; max-width: 64ch; }
    .admin-topbar-back { display: inline-flex; align-items: center; gap: 6px; align-self: flex-start; color: rgba(255, 255, 255, .78); font-size: 13px; font-weight: 600; text-decoration: none; }
    .admin-topbar-back:hover { color: #fff; }
    .admin-topbar-back svg { width: 16px; height: 16px; }
    .admin-topbar-title { margin: 0; color: #fff; font-size: 28px; font-weight: 800; line-height: 1.25; letter-spacing: -.02em; overflow-wrap: anywhere; }
    .admin-topbar-subtitle { display: flex; flex-wrap: wrap; gap: 4px 0; margin: 0; padding: 0; list-style: none; color: rgba(255, 255, 255, .84); font-size: 14px; line-height: 1.5; }
    .admin-topbar-subtitle li + li { margin-left: 12px; padding-left: 12px; border-left: 1px solid rgba(255, 255, 255, .3); }
    .admin-topbar-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; }
    .admin-topbar-actions form { margin: 0; }
    .admin-topbar-action { display: inline-flex; align-items: center; gap: 8px; height: 44px; padding: 0 18px; border: 0; border-radius: 12px; background: #f6b03c; color: #0a2440; font: 700 14px/1 'Plus Jakarta Sans', system-ui, sans-serif; text-decoration: none; cursor: pointer; transition: background-color .15s ease; }
    .admin-topbar-action:hover { background: #f8bf5c; color: #0a2440; }
    .admin-topbar-action.is-quiet { background: rgba(255, 255, 255, .12); color: #fff; box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .32); }
    .admin-topbar-action.is-quiet:hover { background: rgba(255, 255, 255, .2); color: #fff; }
    .admin-topbar a:focus-visible, .admin-topbar button:focus-visible { outline: 3px solid rgba(246, 176, 60, .6); outline-offset: 2px; }
    @media (max-width: 640px) {
        .admin-topbar { padding: 22px 16px 28px; }
        .admin-topbar-title { font-size: 24px; }
    }
</style>
<header class="admin-topbar">
    <svg class="admin-topbar-scene" viewBox="0 0 1100 240" preserveAspectRatio="xMaxYMax meet" aria-hidden="true" focusable="false">
        <defs>
            <linearGradient id="admin-topbar-sky" x1="0" y1="0" x2="0" y2="200" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#0a2440"/><stop offset=".45" stop-color="#16476d"/><stop offset="1" stop-color="#4f8fb8"/></linearGradient>
            <linearGradient id="admin-topbar-sea" x1="0" y1="200" x2="0" y2="240" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#16476d"/><stop offset="1" stop-color="#0a2440"/></linearGradient>
            <radialGradient id="admin-topbar-glow" cx="800" cy="150" r="320" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f6b03c" stop-opacity=".55"/><stop offset=".5" stop-color="#f6b03c" stop-opacity=".16"/><stop offset="1" stop-color="#f6b03c" stop-opacity="0"/></radialGradient>
        </defs>
        <rect width="1100" height="200" fill="url(#admin-topbar-sky)"/>
        <rect width="1100" height="200" fill="url(#admin-topbar-glow)"/>
        <circle cx="800" cy="150" r="36" fill="#f6b03c"/>
        <g fill="#2b5f8a" opacity=".6">
            <path d="M40 200C120 186 190 183 262 195C300 189 342 188 384 200Z"/>
            <path d="M1010 200C1040 191 1068 188 1100 190V200Z"/>
        </g>
        <rect y="200" width="1100" height="40" fill="url(#admin-topbar-sea)"/>
        <g fill="#f6b03c">
            <rect x="755" y="205" width="90" height="2.5" rx="1.25" opacity=".55"/>
            <rect x="770" y="212" width="60" height="2.5" rx="1.25" opacity=".4"/>
            <rect x="782" y="219" width="36" height="2" rx="1" opacity=".3"/>
            <rect x="791" y="226" width="18" height="2" rx="1" opacity=".2"/>
        </g>
        <g fill="#0a2440">
            <path d="M400 200L470 168H1100V175H473L412 200Z"/>
            <rect x="516" y="175" width="8" height="25"/>
            <rect x="1056" y="175" width="8" height="25"/>
            <path d="M633 200L636 52H644L647 200Z"/>
            <path d="M953 200L956 52H964L967 200Z"/>
            <rect x="627" y="176" width="26" height="6"/>
            <rect x="947" y="176" width="26" height="6"/>
        </g>
        <path d="{{ $cables }}" stroke="#0a2440" stroke-width="1.4" fill="none"/>
    </svg>

    <div class="admin-topbar-text">
        @if ($backUrl)
            <a href="{{ $backUrl }}" class="admin-topbar-back">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
                {{ $backLabel }}
            </a>
        @endif
        <h1 class="admin-topbar-title">{{ $title }}</h1>
        @if ($subtitleItems->isNotEmpty())
            <ul class="admin-topbar-subtitle">
                @foreach ($subtitleItems as $item)
                    <li>{{ $item }}</li>
                @endforeach
            </ul>
        @endif
    </div>

    @if (trim($slot) !== '')
        <div class="admin-topbar-actions">{{ $slot }}</div>
    @endif
</header>
