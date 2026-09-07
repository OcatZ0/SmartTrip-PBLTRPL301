# SmartTrip Batam - Sistem Rekomendasi Itinerary Design

Date: 2026-09-07
Team: 6 orang, 1 semester
Deliverable: Aplikasi (Laravel REST API + Flutter mobile). Laporan akademik di luar scope dokumen ini.

## 1. Problem Statement

Wisatawan Batam kesulitan menentukan destinasi wisata/kuliner yang cocok dengan minat, lokasi, waktu, dan anggaran mereka, serta menyusun rute perjalanan yang efisien. SmartTrip membantu user menemukan tempat yang sesuai preferensi dan menyusun jadwal perjalanan (itinerary) otomatis.

## 2. Architecture Overview

**Backend: Laravel, REST API only, JWT auth (Sanctum).**

- `places` sync module - Artisan command (`php artisan places:sync`), dijalankan manual (admin trigger) atau terjadwal ringan (bulanan), menarik data tempat wisata/kuliner/hotel Batam dari Google Places API (New) ke tabel `places` lokal. Upsert idempotent berdasarkan `google_place_id`.
- `recommendation` module - hitung bobot kriteria dari input slider user, scoring TOPSIS terhadap kandidat tempat, clustering K-Means untuk pembagian hari, nearest-neighbor routing per hari.
- `itinerary` module - simpan itinerary (hanya untuk user yang login), swap item, tracking source (wishlist vs recommended).
- `admin` module - CRUD atribut custom tempat, manajemen kriteria, trigger sync manual, dashboard analitik dari data review in-app.

**Mobile: Flutter.**

- Alur pakai tanpa login (guest) sampai user memilih simpan trip.
- Semua komunikasi ke backend lewat REST/JWT. Tidak ada panggilan langsung ke Google API dari mobile (API key tetap di server) - kecuali `google_maps_flutter` (render peta) dan `geolocator` (lokasi GPS device), yang keduanya tidak butuh API key berbayar/panggilan server sama sekali.

**Kenapa split begini:** panggilan Google Places (yang berbayar/quota-limited) selalu lewat server dan batched, bukan per user mobile. Scoring TOPSIS juga selalu terhadap data lokal, jadi cepat dan tidak bergantung latency API eksternal.

## 3. Feasibility Check (Google Places API, Maps SDK, Routes API)

- **Field coverage:** cukup. Google Places API (New) punya `displayName`, `location` (lat/lng), `types`/`primaryType` (attraction/restaurant subtypes/lodging), `rating`, `userRatingCount`, `priceLevel`, `regularOpeningHours`/`currentOpeningHours`, `photos`.
- **Pricing (Places):** kredit blanket $200/bulan sudah tidak berlaku (expired Feb 2025). Model sekarang: free calls per SKU per bulan - Nearby/Text Search (Pro SKU) 5.000 panggilan gratis/bulan, Place Details dengan field rating+jam buka+harga (Enterprise SKU) hanya **1.000 panggilan gratis/bulan**.
- **Implikasi:** batasi jumlah tempat awal (~300-500 tempat lintas kategori attraction/culinary/lodging di Batam) supaya full sync awal tetap dalam kuota gratis. Sync tetap manual/admin-triggered (tombol "sync now"), bukan cron agresif harian, supaya tidak boros kuota Enterprise. Akun Google Cloud baru juga dapat trial credit $300 sekali pakai yang cukup menutupi testing satu semester.
- **Peta & rute jalan (kenapa Google, bukan TomTom):** Maps SDK for Android/iOS (dipakai lewat `google_maps_flutter`) gratis tanpa batas untuk render peta - jadi tidak ada biaya tambahan buat nampilin peta itu sendiri. Rute jalan asli (turn-by-turn, ngikutin jalan) pakai Google Routes API (`computeRoutes`), masuk tier Essentials dengan 10.000 panggilan gratis/bulan - jauh lebih dari cukup karena API ini cuma dipanggil sekali per hari-itinerary saat generate atau swap (bukan per view). TomTom punya free tier lebih besar (2.500 req/hari) tapi tidak ada Flutter SDK resmi, jadi butuh effort tambahan buat integrasi tile peta sendiri tanpa manfaat jelas dibanding Google yang sudah gratis. Lokasi user saat ini tidak butuh API sama sekali - cukup `geolocator` (akses GPS device langsung).
- **Catatan operasional:** Google Maps Platform tetap butuh billing account (kartu kredit) aktif walau memakai kuota gratis - perlu disiapkan salah satu anggota tim.

## 4. Data Model

