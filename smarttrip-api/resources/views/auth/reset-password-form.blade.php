<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Atur Ulang Kata Sandi - SmartTrip Batam</title>
</head>
<body style="font-family: sans-serif; max-width: 360px; margin: 4rem auto;">
    <h1>Atur Ulang Kata Sandi</h1>

    @if ($errors->any())
        <div style="color: #b00020;">
            <ul>
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form method="POST" action="{{ route('auth.reset-password.submit') }}">
        @csrf
        <input type="hidden" name="email" value="{{ $email }}">
        <input type="hidden" name="token" value="{{ $token }}">

        <div style="margin-bottom: 1rem;">
            <label for="password">Kata Sandi Baru</label><br>
            <input type="password" id="password" name="password" required minlength="8" style="width: 100%;">
        </div>
        <div style="margin-bottom: 1rem;">
            <label for="password_confirmation">Konfirmasi Kata Sandi</label><br>
            <input type="password" id="password_confirmation" name="password_confirmation" required minlength="8" style="width: 100%;">
        </div>
        <button type="submit" style="width: 100%;">Simpan Kata Sandi Baru</button>
    </form>
</body>
</html>
