<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Admin') - SmartTrip Batam</title>
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
            --admin-bg: #F8FAFC;
            --sidebar-bg: #0D192B;
            --sidebar-active: #1672B8;
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

        /* Sidebar Styling (Flat, No Glow) */
        .sidebar {
            width: 260px;
            background-color: var(--sidebar-bg);
            color: #94A3B8;
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 20px 14px;
            border-right: 1px solid rgba(255, 255, 255, 0.05);
        }

        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 4px 8px 20px 8px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            margin-bottom: 20px;
        }

        .brand-logo-img {
            height: 34px;
            width: auto;
            object-fit: contain;
        }

        .brand-title {
            font-size: 15px;
            font-weight: 800;
            color: #FFFFFF;
            line-height: 1.2;
            letter-spacing: -0.2px;
        }

        .brand-subtitle {
            font-size: 11px;
            color: #94A3B8;
            font-weight: 500;
        }

        .nav-section-label {
            font-size: 10.5px;
            font-weight: 800;
            letter-spacing: 0.8px;
            color: #64748B;
            text-transform: uppercase;
            padding: 0 12px 8px 12px;
        }

        .sidebar-nav {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .sidebar-nav-item a {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            border-radius: 10px;
            color: #94A3B8;
            text-decoration: none;
            font-size: 13.5px;
            font-weight: 700;
            transition: background-color 0.15s ease, color 0.15s ease;
        }

        .sidebar-nav-item a:hover {
            color: #FFFFFF;
            background-color: rgba(255, 255, 255, 0.06);
        }

        .sidebar-nav-item.active a {
            background-color: var(--sidebar-active);
            color: #FFFFFF;
        }

        .sidebar-user-card {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 12px;
            background-color: rgba(255, 255, 255, 0.04);
            border-radius: 12px;
            border: 1px solid rgba(255, 255, 255, 0.08);
        }

        .user-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            object-fit: cover;
        }

        .user-info {
            flex: 1;
            overflow: hidden;
        }

        .user-name {
            font-size: 13px;
            font-weight: 800;
            color: #FFFFFF;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .user-role {
            font-size: 11px;
            color: #94A3B8;
            font-weight: 500;
        }

        /* Main Content Wrapper */
        .main-wrapper {
            margin-left: 260px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Top Header */
        .top-header {
            height: 60px;
            background-color: #FFFFFF;
            border-bottom: 1px solid #E2E8F0;
            padding: 0 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 900;
        }

        .breadcrumb-text {
            font-size: 13px;
            color: #64748B;
            font-weight: 600;
        }

        .top-search-bar {
            position: relative;
            width: 300px;
        }

        .top-search-bar input {
            width: 100%;
            height: 36px;
            background-color: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 8px;
            padding-left: 36px;
            padding-right: 14px;
            font-size: 13px;
            color: #334155;
            outline: none;
        }

        .top-search-bar input:focus {
            background-color: #FFFFFF;
            border-color: var(--primary-blue);
        }

        .top-search-bar i {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #94A3B8;
            font-size: 13px;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .btn-preview-app {
            height: 36px;
            padding: 0 14px;
            border-radius: 8px;
            border: 1px solid #CBD5E1;
            background-color: #FFFFFF;
            color: #334155;
            font-size: 12.5px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 6px;
            text-decoration: none;
        }

        .btn-preview-app:hover {
            background-color: #F1F5F9;
            color: #0F172A;
        }

        .notification-btn {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background-color: #F8FAFC;
            border: 1px solid #E2E8F0;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #475569;
            position: relative;
            cursor: pointer;
        }

        .notification-badge {
            position: absolute;
            top: 5px;
            right: 5px;
            width: 7px;
            height: 7px;
            background-color: #EF4444;
            border-radius: 50%;
            border: 1.5px solid #FFFFFF;
        }

        .content-area {
            padding: 20px 24px;
            flex: 1;
            display: flex;
            flex-direction: column;
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

    <!-- Sidebar Nav -->
    <aside class="sidebar">
        <div>
            <!-- Brand Logo -->
            <div class="sidebar-brand">
                <img src="{{ asset('images/logo_white.png') }}" alt="SmartTrip" class="brand-logo-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div style="display: none;" class="align-items-center gap-2">
                    <i class="bi bi-compass-fill fs-4 text-primary"></i>
                </div>
                <div>
                    <div class="brand-title">SmartTrip Batam</div>
                    <div class="brand-subtitle">Portal Kurator & Admin</div>
                </div>
            </div>

            <!-- Navigation Links (Only Kelola Tempat as requested) -->
            <div class="nav-section-label">Navigasi Kurasi</div>
            <ul class="sidebar-nav">
                <li class="sidebar-nav-item {{ request()->routeIs('admin.places.*') ? 'active' : '' }}">
                    <a href="{{ route('admin.places.index') }}">
                        <i class="bi bi-geo-alt-fill"></i>
                        <span>Kelola Tempat</span>
                    </a>
                </li>
                <li class="sidebar-nav-item {{ request()->routeIs('admin.categories.*') ? 'active' : '' }}">
                    <a href="{{ route('admin.categories.index') }}">
                        <i class="bi bi-bookmark-fill"></i>
                        <span>Kelola Kategori</span>
                    </a>
                </li>
            </ul>
        </div>

        <!-- Sidebar User Footer -->
        <div>
            <div class="sidebar-user-card">
                <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=faces" alt="Avatar" class="user-avatar">
                <div class="user-info">
                    <div class="user-name">{{ Auth::user()->name ?? 'Dian Pratama' }}</div>
                    <div class="user-role">Admin Kurator</div>
                </div>
            </div>
        </div>
    </aside>

    <!-- Main Content Area -->
    <div class="main-wrapper">
        <!-- Top Navbar -->
        <header class="top-header">
            <div class="breadcrumb-text">
                Admin Batam / <strong style="color: #0F172A;">@yield('breadcrumb', 'Manajemen Destinasi')</strong>
            </div>

            <div class="header-actions">
                <div class="top-search-bar d-none d-md-block">
                    <i class="bi bi-search"></i>
                    <input type="text" placeholder="Cari tempat, kurasi, tagar...">
                </div>

                <a href="#" class="btn-preview-app">
                    <i class="bi bi-box-arrow-up-right"></i>
                    <span>Pratinjau Aplikasi Traveler</span>
                </a>

                <div class="notification-btn" title="Notifikasi">
                    <i class="bi bi-bell"></i>
                    <span class="notification-badge"></span>
                </div>
            </div>
        </header>

        <!-- Page Main View -->
        <main class="content-area">
            @yield('content')
        </main>
    </div>

    <!-- jQuery: used by the place photo manager (admin/places/photos) -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    @stack('scripts')
</body>
</html>
