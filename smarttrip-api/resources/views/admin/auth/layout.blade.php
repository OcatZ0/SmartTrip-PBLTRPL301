<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · SmartTrip Admin</title>
    <link rel="icon" type="image/svg+xml" href="{{ asset('images/logo.svg') }}">
    <link rel="icon" href="{{ asset('images/logo.png') }}" type="image/png">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* 1. Living dusk: the sun drifts, its glow breathes, the reflection ripples, stars twinkle. */
        .auth-sun-drift { animation: auth-sun-drift 14s ease-in-out infinite alternate; }
        .auth-glow { animation: auth-glow 7s ease-in-out infinite alternate; }
        .auth-ripple { transform-box: fill-box; transform-origin: center; animation: auth-ripple 3.6s ease-in-out infinite; animation-delay: calc(var(--d) * -1.2s); }
        .auth-star { animation: auth-twinkle 4s ease-in-out infinite; animation-delay: calc(var(--d) * -0.37s); }
        @keyframes auth-sun-drift { from { transform: translateY(0); } to { transform: translateY(12px); } }
        @keyframes auth-glow { from { opacity: .75; } to { opacity: 1; } }
        @keyframes auth-ripple { 0%, 100% { transform: scaleX(1); opacity: 1; } 50% { transform: scaleX(.82); opacity: .6; } }
        @keyframes auth-twinkle { 0%, 100% { opacity: .15; } 50% { opacity: .85; } }

        /* 2. Opening: the scene fades in, the sun rises, the cables draw from the towers, then the card and its rows. */
        .auth-intro .auth-scene { animation: auth-fade .6s ease-out both; }
        .auth-intro .auth-sun-rise { animation: auth-sun-rise 1.2s cubic-bezier(.22, .61, .36, 1) .15s both; }
        .auth-intro .auth-cable { stroke-dasharray: 1; animation: auth-draw .7s ease-out both; animation-delay: calc(.3s + var(--i) * 28ms); }
        .auth-intro .auth-header { animation: auth-drop .5s ease-out .1s both; }
        .auth-intro .auth-card { animation: auth-rise .6s cubic-bezier(.22, .61, .36, 1) .35s both; }
        .auth-intro .auth-card > * { animation: auth-rise .5s ease-out both; animation-delay: calc(.5s + var(--n, 0) * 60ms); }
        .auth-intro .auth-card > :nth-child(2) { --n: 1; }
        .auth-intro .auth-card > :nth-child(3) { --n: 2; }
        .auth-intro .auth-card > :nth-child(4) { --n: 3; }
        .auth-intro .auth-card > :nth-child(5) { --n: 4; }
        .auth-intro .auth-card > :nth-child(6) { --n: 5; }
        .auth-intro .auth-card > :nth-child(7) { --n: 6; }
        .auth-intro .auth-card > :nth-child(n+8) { --n: 7; }
        @keyframes auth-fade { from { opacity: 0; } }
        @keyframes auth-sun-rise { from { transform: translateY(70px); } }
        @keyframes auth-draw { from { stroke-dashoffset: 1; } to { stroke-dashoffset: 0; } }
        @keyframes auth-drop { from { opacity: 0; transform: translateY(-10px); } }
        @keyframes auth-rise { from { opacity: 0; transform: translateY(18px); } }

        /* 3. Parallax: each layer moves sideways by --depth times --px (-1..1), set on the scene by the script below.
           Only the stars also move up and down (--depth-y): everything standing on the waterline would lift off the sea. */
        .auth-layer { transform: translate3d(calc(var(--px, 0) * var(--depth) * 1px), calc(var(--py, 0) * var(--depth-y, 0) * 1px), 0); }

        /* 5. Leaving after a successful login: the card shrinks away, the sun sets, the screen dims. */
        .auth-curtain { position: absolute; inset: 0; z-index: 20; background: #0a2440; opacity: 0; pointer-events: none; transition: opacity .35s ease .3s; }
        .auth-sun-set { transition: transform .7s cubic-bezier(.55, 0, .75, .45); }
        .auth-card { transition: transform .4s ease, opacity .4s ease; }
        .auth-leaving .auth-card { transform: scale(.94) translateY(8px); opacity: 0; }
        .auth-leaving .auth-sun-set { transform: translateY(150px); }
        .auth-leaving .auth-curtain { opacity: 1; }

        @media (prefers-reduced-motion: reduce) {
            .auth-sun-drift, .auth-glow, .auth-ripple, .auth-star,
            .auth-intro .auth-scene, .auth-intro .auth-sun-rise, .auth-intro .auth-cable, .auth-intro .auth-header,
            .auth-intro .auth-card, .auth-intro .auth-card > * { animation: none !important; }
            .auth-layer { transform: none !important; }
            .auth-curtain, .auth-sun-set, .auth-card { transition: none !important; }
        }
    </style>
</head>
<body class="m-0 font-['Plus_Jakarta_Sans',system-ui,sans-serif] antialiased">
{{-- The opening plays on a fresh visit only, not when the form comes back with errors. --}}
<div class="auth-root relative flex min-h-screen flex-col overflow-hidden bg-[#0a2440] text-white {{ $errors->any() ? '' : 'auth-intro' }}">
    {{-- Barelang bridge at dusk, the same scene as the mobile login. Layers further away move less. --}}
    <svg viewBox="0 0 1440 600" preserveAspectRatio="xMidYMax slice" aria-hidden="true" class="auth-scene absolute inset-0 h-full w-full">
        <defs>
            <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a2440"/><stop offset="0.55" stop-color="#16476d"/><stop offset="1" stop-color="#4f8fb8"/></linearGradient>
            <radialGradient id="glow" cx="1240" cy="440" r="520" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f6b03c" stop-opacity="0.55"/><stop offset="1" stop-color="#f6b03c" stop-opacity="0"/></radialGradient>
            <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16476d"/><stop offset="1" stop-color="#0a2440"/></linearGradient>
        </defs>
        <rect width="1440" height="440" fill="url(#sky)"/>
        <g class="auth-layer" style="--depth: 4; --depth-y: 4">
            @foreach ([[90, 60], [230, 140], [340, 40], [520, 110], [610, 30], [760, 150], [880, 70], [1060, 50], [1150, 130], [1330, 80], [1390, 190], [40, 210], [680, 230], [960, 210]] as [$starX, $starY])
                <circle class="auth-star" style="--d: {{ $loop->index }}" cx="{{ $starX }}" cy="{{ $starY }}" r="{{ $loop->index % 3 === 0 ? 1.6 : 1.1 }}" fill="#ffffff"/>
            @endforeach
        </g>
        <g class="auth-layer" style="--depth: 6">
            <g class="auth-sun-rise"><g class="auth-sun-set"><g class="auth-sun-drift">
                <rect class="auth-glow" width="1440" height="440" fill="url(#glow)"/>
                <circle cx="1240" cy="440" r="70" fill="#f6b03c"/>
            </g></g></g>
        </g>
        <g class="auth-layer" style="--depth: 10">
            <path d="M-60 440 V420 L0 420 Q120 400 240 414 Q360 398 480 418 Q600 404 720 424 Q780 432 840 440 Z" fill="#16476d" opacity="0.85"/>
        </g>
        <rect y="440" width="1440" height="160" fill="url(#sea)"/>
        <g class="auth-layer" style="--depth: 10">
            <g fill="#f6b03c">
                <rect class="auth-ripple" style="--d: 0" x="1150" y="452" width="180" height="5" rx="2.5" opacity="0.7"/>
                <rect class="auth-ripple" style="--d: 1" x="1180" y="468" width="120" height="5" rx="2.5" opacity="0.5"/>
                <rect class="auth-ripple" style="--d: 2" x="1205" y="484" width="70" height="5" rx="2.5" opacity="0.35"/>
            </g>
        </g>
        <g class="auth-layer" style="--depth: 16">
            <g fill="#0a2440"><rect x="-40" y="372" width="1520" height="10"/><rect x="160" y="382" width="12" height="58"/><rect x="706" y="382" width="12" height="58"/><rect x="1240" y="382" width="12" height="58"/><rect x="404" y="150" width="16" height="290"/><rect x="1004" y="150" width="16" height="290"/></g>
            {{-- Twelve cables per tower, nearest first, so they draw outward from the tower. --}}
            <g stroke="#0a2440" stroke-width="2" fill="none">
                @foreach ([412, 1012] as $towerX)
                    @for ($k = 1; $k <= 6; $k++)
                        <path class="auth-cable" style="--i: {{ ($k - 1) * 2 }}" pathLength="1" d="M{{ $towerX }} 175L{{ $towerX - 48 * $k }} 372"/>
                        <path class="auth-cable" style="--i: {{ ($k - 1) * 2 + 1 }}" pathLength="1" d="M{{ $towerX }} 175L{{ $towerX + 48 * $k }} 372"/>
                    @endfor
                @endforeach
            </g>
        </g>
    </svg>

    <header class="auth-header relative flex items-center gap-3 px-6 py-6 sm:px-10">
        <span class="flex h-10 w-10 items-center justify-center rounded-full bg-white">
            <img src="{{ asset('images/logo.svg') }}" alt="" class="h-6 w-6">
        </span>
        <span class="text-[17px] font-extrabold">SmartTrip</span>
        <span class="rounded-full border border-white/30 bg-white/15 px-2.5 py-0.5 text-xs font-bold">Admin</span>
    </header>

    <main class="relative flex flex-1 items-center justify-center px-4 pb-16 pt-6">
        @yield('content')
    </main>

    <footer class="relative pb-5 text-center text-xs text-white/70">© {{ date('Y') }} SmartTrip</footer>
    <div class="auth-curtain" aria-hidden="true"></div>
</div>
<script>
    // 3. Parallax: follow the mouse (or the phone's tilt), eased toward the target each frame.
    (function () {
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
        var scene = document.querySelector('.auth-scene');
        var target = { x: 0, y: 0 };
        var current = { x: 0, y: 0 };
        var running = false;

        function frame() {
            current.x += (target.x - current.x) * 0.08;
            current.y += (target.y - current.y) * 0.08;
            scene.style.setProperty('--px', current.x.toFixed(3));
            scene.style.setProperty('--py', current.y.toFixed(3));
            if (Math.abs(target.x - current.x) > 0.001 || Math.abs(target.y - current.y) > 0.001) {
                requestAnimationFrame(frame);
            } else {
                running = false;
            }
        }

        function aim(x, y) {
            target.x = Math.max(-1, Math.min(1, x));
            target.y = Math.max(-1, Math.min(1, y));
            if (!running) {
                running = true;
                requestAnimationFrame(frame);
            }
        }

        if (window.matchMedia('(pointer: fine)').matches) {
            document.addEventListener('pointermove', function (event) {
                aim(event.clientX / window.innerWidth * 2 - 1, event.clientY / window.innerHeight * 2 - 1);
            });
            document.addEventListener('pointerleave', function () { aim(0, 0); });
        } else if (window.DeviceOrientationEvent && typeof DeviceOrientationEvent.requestPermission !== 'function') {
            // Android tilts without asking; iOS needs a permission prompt, so it stays still there.
            window.addEventListener('deviceorientation', function (event) {
                if (event.gamma === null) return;
                aim(event.gamma / 25, (event.beta - 45) / 25);
            });
        }
    })();
</script>
@stack('scripts')
</body>
</html>
