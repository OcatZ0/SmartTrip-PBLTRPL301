<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Atur Ulang Kata Sandi - SmartTrip</title>
    <link rel="icon" href="{{ asset('images/logo.svg') }}" type="image/svg+xml">
    <link rel="icon" href="{{ asset('images/logo.png') }}" type="image/png">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
</head>
<body style="font-family: sans-serif; text-align: center; padding-top: 4rem;">
    <h1>{{ $success ? 'Kata Sandi Berhasil Diubah' : 'Gagal Mengatur Ulang Kata Sandi' }}</h1>
    <p>{{ $message }}</p>
</body>
</html>
