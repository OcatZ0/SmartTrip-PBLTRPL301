<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Admin') · SmartTrip Admin</title>
    <!-- Google Fonts Plus Jakarta Sans -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

    <style>
        :root {
            --admin-bg: #F5F7FB;
            --primary-blue: #1672B8;
            --font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
        }

        * {
            font-family: var(--font-family);
        }

        body {
            font-family: var(--font-family);
            background-color: var(--admin-bg);
            color: #1E293B;
            min-height: 100vh;
            overflow-x: hidden;
        }

        .admin-shell {
            display: flex;
            min-height: 100vh;
        }

        .admin-page {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
        }

        .content-area {
            flex: 1;
            padding: 24px 32px;
            display: flex;
            flex-direction: column;
        }

        @media (max-width: 640px) {
            .content-area {
                padding: 20px 16px;
            }
        }

        /* Scrollbar */
        ::-webkit-scrollbar {
            width: 5px;
            height: 5px;
        }
        ::-webkit-scrollbar-track {
            background: #F1F5F9;
        }
        ::-webkit-scrollbar-thumb {
            background: #CBD5E1;
            border-radius: 3px;
        }
    </style>
    @stack('styles')
</head>
<body>
    <div class="admin-shell">
        @include('admin.partials.nav')

        <div class="admin-page">
            {{-- Short @section values arrive already escaped, so wrap them to avoid double escaping in the component. --}}
            <x-admin.topbar
                :title="new \Illuminate\Support\HtmlString($__env->hasSection('heading') ? $__env->yieldContent('heading') : $__env->yieldContent('title', 'Admin'))"
                :subtitle="new \Illuminate\Support\HtmlString($__env->yieldContent('subtitle'))"
                :back-url="$__env->yieldContent('back_url') ?: null"
                :back-label="new \Illuminate\Support\HtmlString($__env->yieldContent('back_label'))">
                @yield('topbar_actions')
            </x-admin.topbar>

            <main class="content-area">
                @yield('content')
            </main>
        </div>
    </div>

    <!-- jQuery: used by the place photo manager (admin/places/photos) -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    @stack('scripts')
</body>
</html>
