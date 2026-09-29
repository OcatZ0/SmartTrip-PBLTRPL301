<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/SmartTrips_white_logo.png">
    <source media="(prefers-color-scheme: light)" srcset="docs/assets/SmartTrips_logo.png">
    <img alt="SmartTrip Batam logo" src="docs/assets/SmartTrips_logo.png" width="140">
  </picture>

  # SmartTrip Batam

  **Sistem rekomendasi itinerary liburan Batam berbasis preferensi pengguna**

  College project - PBL TRPL 301
</div>

---

## About

Wisatawan Batam sering kesulitan menentukan destinasi wisata dan kuliner yang sesuai dengan minat, lokasi, waktu, dan anggaran mereka karena informasinya tersebar di banyak platform. SmartTrip Batam menyusunkan itinerary multi-hari secara otomatis: pengguna memilih minat dan bobot preferensi (kategori, jarak, anggaran, rating), lalu sistem merekomendasikan tempat wisata/kuliner/hotel yang paling sesuai dan menyusun rutenya sendiri per hari.

**Pipeline rekomendasi:** Weighted-TOPSIS (skoring tempat per 4 kriteria) → K-Means (pengelompokan tempat per hari) → Nearest-Neighbor (urutan rute per hari) → Google Routes API (jalur jalan asli per segmen).

## Key Features

- **Rekomendasi personalisasi** - 4 kriteria TOPSIS: kesesuaian kategori/minat (Jaccard similarity), jarak (Haversine), anggaran (fallback bertingkat), dan rating (blend Bayesian Google + in-app)
- **Live trip map** - progres kunjungan otomatis lewat GPS geofencing, dengan fallback tandai manual
- **Peringatan cuaca** - saran swap otomatis untuk stop outdoor kalau forecast menunjukkan hujan
- **Data tempat terkurasi** - bersumber murni dari Google Places API (New) lewat pipeline Discovery/Enrichment dua fase yang direview admin, tanpa scraping platform lain
- **AI enrichment** - Gemini API untuk translasi otomatis, tagging kategori, estimasi durasi kunjungan, dan deteksi tempat outdoor
- **Admin panel web** - kurasi data tempat, review kandidat Discovery, kelola kategori, dengan audit trail perubahan (`spatie/laravel-activitylog`)
- **Wishlist & custom pin** - tambah tempat favorit dari katalog atau tap pin manual di peta

## Tech Stack

| Layer | Choice |
|---|---|
| Backend | Laravel 12 (PHP), REST API |
| Mobile | Flutter (Riverpod) |
| Admin Panel | Laravel Blade + Bootstrap (session auth, separate from mobile API) |
| Database | PostgreSQL |
| Auth | Laravel Sanctum (API tokens) + Google Sign-In |
| Maps & Routing | Google Maps SDK, Google Routes API |
| Place Data | Google Places API (New) |
| AI Enrichment | Gemini API (Flash/Flash-Lite) |
| Weather | Open-Meteo |
| Notifications | `flutter_local_notifications` (fully client-side) |
| Hosting | Linux server |

## Documentation

| Document | Description |
|---|---|
| [Design Spec](docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md) | Full technical design - data model, algorithm, API, architecture (source of truth) |
| [PRD](docs/prd/2026-09-07-smarttrip-prd.md) | Product requirements, user stories, acceptance criteria |
| [Page/Screen Inventory](docs/mockup/2026-09-11-smarttrip-page-inventory.md) | Full mobile + admin screen inventory for mockup reference |

## Project Structure

```
SmartTrip-PBLTRPL301/
├── docs/                   # Design spec, PRD, mockup inventory, assets
├── smarttrip-api/          # Laravel 12 backend - REST API (mobile) + admin web panel
│   ├── app/Http/Controllers/Api/     # Auth, Trip, Place controllers - routes/api.php
│   ├── app/Http/Controllers/Admin/   # Dashboard, auth - routes/web.php, session guard
│   ├── app/Services/                 # TOPSIS/K-Means/route assembly (not yet implemented)
│   ├── resources/views/admin/        # Blade + Bootstrap admin panel
│   └── database/migrations/          # users.role/google_id, personal_access_tokens, activity_log
└── smarttrip-mobile/       # Flutter mobile app (scaffolded, org com.smarttrip.batam)
    ├── lib/
    │   ├── core/           # api client, auth token storage, config, router, theme
    │   ├── features/       # onboarding, catalog, trip_setup, wishlist, itinerary,
    │   │                   # live_map, reviews, profile, trip_sharing, auth
    │   ├── app.dart
    │   └── main.dart
    └── test/
```

Run the backend:
```
cd smarttrip-api
composer install
cp .env.example .env   # fill in DB credentials + Google/Gemini API keys
php artisan key:generate
php artisan migrate --seed
php artisan serve
```
Seeded accounts: `admin@smarttrip.test` (role `admin`, admin panel at `/admin/login`) and `test@example.com` (regular user) - both created by `Database\Factories\UserFactory` with a random password, so set one via `php artisan tinker` or re-seed with a known password before relying on them.

Run the mobile app:
```
cd smarttrip-mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Status

Design spec and PRD are finalized. Both `smarttrip-api` (Laravel 12 + PostgreSQL, Sanctum auth, register/login/logout wired to F001-F003, admin session-auth scaffold) and `smarttrip-mobile` (Flutter, Riverpod + go_router wiring) have been scaffolded, but most feature screens/endpoints (trip generation, TOPSIS/K-Means pipeline, wishlist, live map, admin curation) are not yet implemented - see Section 10 of the PRD for the full data model still to be migrated.

**Planned phases** *(illustrative, not yet tied to real semester dates)*:
1. Backend scaffolding, data model migrations, Google Places bootstrap
2. Core algorithm (TOPSIS/K-Means/NN) + unit tests, Flutter trip-setup/wishlist/generate flow
3. Live map + geofencing, swap, admin web panel, AI enrichment pipeline
4. Profile preferences, Google Sign-In, bilingual support, reviews, polish + testing

## Team

1-semester project for course TRPL 301.

| NIM | Name | Role |
|---|---|---|
| 4342501028 | Muhamad Nurfadli | Team Leader |
| 4342501003 | Fathia Zahra Salsabila | Member |
| 4342501014 | Atma Fauzilla | Member |
| 4342501010 | Zahrah Faradila | Member |
| 4342501025 | Muhammad Rangga | Member |
