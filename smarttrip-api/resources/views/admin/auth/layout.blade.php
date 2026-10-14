<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title') - SmartTrip Admin</title>
    <link rel="icon" type="image/svg+xml" href="{{ asset('images/logo.svg') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root {
            --auth-primary: #005A92;
            --auth-primary-hover: #004A78;
            --auth-title: #0B4F80;
            --auth-link: #1672B8;
            --auth-ink: #1E293B;
            --auth-muted: #64748B;
            --auth-field: #EEF4FD;
            --auth-badge: #D6E6F7;
            --auth-line: #E2E8F0;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: #FFFFFF;
            color: var(--auth-ink);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px 16px;
        }

        .auth-card {
            width: 100%;
            max-width: 462px;
            background: #FFFFFF;
            border-radius: 16px;
            box-shadow: 0 2px 6px rgba(15, 23, 42, 0.10), 0 0 1px rgba(15, 23, 42, 0.08);
            padding: 64px 38px 72px;
        }

        .auth-brand { text-align: center; }
        .auth-brand img { width: 56px; height: auto; }
        .auth-brand-name {
            margin-top: 10px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            color: var(--auth-ink);
        }
        .auth-badge {
            background: var(--auth-badge);
            color: var(--auth-title);
            font-size: 13px;
            font-weight: 500;
            padding: 2px 8px;
            border-radius: 999px;
        }

        .auth-title {
            margin: 10px 0 4px;
            text-align: center;
            color: var(--auth-title);
            font-size: 18px;
            font-weight: 500;
        }
        .auth-title-lg { font-size: 22px; font-weight: 700; }
        .auth-subtitle {
            text-align: center;
            font-size: 13px;
            color: var(--auth-ink);
            margin-bottom: 26px;
        }

        .auth-label {
            font-size: 13px;
            font-weight: 500;
            color: var(--auth-ink);
            margin-bottom: 6px;
        }
        .auth-label-row {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
        }
        .auth-link {
            color: var(--auth-link);
            font-size: 13px;
            text-decoration: none;
        }
        .auth-link:hover { text-decoration: underline; color: var(--auth-link); }

        .auth-field {
            position: relative;
            margin-bottom: 18px;
        }
        .auth-field > .bi {
            position: absolute;
            left: 14px;
            top: 50%;
            transform: translateY(-50%);
            color: #475569;
            font-size: 16px;
            pointer-events: none;
        }
        .auth-input {
            width: 100%;
            height: 42px;
            border: 1px solid transparent;
            border-radius: 6px;
            background: var(--auth-field);
            padding: 0 42px 0 42px;
            font-size: 13px;
            color: var(--auth-ink);
            outline: none;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .auth-input::placeholder { color: #8A94A6; }
        .auth-input:focus {
            border-color: var(--auth-link);
            box-shadow: 0 0 0 3px rgba(22, 114, 184, 0.15);
            background: #FFFFFF;
        }
        .auth-input.is-invalid { border-color: #DC2626; }
        .auth-eye {
            position: absolute;
            right: 8px;
            top: 50%;
            transform: translateY(-50%);
            border: 0;
            background: transparent;
            color: #475569;
            padding: 4px 6px;
            line-height: 1;
        }

        .auth-check {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: var(--auth-ink);
            margin: 4px 0 16px;
        }
        .auth-check input {
            width: 18px;
            height: 18px;
            margin: 0;
            accent-color: var(--auth-primary);
        }

        .auth-submit {
            width: 100%;
            height: 42px;
            border: 0;
            border-radius: 6px;
            background: var(--auth-primary);
            color: #FFFFFF;
            font-size: 14px;
            font-weight: 500;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            box-shadow: 0 1px 3px rgba(0, 90, 146, 0.35);
            transition: background-color 0.15s ease;
        }
        .auth-submit:hover { background: var(--auth-primary-hover); }

        .auth-footer {
            border-top: 1px solid var(--auth-line);
            margin-top: 24px;
            padding-top: 18px;
            text-align: center;
            font-size: 13px;
            color: var(--auth-ink);
        }
        .auth-copyright {
            margin-top: 8px;
            color: var(--auth-muted);
            font-size: 13px;
        }

        .auth-alert {
            font-size: 13px;
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 18px;
        }
        .auth-error-text {
            color: #DC2626;
            font-size: 12px;
            margin: -12px 0 14px;
        }
    </style>
</head>
<body>
    <main class="auth-card">
        <div class="auth-brand">
            <img src="{{ asset('images/logo.svg') }}" alt="SmartTrip">
            <div>
                <span class="auth-brand-name">SmartTrip <span class="auth-badge">BATAM</span></span>
            </div>
        </div>

        @yield('content')

        <div class="auth-footer">
            {{-- No contact page exists yet, so this stays plain text. --}}
            <div>Belum punya akses? <span style="color: var(--auth-link);">Hubungi Admin Utama</span></div>
            <div class="auth-copyright">&copy; {{ date('Y') }} SmartTrip Batam. All rights reserved.</div>
        </div>
    </main>

    <script>
        document.querySelectorAll('[data-toggle-password]').forEach(function (button) {
            button.addEventListener('click', function () {
                var input = document.getElementById(button.dataset.togglePassword);
                var show = input.type === 'password';
                input.type = show ? 'text' : 'password';
                button.querySelector('.bi').className = show ? 'bi bi-eye-slash' : 'bi bi-eye';
                button.setAttribute('aria-label', show ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi');
            });
        });
    </script>
</body>
</html>