- **`places`** - id, google_place_id (nullable, unique), name, type (`attraction`/`culinary`/`lodging`), lat, lng, address, price_level, rating (dari Google), review_count, opening_hours (json), photo_url, source (`google`/`manual`), timestamps
- **`place_attributes`** - place_id FK, category_tags (json), estimated_visit_minutes, budget_tier override admin. Dipisah dari `places` supaya re-sync dari Google tidak menimpa data custom admin.
- **`place_reviews`** - place_id FK, user_id FK, rating (1-5), comment (nullable), itinerary_item_id FK (nullable, pembeda review "setelah kunjungan via app" vs review umum), timestamps
- **`users`** - standar Laravel auth
- **`trips`** - user_id (nullable sampai disimpan), title, num_days, budget_total, has_own_hotel (bool), hotel_place_id (FK nullable), start_date, daily_start_time (default 09:00), daily_end_time (default 19:00)
- **`trip_wishlist_places`** - trip_id FK, place_id FK (nullable - kalau custom pin di luar database, simpan name+lat+lng langsung)
- **`trip_criteria_weights`** - trip_id FK, criterion, weight (hasil normalisasi slider, disimpan supaya swap/regenerate pakai bobot yang sama)
- **`itinerary_days`** - trip_id FK, day_number, start_place_id, end_place_id (biasanya = hotel di kedua ujung), route_polyline (text, encoded polyline dari Google Routes API - dihitung sekali saat generate/swap, bukan tiap kali itinerary dibuka)
- **`itinerary_items`** - itinerary_day_id FK, place_id FK, visit_order, topsis_score (snapshot saat generate), source (`wishlist`/`recommended`)

## 5. Rating Blend (Google + In-App)

Rating in-app dipakai buat blend dengan rating Google di kriteria TOPSIS, bukan cuma data analitik pasif. Supaya tempat baru dengan 1 review 5 bintang tidak mengalahkan tempat dengan 2.000 review asli, dipakai Bayesian-average blend (mirip formula rating IMDB): rata-rata in-app menarik bobot makin besar seiring bertambahnya jumlah review in-app, tapi hampir sepenuhnya mengikuti rating Google kalau review in-app masih sedikit/nol (menghindari cold-start problem).

## 6. Recommendation Engine Flow

1. **Trip setup (mobile):** num_days, budget_total, start_date, daily_start_time/daily_end_time (optional, default 09:00-19:00), toggle "sudah punya hotel?".
2. **Wishlist (mobile, opsional):** user browse/scroll katalog tempat (seperti e-commerce - grid/list, filter kategori, infinite scroll via pagination) dan tambah ke wishlist. Ini terjadi sebelum tahap generate.
3. **Bobot kriteria (mobile):** user isi 4 slider (0-10): kesesuaian kategori/minat, jarak/lokasi, kesesuaian anggaran, rating/popularitas. Backend normalisasi: `weight_i = rating_i / sum(semua rating)`.
4. **Hotel (backend):** kalau tidak punya hotel sendiri, jalankan TOPSIS 3-kriteria (jarak ke area wisata terpilih, kesesuaian anggaran, rating) khusus `type=lodging`, tampilkan top-3 buat dipilih user. Kalau sudah punya hotel, lewati langkah ini - lokasi yang diinput user jadi titik awal/akhir.
5. **Scoring kandidat (backend):** filter `attraction`/`culinary` berdasarkan kategori + kompatibilitas jam buka terhadap daily_start_time/daily_end_time, bangun matriks keputusan TOPSIS (baris = kandidat tempat, kolom = 4 kriteria dengan bobot dari langkah 3), hitung closeness-to-ideal score.
6. **Pembagian hari (backend):**
   a. K-Means clustering (k = num_days) atas koordinat tempat wishlist, supaya wishlist yang lokasinya berjauhan tidak masuk hari yang sama.
   b. Kalau total estimated_visit_minutes wishlist di satu cluster hari melebihi budget waktu hari itu, item overflow (prioritas terendah - terjauh dari centroid cluster) otomatis didorong (push) ke hari berikutnya, cascading kalau perlu. Kalau tetap tidak muat sampai hari terakhir, hari itu dikembalikan dengan flag "tidak muat".
   c. Slot kosong tiap hari diisi tempat rekomendasi TOPSIS terdekat dari centroid cluster hari itu (atau dari hotel kalau hari itu tidak ada wishlist).
   d. Nearest-neighbor (Haversine) dijalankan per hari (wishlist + recommended digabung) mulai dan berakhir di hotel/titik awal, untuk menentukan urutan kunjungan.
   e. Setelah urutan per hari fix, backend panggil Google Routes API (`computeRoutes`) sekali per hari dengan urutan stop tsb, simpan encoded polyline hasilnya ke `itinerary_days.route_polyline`.
7. **Swap (backend):** ganti satu item - ambil alternatif TOPSIS peringkat berikutnya yang belum dipakai (kategori & radius hari yang sama), atau user cari manual lewat browse/search penuh. Setelah swap, urutan NN dihitung ulang untuk hari itu (langkah 6d) dan `route_polyline` di-refresh (langkah 6e) - hari lain tidak terpengaruh.

Pipeline: **K-Means (pembagian hari)** -> **Weighted-TOPSIS (ranking kandidat)** -> **Nearest-Neighbor (urutan rute)** -> **Routes API (polyline jalan asli)**.

