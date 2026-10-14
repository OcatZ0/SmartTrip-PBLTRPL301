# Introduction

REST API untuk aplikasi mobile SmartTrip (Flutter) - autentikasi, katalog tempat, wishlist, generate itinerary otomatis, swap, live tracking, review, dan share trip.

<aside>
    <strong>Base URL</strong>: <code>http://localhost:8000</code>
</aside>

    Dokumentasi ini mencakup seluruh endpoint `/api/*` yang dikonsumsi mobile app SmartTrip lewat Laravel Sanctum bearer token.

    Panel admin (`/admin/*`, session auth `guard:web`, Laravel Blade + Bootstrap) sengaja **tidak** termasuk di sini - itu bukan REST API, cuma HTML form biasa buat kurasi data.

    <aside>Klik endpoint mana pun di sebelah kiri untuk lihat detail parameter, contoh request, dan contoh response.</aside>

