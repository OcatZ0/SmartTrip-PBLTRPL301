<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title') · SmartTrip Admin</title>
    <link rel="icon" type="image/svg+xml" href="{{ asset('images/logo.svg') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="m-0 font-['Plus_Jakarta_Sans',system-ui,sans-serif] antialiased">
<div class="relative flex min-h-screen flex-col overflow-hidden bg-[#0a2440] text-white">
    {{-- Barelang bridge at dusk, the same scene as the mobile login. --}}
    <svg viewBox="0 0 1440 600" preserveAspectRatio="xMidYMax slice" aria-hidden="true" class="absolute inset-0 h-full w-full">
        <defs>
            <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a2440"/><stop offset="0.55" stop-color="#16476d"/><stop offset="1" stop-color="#4f8fb8"/></linearGradient>
            <radialGradient id="glow" cx="1240" cy="440" r="520" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f6b03c" stop-opacity="0.55"/><stop offset="1" stop-color="#f6b03c" stop-opacity="0"/></radialGradient>
            <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16476d"/><stop offset="1" stop-color="#0a2440"/></linearGradient>
        </defs>
        <rect width="1440" height="440" fill="url(#sky)"/>
        <rect width="1440" height="440" fill="url(#glow)"/>
        <circle cx="1240" cy="440" r="70" fill="#f6b03c"/>
        <path d="M0 440 V420 Q120 400 240 414 Q360 398 480 418 Q600 404 720 424 Q780 432 840 440 Z" fill="#16476d" opacity="0.85"/>
        <rect y="440" width="1440" height="160" fill="url(#sea)"/>
        <g fill="#f6b03c"><rect x="1150" y="452" width="180" height="5" rx="2.5" opacity="0.7"/><rect x="1180" y="468" width="120" height="5" rx="2.5" opacity="0.5"/><rect x="1205" y="484" width="70" height="5" rx="2.5" opacity="0.35"/></g>
        <g fill="#0a2440"><rect x="-20" y="372" width="1480" height="10"/><rect x="160" y="382" width="12" height="58"/><rect x="706" y="382" width="12" height="58"/><rect x="1240" y="382" width="12" height="58"/><rect x="404" y="150" width="16" height="290"/><rect x="1004" y="150" width="16" height="290"/></g>
        <path d="M412 175L364 372M412 175L460 372M412 175L316 372M412 175L508 372M412 175L268 372M412 175L556 372M412 175L220 372M412 175L604 372M412 175L172 372M412 175L652 372M412 175L124 372M412 175L700 372M1012 175L964 372M1012 175L1060 372M1012 175L916 372M1012 175L1108 372M1012 175L868 372M1012 175L1156 372M1012 175L820 372M1012 175L1204 372M1012 175L772 372M1012 175L1252 372M1012 175L724 372M1012 175L1300 372" stroke="#0a2440" stroke-width="2" fill="none"/>
    </svg>

    <header class="relative flex items-center gap-3 px-6 py-6 sm:px-10">
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
</div>
</body>
</html>