## 7. API Endpoints

```
Auth
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout                          (auth)

Trip setup
POST   /api/trips                                 - create trip (guest-allowed)
                                                      body: num_days, budget_total, start_date,
                                                      daily_start_time?, daily_end_time?, has_own_hotel
GET    /api/trips/{id}                             - trip detail (+ itinerary + route_polyline per hari setelah generate)
POST   /api/trips/{id}/hotel                       - set hotel pilihan/sendiri sebagai titik awal/akhir
GET    /api/trips/{id}/hotel-options                - top-3 hotel ranking TOPSIS (skip kalau has_own_hotel)

Wishlist
POST   /api/trips/{id}/wishlist                    - tambah wishlist (place_id, atau custom name+lat+lng)
GET    /api/trips/{id}/wishlist                     - list wishlist
DELETE /api/trips/{id}/wishlist/{wishlist_id}       - hapus item wishlist

Bobot & generate
POST   /api/trips/{id}/weights                     - submit 4 slider rating -> bobot ternormalisasi
POST   /api/trips/{id}/generate                     - jalankan K-Means + TOPSIS + Nearest-Neighbor -> itinerary
POST   /api/trips/{id}/save                         - attach guest trip ke user login          (auth)
GET    /api/trips                                   - list trip tersimpan                       (auth)

Swap
GET    /api/itinerary-items/{id}/swap-candidates     - alternatif ranking (mode=ranked)
GET    /api/places?search=&category=&near_itinerary_day={day_id}   - "cari lainnya" manual
PATCH  /api/itinerary-items/{id}                     - commit swap {place_id}, re-run NN hari itu

Places & review
GET    /api/places                                  - browse/search umum (katalog wishlist)
GET    /api/places/{id}                              - detail tempat
POST   /api/places/{id}/reviews                      - submit rating/review in-app             (auth)

Admin                                                (auth + role admin)
GET/POST/PATCH  /api/admin/places
GET/POST/PATCH  /api/admin/place-attributes
GET/POST/PATCH  /api/admin/criteria
POST            /api/admin/places/sync               - trigger sync Google Places manual
GET             /api/admin/places/sync-status
GET             /api/admin/analytics                 - tempat terfavorit, rata-rata rating, volume trip
```

Guest trip dilacak lewat signed trip token (bukan session user), supaya guest bisa kembali ke trip yang sama sebelum memutuskan simpan/login.

## 8. Mobile App Flow (Flutter)

1. Home -> "Buat Trip" (tanpa login)
2. Trip setup: num_days, budget_total, start_date, daily start/end time (opsional, default ditampilkan), toggle "sudah punya hotel?"
3. Wishlist (opsional): katalog tempat gaya e-commerce (grid/list, filter kategori, infinite scroll) dengan tombol "+ wishlist" per kartu
4. Slider preferensi: 4 kriteria, 0-10
5. Kalau belum punya hotel: tampilkan top-3 pilihan hotel
6. Loading -> hasil itinerary: kartu per hari, tiap tempat ada badge source (wishlist/recommended), peta per hari (`google_maps_flutter`) menampilkan pin bernomor sesuai urutan kunjungan + polyline rute jalan asli (decode dari `route_polyline`) + marker lokasi user saat ini (dari `geolocator`, kalau permission diizinkan)
7. Menu "..." per item -> swap (alternatif ranking atau cari manual)
8. "Simpan trip" -> minta login/register kalau masih guest, lalu simpan
9. List trip tersimpan (auth) -> buka lagi, edit, generate ulang, tambah review in-app setelah kunjungan

## 9. Admin Panel Scope (web, Blade)

- CRUD Places (lihat data hasil sync Google, edit atribut custom, tambah manual tempat yang tidak ada di Google)
- Trigger "sync now" manual + status sync terakhir
- Manajemen tag kategori/kriteria
- Dashboard analitik dasar (tempat paling di-wishlist, rata-rata rating in-app, volume trip) - di sinilah data review in-app dipakai

## 10. Testing Approach

- Backend: unit test untuk bagian matematis murni (normalisasi bobot, scoring TOPSIS, Haversine, K-Means clustering, blend rating Bayesian) karena deterministik dan gampang diverifikasi terhadap input yang sudah diketahui hasilnya - bagian ini juga paling penting untuk dipertanggungjawabkan metodenya.
- Feature test untuk endpoint API (alur create trip -> generate -> swap).
- Flutter: widget test untuk layar input slider/wishlist, QA manual untuk alur penuh (output auto-generate tidak praktis untuk diasersi persis lewat widget test).

## 11. Out of Scope (semester ini)

- Laporan akademik (di luar dokumen ini per instruksi user)
- Scraping platform lain (TripAdvisor/Traveloka/Tiket.com) - hanya Google Places sebagai sumber data eksternal
- True AHP pairwise comparison - dipakai direct-rating slider yang lebih simpel untuk UX mobile
- Kolaborasi/sharing itinerary antar user
