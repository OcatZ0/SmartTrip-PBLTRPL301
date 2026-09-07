# SmartTrip Batam - Sistem Rekomendasi Itinerary Design

Date: 2026-09-07
Team: 6 orang, 1 semester
Deliverable: Aplikasi (Laravel REST API + Flutter mobile). Laporan akademik di luar scope dokumen ini.

## 1. Problem Statement

Wisatawan Batam kesulitan menentukan destinasi wisata/kuliner yang cocok dengan minat, lokasi, waktu, dan anggaran mereka, serta menyusun rute perjalanan yang efisien. SmartTrip membantu user menemukan tempat yang sesuai preferensi dan menyusun jadwal perjalanan (itinerary) otomatis.

## 2. Architecture Overview

**Backend: Laravel, REST API only, auth via Laravel Sanctum (API token mode - opaque bearer token, bukan JWT; dipilih karena first-party, gampang di-revoke, cukup buat skala project ini). Dua cara masuk: email/password, atau Google Sign-In - keduanya berakhir dengan Sanctum token yang sama, cuma beda cara verifikasi identitas awal.**

- `places` sync module - Artisan command (`php artisan places:sync`), dijalankan manual (admin trigger) atau terjadwal ringan (bulanan), menarik data tempat wisata/kuliner/hotel Batam dari Google Places API (New) ke tabel `places` lokal. Upsert idempotent berdasarkan `google_place_id`.
- `recommendation` module - hitung bobot kriteria dari input slider user, scoring TOPSIS terhadap kandidat tempat, clustering K-Means untuk pembagian hari, nearest-neighbor routing per hari.
- `itinerary` module - simpan itinerary (hanya untuk user yang login), swap item, tracking source (wishlist vs recommended).
- `admin` module - CRUD places/place_attributes, CRUD categories, review place_candidates (discovery/approve/reject), dashboard analitik - semua lewat endpoint `/api/admin/*` yang sama, dikonsumsi Flutter role-gated (Section 11), bukan Blade.

**Mobile: Flutter - satu app buat semua (user biasa & admin), tidak ada web admin panel sama sekali.**

- **Role-gated, bukan app terpisah:** admin login di app Flutter yang sama persis. Begitu `users.role = admin` kedeteksi setelah login, muncul tab/menu tambahan (review candidate tempat, CRUD places/categories, dashboard analitik - lihat Section 11) di atas alur user biasa yang tetap sama. Satu codebase, satu app di HP siapapun - bukan dua project Flutter terpisah.
- **Login/register wajib sebelum bisa bikin trip** - tidak ada alur guest lagi (diputuskan ulang, disederhanakan dari desain awal). Browse katalog tempat (`GET /api/places`) tetap bisa tanpa login, tapi begitu masuk ke "Buat Trip" langsung diarahkan ke login/register kalau belum. Ini menghilangkan kebutuhan guest trip token, endpoint "save/attach trip", dan logic auth kondisional - trip selalu langsung terikat ke `user_id` sejak dibuat.
- Semua komunikasi ke backend lewat REST + Sanctum bearer token. Tidak ada panggilan langsung ke Google API dari mobile (API key tetap di server) - kecuali `google_maps_flutter` (render peta) dan `geolocator` (lokasi GPS device), yang keduanya tidak butuh API key berbayar/panggilan server sama sekali.
- Foto tempat **tidak** di-hotlink langsung ke Google - Google Places Photo (New) butuh API key di URL buat ambil bytes gambar, jadi kalau mobile fetch langsung, key ke-expose ke client. Sync menyimpan foto ke storage lokal server (sesuai konvensi tim: file disimpan lokal, bukan cloud storage), `photo_url`/`place_photos.photo_url` menunjuk ke path server sendiri.
- UI bilingual (ID/EN) lewat Flutter i18n standar (`easy_localization` atau `intl` bawaan) - murni client-side, tidak ada endpoint tambahan.
- Notifikasi (reminder mulai hari, notif mendekati stop berikutnya) pakai `flutter_local_notifications` - **dijadwalkan/dipicu murni di device**, bukan push server. Reminder mulai hari dijadwalkan client-side begitu itinerary di-generate (pakai `daily_start_time` + tanggal hari itu); notif mendekati stop numpang di event geofence entry yang sama dengan visit-tracking (Section 8). Tidak butuh Firebase Cloud Messaging atau endpoint backend baru.

**Kenapa split begini:** panggilan Google Places (yang berbayar/quota-limited) selalu lewat server dan batched, bukan per user mobile. Scoring TOPSIS juga selalu terhadap data lokal, jadi cepat dan tidak bergantung latency API eksternal.

## 3. Feasibility Check (Google Places API, Maps SDK, Routes API)

- **Field coverage:** cukup. Google Places API (New) punya `displayName`, `location` (lat/lng), `types`/`primaryType` (attraction/restaurant subtypes/lodging), `rating`, `userRatingCount`, `priceLevel`, `regularOpeningHours`/`currentOpeningHours`, `photos`.
- **Pricing (Places):** kredit blanket $200/bulan sudah tidak berlaku (expired Feb 2025). Model sekarang: free calls per SKU per bulan - Nearby/Text Search (Pro SKU) 5.000 panggilan gratis/bulan, Place Details dengan field rating+jam buka+harga (Enterprise SKU) hanya **1.000 panggilan gratis/bulan**.
- **Implikasi:** batasi jumlah tempat awal (~300-500 tempat lintas kategori attraction/culinary/lodging di Batam) supaya full sync awal tetap dalam kuota gratis. Sync tetap manual/admin-triggered (tombol "sync now"), bukan cron agresif harian, supaya tidak boros kuota Enterprise. Akun Google Cloud baru juga dapat trial credit $300 sekali pakai yang cukup menutupi testing satu semester.
- **Peta & rute jalan (kenapa Google, bukan TomTom):** Maps SDK for Android/iOS (dipakai lewat `google_maps_flutter`) gratis tanpa batas untuk render peta - jadi tidak ada biaya tambahan buat nampilin peta itu sendiri. Rute jalan asli (turn-by-turn, ngikutin jalan) pakai Google Routes API (`computeRoutes`), masuk tier Essentials dengan 10.000 panggilan gratis/bulan - jauh lebih dari cukup karena API ini cuma dipanggil sekali per hari-itinerary saat generate atau swap (bukan per view). TomTom punya free tier lebih besar (2.500 req/hari) tapi tidak ada Flutter SDK resmi, jadi butuh effort tambahan buat integrasi tile peta sendiri tanpa manfaat jelas dibanding Google yang sudah gratis. Lokasi user saat ini tidak butuh API sama sekali - cukup `geolocator` (akses GPS device langsung).
- **Catatan operasional:** Google Maps Platform tetap butuh billing account (kartu kredit) aktif walau memakai kuota gratis - perlu disiapkan salah satu anggota tim.
- **Urutan bootstrap - `categories` diseed duluan:** tagging AI (langkah 4 di bawah) cuma boleh pilih dari `categories` yang sudah ada (Section 5) - kalau tabelnya masih kosong, tidak ada yang bisa disarankan. Jadi urutannya: seed `categories` dengan taksonomi awal (~10-15 tag baku via Laravel seeder, admin bisa tambah/edit belakangan) **sebelum** proses places bootstrap di bawah dijalankan.
- **Bootstrap data awal - kenapa tidak cukup 1 kali panggil sync:** Nearby/Text Search cuma balikin maks 20 hasil per call (60 dengan pagination), walau radius di-set sampai 50km - jadi 1 search tidak akan pernah nyampe 300-500 tempat, cuma dapat "yang paling menonjol" berulang-ulang. Solusinya sync jalan dalam **2 fase**:
  1. **Discovery (murah, Pro SKU):** jalankan Nearby/Text Search per kombinasi area x kategori (misal per kecamatan di Batam x attraction/culinary/lodging, sekitar belasan area x 3 kategori) - hasilnya (name, lokasi, tipe dasar, google_place_id) masuk tabel staging `place_candidates`, BUKAN langsung ke `places`. Fase ini murah karena cuma butuh field dasar (Pro SKU), tidak menyentuh kuota Enterprise yang ketat. **1 kali trigger sudah loop semua kombinasi area x kategori** - bukan 1 API call, tapi 1 operasi bootstrap yang cukup buat nyampe target awal (~300-500 tempat) sekali jalan, dengan asumsi Batam memang punya sebanyak itu tempat.
  1a. **Idempotensi - kenapa re-trigger Discovery tidak dobel data:** admin bisa trigger Discovery lagi kapan saja (nambah area baru, atau cek tempat baru yang muncul di Google belakangan) - tiap `google_place_id` hasil pencarian dicek dulu terhadap **`places` DAN `place_candidates` (status apapun, termasuk `rejected`)** sebelum di-insert. Kalau sudah ada di salah satu (baik sudah jadi place resmi, masih pending, atau sudah pernah ditolak), dilewati - tidak insert ulang. Ini penting khusus buat status `rejected`: tanpa cek ini, tempat yang sudah sengaja ditolak admin bakal terus muncul lagi tiap kali Discovery di-re-run, bikin review jadi berulang-ulang buat hal yang sama.
  2. **Review admin:** panel nampilin daftar candidate hasil discovery (bisa ratusan/ribuan, termasuk noise kayak warung kecil yang ke-tag "restaurant"), admin pilih/approve mana yang layak jadi `places` beneran.
  3. **Enrichment (mahal, Enterprise SKU, cuma buat yang di-approve):** candidate yang di-approve baru di-fetch Place Details lengkap (rating, jam buka, harga, foto, deskripsi) dan dipromosikan ke `places` - di sinilah kuota 1.000/bulan kepake, jadi dijaga cuma buat tempat yang beneran lolos review, bukan semua hasil discovery mentah.
  4. **Tagging (langsung nyambung ke akhir Enrichment):** begitu `description` tersimpan dari Place Details, satu call Gemini (Section 5) langsung jalan buat tempat itu - hasilnya `description_en` (auto-translate) dan `category_tags` (disarankan dari daftar `categories` yang ada, `category_tags_reviewed = false`). Jadi tiap tempat yang lolos approve otomatis lengkap (foto, deskripsi 2 bahasa, tag kategori) tanpa langkah manual terpisah - tag-nya cuma nunggu direview admin (sudah bisa dipakai algoritma dari awal, lihat Section 5).
  5. Proses ini dijalankan sekali di awal buat isi data awal (~300-500 tempat), lalu admin bisa ulang discovery kapan saja buat nambah area/kategori baru.
- **Bilingual & kuota:** sync dari Google cuma sekali per tempat dalam satu bahasa (Indonesia) - fetch ulang dalam Bahasa Inggris buat tiap tempat akan menggandakan pemakaian kuota Enterprise (sudah ketat di 1.000/bulan). Konten Inggris (`description_en`) **bukan** ditulis manual oleh admin - begitu `description` (ID) tersedia (dari Google atau admin override), backend auto-translate ke Inggris pakai Gemini API (lihat Section 5 - satu provider AI buat translasi & tagging kategori sekaligus). Hasil auto-translate tetap disimpan sebagai field yang bisa di-override admin kalau hasilnya kurang pas, bukan dikunci permanen.
- **Kenapa Gemini buat fitur AI (translasi & tagging kategori):** Gemini API (model Flash/Flash-Lite) benar-benar gratis terus-menerus tanpa kartu kredit, cuma dibatasi rate limit (5-15 request/menit, sampai 1.000 request/hari) - beda dari OpenAI/Claude yang cuma kasih kredit trial sekali pakai (~$5, ada masa berlaku) baru bayar per-token setelahnya. Cocok banget buat kebutuhan proyek kuliah yang volume-nya kecil (300-500 tempat) tapi butuh AI yang genuinely gratis jangka panjang.

## 4. Data Model

- **`places`** - id, google_place_id (nullable, unique), name, type (`attraction`/`culinary`/`lodging`), lat, lng, address, price_level (raw Google tier, nullable - lihat catatan anggaran di Section 7), rating (dari Google), review_count, opening_hours (json), photo_url (thumbnail utama, path lokal server - lihat Section 2), description (nullable, dari Google `editorialSummary`, Bahasa Indonesia - tidak semua tempat punya), phone (nullable), website (nullable), google_maps_uri (nullable - buat tombol "Buka di Google Maps" navigasi asli, terpisah dari route view in-app), business_status (`operational`/`closed_temporarily`/`closed_permanently`, default `operational` - sync mengecualikan yang `closed_permanently` dari rekomendasi), types (json, raw Google types array buat label kategori lebih detail di layar), source (`google`/`manual`), timestamps
- **`place_attributes`** - place_id FK, category_tags (json array of `categories.id`, diisi AI lalu admin-editable - lihat Section 5), category_tags_reviewed (bool, default false - ditandai true begitu admin cek hasil tagging AI), estimated_visit_minutes (diisi AI - Gemini nebak durasi kunjungan wajar berdasar tipe/kategori tempat, misal museum ~90 menit, cafe ~45 menit - bagian dari call enrichment yang sama di Section 5, admin bisa override), estimated_cost_idr (nullable, admin manual - prioritas utama buat kriteria anggaran, lihat Section 7), description_override (nullable, Bahasa Indonesia), description_en (nullable, auto-translate via Gemini API saat data ID tersimpan, admin bisa override hasilnya - fallback ke `description`/`description_override` kalau tetap kosong saat UI dalam mode EN). Dipisah dari `places` supaya re-sync dari Google tidak menimpa data custom admin.
- **`categories`** - id, name_id, name_en, slug (unique - jaga konsistensi, cegah duplikat mirip kayak "kuliner" vs "wisata kuliner"), timestamps. Admin-manageable lewat panel (CRUD), bukan hardcode.
- **`place_candidates`** - google_place_id (unique), name, type (dugaan awal dari Google types), lat, lng, search_area (kecamatan/area asal discovery, buat filter di panel review), status (`pending`/`approved`/`rejected`, default `pending`), timestamps. Staging area hasil fase Discovery (Section 3) - cuma field dasar/murah, belum ada rating/jam buka/harga. Baris yang `approved` dipromosikan (fetch Place Details lengkap) jadi baris baru di `places`, lalu row candidate-nya bisa dihapus/diarsipkan.
- **`place_photos`** - place_id FK, photo_url (path lokal server), sort_order. Diisi dari Google `photos[]` saat sync (cap ~5 foto per tempat, download bytes-nya lewat server bukan disimpan sebagai link Google), dipakai buat carousel di detail screen.
- **`place_reviews`** - place_id FK, user_id FK, rating (1-5), comment (nullable), itinerary_item_id FK (nullable), timestamps. **Review terbuka** - siapa saja bisa review tempat manapun kapan saja dari halaman detail tempat, tidak perlu bukti kunjungan (Section 6 butuh volume review biar Bayesian blend berguna, bukan cuma dekorasi). `itinerary_item_id` cuma keisi kalau review disubmit dari flow "beri rating" pasca-kunjungan di dalam trip - review umum dari halaman detail tempat null di field ini.
- **`users`** - standar Laravel auth (password nullable - akun Google-only tidak punya password) + google_id (nullable, unique) + role (`user`/`admin`, default `user`), default_interest_category_ids (json array of `categories.id`, nullable - preferensi minat default, diedit dari layar Profil). **Urutan lookup di `POST /api/auth/google`:** (1) cari by `google_id` - kalau ada, itu user-nya. (2) Kalau tidak ada, cari by `email` dari token Google - kalau ketemu (user ini sebelumnya daftar pakai password), **link** `google_id` ke akun itu, bukan bikin akun baru (supaya 1 email = 1 akun, tidak dobel). (3) Kalau email juga tidak ketemu, baru buat user baru.
- **`user_criteria_weights`** - user_id FK, criterion, weight (default bobot 4 kriteria, sama struktur kayak `trip_criteria_weights` tapi di level akun bukan per-trip). Baris ini **cuma dipakai buat pre-fill** langkah "Pilih minat + slider" (Section 10) saat bikin trip baru - trip yang sudah digenerate tetap pakai snapshot `trips.interest_category_ids`/`trip_criteria_weights` sendiri, tidak berubah walau default di profil diedit belakangan. Kosong/nullable sampai user pertama kali isi (baik lewat layar Profil atau otomatis kesimpan dari trip pertama yang dibuat).
- **`trips`** - user_id (FK, wajib - tidak ada trip guest lagi), title, num_days, budget_total, has_own_hotel (bool), hotel_place_id (FK nullable), hotel_custom_name/hotel_lat/hotel_lng (nullable - fallback kalau hotel user tidak ada di `places`, pola sama kayak custom pin di `trip_wishlist_places`), interest_category_ids (json array of `categories.id` - minat yang dipilih user, dipakai buat hitung Jaccard similarity di Section 7. Field ini yang tadinya kelewat: slider "kesesuaian kategori/minat" cuma nentuin BOBOT kriteria ini, bukan ISI minatnya - butuh langkah pilih minat terpisah, lihat Section 10), start_date, daily_start_time (default 09:00), daily_end_time (default 19:00, berlaku sama buat semua hari dalam 1 trip - bukan per-hari)
- **`trip_wishlist_places`** - trip_id FK, place_id FK (nullable - kalau custom pin di luar database, simpan name+lat+lng langsung). Input custom pin sama kayak hotel (Section 10): search dulu di katalog, kalau tidak ketemu baru tap/drag pin di `google_maps_flutter` - tidak pakai Geocoding API (produk terpisah, belum ada di budget/scope manapun di spec ini), murni koordinat dari tap posisi di peta.
- **`trip_criteria_weights`** - trip_id FK, criterion, weight (hasil normalisasi slider, disimpan supaya swap/regenerate pakai bobot yang sama)
- **`itinerary_days`** - trip_id FK, day_number, start_place_id, end_place_id (biasanya = hotel di kedua ujung)
- **`itinerary_items`** - itinerary_day_id FK, place_id FK, visit_order, topsis_score (snapshot saat generate), source (`wishlist`/`recommended`), polyline_to_here (text, encoded polyline segmen jalan dari stop sebelumnya/hotel ke stop ini - diambil dari `legs[]` Google Routes API, per-leg bukan satu polyline gabungan per hari, supaya tiap segmen bisa diwarnai independen), visited_at (nullable timestamp, diisi otomatis lewat geofence trigger dari mobile)

## 5. AI-Assisted Data Enrichment (bukan scraping)

AI (Gemini API, lihat Section 3) dipakai buat memproses data yang sudah legal kita punya, bukan buat mengambil data baru dari situs pihak ketiga (lihat Section 13 - scraping tetap di luar scope, ganti "scraper" jadi "AI agent" tidak menghilangkan masalah ToS-nya):

- **Deskripsi awal:** Google Place Details punya field `generativeSummary`/`reviewSummary` (AI-generated summary dari review Google sendiri) - diminta langsung saat sync, jadi deskripsi berkualitas tanpa kerja tambahan, sudah termasuk dalam field yang dibayar/di-request dari Places API.
- **Translasi EN + tagging kategori + estimasi durasi kunjungan - digabung jadi satu panggilan Gemini per tempat:** begitu `description` (ID) tersimpan, backend kirim satu request ke Gemini berisi name + types + description + daftar `categories` yang ada, minta output terstruktur (JSON) berisi (a) terjemahan Inggris, (b) kategori yang cocok **dari daftar yang sudah ada saja** (tidak boleh bikin tag baru sendiri - jaga taksonomi tetap rapi), dan (c) estimasi `estimated_visit_minutes` yang wajar berdasarkan tipe/kategori tempat. Satu call buat 3 kebutuhan sekaligus, bukan tiga call terpisah - tetap jauh di bawah kuota rate-limit harian Gemini.
- **Kategori hasil AI tetap butuh review admin** (beda dari translasi yang cuma teks tampilan) - karena `category_tags` langsung dipakai di scoring TOPSIS (Jaccard similarity, Section 7), tag yang salah bisa bikin rekomendasi melenceng, bukan cuma typo kosmetik. `place_attributes.category_tags_reviewed` (bool, default false) ditandai true begitu admin cek/konfirmasi di panel - tag AI tetap langsung aktif dipakai algoritma sementara menunggu direview (tidak memblokir), tapi dashboard admin (Section 11) nampilin daftar "tempat yang kategorinya belum direview" biar tidak kelupaan selamanya.
- **Volume & rate limit:** ~300-500 tempat x 1 call = 300-500 request, dijalankan sebagai background job setelah sync dengan jeda antar-request (respect 5-15 RPM limit Gemini free tier) - selesai dalam hitungan puluhan menit, jauh di bawah kuota 1.000 request/hari.

## 6. Rating Blend (Google + In-App)

Rating in-app dipakai buat blend dengan rating Google di kriteria TOPSIS, bukan cuma data analitik pasif. Supaya tempat baru dengan 1 review 5 bintang tidak mengalahkan tempat dengan 2.000 review asli, dipakai Bayesian-average blend (mirip formula rating IMDB): rata-rata in-app menarik bobot makin besar seiring bertambahnya jumlah review in-app, tapi hampir sepenuhnya mengikuti rating Google kalau review in-app masih sedikit/nol (menghindari cold-start problem).

## 7. Recommendation Engine Flow

1. **Trip setup (mobile):** num_days, budget_total, start_date, daily_start_time/daily_end_time (optional, default 09:00-19:00), toggle "sudah punya hotel?".
2. **Wishlist (mobile, opsional):** user browse/scroll katalog tempat (seperti e-commerce - grid/list, filter kategori, infinite scroll via pagination) dan tambah ke wishlist. Ini terjadi sebelum tahap generate.
3. **Minat + bobot kriteria (mobile):** dua hal terpisah, jangan tertukar. (a) **Pilih minat** - multi-select chip dari daftar `categories` (alam, kuliner seafood, sejarah, dst) -> disimpan ke `trips.interest_category_ids`, ini yang jadi ISI buat Jaccard similarity di langkah 5. (b) **Bobot kriteria** - user isi 4 slider (0-10): kesesuaian kategori/minat, jarak/lokasi, kesesuaian anggaran, rating/popularitas, nentuin seberapa PENTING tiap kriteria (termasuk seberapa penting kecocokan minat yang baru dipilih di atas). Backend normalisasi: `weight_i = rating_i / sum(semua rating)`.
4. **Hotel (backend):** kalau tidak punya hotel sendiri (input via search di katalog `places` atau custom pin lat/lng, sama seperti pola wishlist - Section 4), jalankan TOPSIS 3-kriteria (jarak ke area wisata terpilih, kesesuaian anggaran, rating) khusus `type=lodging`, tampilkan top-3 buat dipilih user. Bobot 3 kriteria ini **pakai ulang** `trip_criteria_weights` milik trip (jarak/anggaran/rating dari slider user, kategori/minat dibuang lalu sisanya dinormalisasi ulang supaya total tetap 1) - bukan skema bobot terpisah. "Area wisata terpilih" buat kriteria jarak dihitung dari centroid koordinat `trip_wishlist_places`; kalau wishlist kosong (user skip wishlist sama sekali), fallback ke centroid tempat kandidat berskor tertinggi di kategori minat yang dipilih user. Kalau sudah punya hotel, lewati langkah ini - lokasi yang diinput user jadi titik awal/akhir.
5. **Scoring kandidat (backend):** filter `attraction`/`culinary` berdasarkan kategori + kompatibilitas jam buka terhadap daily_start_time/daily_end_time, bangun matriks keputusan TOPSIS (baris = kandidat tempat, kolom = 4 kriteria dengan bobot dari langkah 3), hitung closeness-to-ideal score. Detail tiap kriteria:
   - **Kesesuaian kategori/minat** (benefit, maksimalkan) - Jaccard similarity antara `trips.interest_category_ids` (langkah 3a) dan `place_attributes.category_tags` tempat tsb.
   - **Jarak/lokasi** (cost, minimalkan) - Haversine dari hotel/titik awal.
   - **Kesesuaian anggaran** (cost, minimalkan) - nilai diambil berjenjang 4 tingkat: (1) `place_attributes.estimated_cost_idr` kalau admin sudah isi, (2) kalau kosong, `places.price_level` dipetakan ke rentang IDR kasar, (3) kalau keduanya kosong, median harga tempat lain di kategori `type` yang sama yang datanya ada (imputasi netral - tempat tidak dihukum atau diuntungkan, cuma jadi rata-rata di kriteria ini), (4) **kalau kategori itu sama sekali belum ada satupun data harga** (bisa kejadian pas bootstrap awal - misal semua attraction belum ada priceLevel dari Google maupun input admin, jadi tidak ada apa-apa buat dihitung median-nya) - fallback ke nilai default hardcode per `type` (misal Rp 50.000 buat attraction/culinary, Rp 300.000 buat lodging) sampai data asli mulai terisi. Tetap dibedakan penuh oleh 3 kriteria lain di semua tingkat fallback ini.
   - **Rating/popularitas** (benefit, maksimalkan) - blend Bayesian rating Google + in-app (Section 6).
6. **Pembagian hari (backend):**
   a. K-Means clustering (k = num_days) atas koordinat tempat wishlist, supaya wishlist yang lokasinya berjauhan tidak masuk hari yang sama.
   b. **Budget waktu per hari dihitung dari visit duration + estimasi waktu tempuh, bukan visit duration doang** - `sum(estimated_visit_minutes semua stop) + sum(estimasi waktu tempuh antar stop berurutan)` dibandingkan ke (`daily_end_time` - `daily_start_time`). Estimasi waktu tempuh: jarak Haversine **dikali faktor detour ~1.3-1.4x** (garis lurus meremehkan jarak jalan asli, apalagi di Batam yang berbentuk pulau dengan jembatan/garis pantai tidak beraturan - bukan grid kota biasa), baru dibagi asumsi kecepatan rata-rata kota ~25-30 km/jam. Ini cuma estimasi kasar buat keputusan muat/tidak muat di tahap ini - waktu tempuh asli dari Routes API baru diketahui di langkah 6e (setelah urutan fix), lihat validasi pasca-6e di bawah. Kalau total estimasi di satu cluster hari melebihi budget, item overflow (prioritas terendah - terjauh dari centroid cluster) otomatis didorong (push) ke hari berikutnya, cascading kalau perlu. Kalau tetap tidak muat sampai hari terakhir, hari itu dikembalikan dengan flag "tidak muat".
   c. Slot kosong tiap hari diisi tempat rekomendasi TOPSIS terdekat dari centroid cluster hari itu (atau dari hotel kalau hari itu tidak ada wishlist), berhenti nambah begitu proyeksi visit+tempuh (langkah 6b) bakal lewat budget hari itu. Tempat yang sudah dipakai di hari manapun dalam generate run yang sama langsung dikeluarkan dari pool kandidat hari berikutnya - tidak ada tempat yang muncul dobel di lebih dari satu hari.
   d. Nearest-neighbor (Haversine) dijalankan per hari (wishlist + recommended digabung) mulai dan berakhir di hotel/titik awal, untuk menentukan urutan kunjungan.
   e. Setelah urutan per hari fix, backend panggil Google Routes API (`computeRoutes`) sekali per hari dengan seluruh waypoint (hotel -> stop 1 -> stop 2 -> ... -> hotel), lalu simpan tiap segmen dari `legs[]` response ke `polyline_to_here` milik stop tujuan masing-masing (bukan satu polyline gabungan) - satu API call tetap cukup buat seluruh hari karena Routes API mendukung multi-waypoint dalam satu request.
   f. **Validasi pasca-fakta:** bandingkan total durasi asli dari Routes API (langkah 6e) + visit duration terhadap budget waktu hari itu. Kalau ternyata melebihi cukup jauh (estimasi kasar di 6b meleset), hari itu ditandai flag "padat" di response (sama seperti flag "tidak muat" di 6b) - bukan dibiarkan diam-diam jadi jadwal yang secara fisik terlalu padat.
7. **Swap (backend):** ganti satu item - ambil alternatif TOPSIS peringkat berikutnya yang belum dipakai (kategori & radius hari yang sama), atau user cari manual lewat browse/search penuh. Setelah swap, urutan NN dihitung ulang untuk hari itu (langkah 6d) dan `polyline_to_here` di-refresh buat stop yang urutannya berubah (langkah 6e) - hari lain tidak terpengaruh.

Pipeline: **K-Means (pembagian hari)** -> **Weighted-TOPSIS (ranking kandidat)** -> **Nearest-Neighbor (urutan rute)** -> **Routes API (polyline jalan asli per segmen)**.

## 8. Live Trip Map & Visit Tracking

Saat user membuka peta untuk hari yang sedang aktif, tampilan menunjukkan progres perjalanan hari itu, bukan cuma rute statis:

- **Marker hotel/titik awal** - dari `itinerary_days.start_place_id`
- **Marker lokasi user saat ini** - live, dari `geolocator` position stream selama layar peta terbuka
- **Pin bernomor tiap stop** sesuai `visit_order`
- **Polyline per segmen** (`itinerary_items.polyline_to_here`) diwarnai **abu-abu** kalau stop tujuan segmen itu sudah `visited_at` terisi, **biru** kalau belum - persis pola warna rute yang sudah/belum dilalui di Google Maps navigasi
- **Titik akhir** - `itinerary_days.end_place_id` (biasanya hotel yang sama)

**Deteksi kunjungan (otomatis, geofencing):** selama trip berlangsung, mobile app mendaftarkan geofence radius 100m (default, bisa disesuaikan) untuk tiap stop yang belum `visited_at` di hari aktif, pakai plugin geofencing native (misal `geofence_service`) - bukan polling GPS manual, supaya lebih hemat baterai dan tetap jalan walau app di-background. Begitu geofence entry event terpicu, app memanggil `POST /api/itinerary-items/{id}/visit` untuk set `visited_at`, lalu peta refresh warna segmen terkait.

**Catatan risiko/scope:** location tracking background butuh permission "Allow all the time" di Android dan "Always" di iOS - keduanya permission sensitif yang direview ketat oleh Play Store/App Store dan wajib ada privacy policy kalau mau publish ke store. Untuk keperluan demo/skripsi (sideload/internal testing) ini bukan blocker, tapi kalau rencananya publish ke Play Store perlu effort tambahan (justifikasi permission, privacy policy) di luar todo teknis biasa. Server tidak (dan tidak perlu) memverifikasi keaslian lokasi device saat menerima `visit` - cukup untuk kebutuhan visualisasi progres, bukan sistem check-in yang butuh anti-fraud.

**Edge cases:**

- **Permission lokasi background ditolak, atau geofence tidak kepicu (GPS drift, radius meleset, user lewat tanpa masuk radius):** tiap stop tetap punya opsi **tandai manual** (long-press pin di peta, atau tombol di kartu itinerary) yang manggil endpoint `visit` yang sama - auto-detection jadi cara utama, bukan satu-satunya cara. Tombol yang sama juga bisa dipakai buat batalkan tanda (toggle, set `visited_at` balik ke null) kalau auto-detection salah trigger.
- **Stop yang di-skip** (user langsung ke stop 3 tanpa geofence stop 2 kepicu): segmen ke stop 2 tetap **biru selamanya** sampai user tandai manual - tidak ada auto-assume "kalau stop sesudahnya visited berarti ini juga visited", karena skip beneran (bukan cuma GPS meleset) itu valid use-case (misal user memang berubah rencana).
- **App ditutup penuh (bukan cuma di-background):** geofence didaftarkan di level OS (Android Geofencing API / iOS region monitoring via `geofence_service`), bukan terikat lifecycle layar peta - registrasi terjadi sekali saat user tap "Mulai Hari Ini" di awal hari itu, sehingga tetap bisa trigger & wake app walau app sudah di-kill, selama OS tidak mematikan proses sepenuhnya (lihat catatan battery optimization di bawah).
- **Tidak ada koneksi internet saat geofence trigger:** event `visit` disimpan dulu di local queue (SQLite/shared prefs), retry otomatis dengan backoff begitu koneksi kembali - bukan langsung gagal silent.
- **Trip multi-hari:** geofence cuma didaftarkan untuk stop-stop di hari yang lagi aktif (hari yang di-"Mulai"-kan), bukan seluruh hari sekaligus - supaya lewat dekat lokasi hari ke-3 saat masih hari ke-1 tidak salah ke-trigger. Geofence hari sebelumnya di-deregister saat pindah/mulai hari berikutnya.
- **Battery optimization (Android):** beberapa OEM (MIUI, OnePlus, dll) agresif mematikan background service walau geofence terdaftar di level OS - app perlu minta exemption dari battery optimization saat user pertama kali mulai live tracking, dan ini didokumentasikan sebagai known risk, bukan sesuatu yang bisa 100% dijamin dari sisi app.

## 9. API Endpoints

Semua endpoint di bawah butuh Sanctum bearer token **kecuali** yang eksplisit ditandai (publik) - login wajib sebelum bikin trip, tidak ada alur guest.

```
Auth
POST   /api/auth/register                          (publik)
POST   /api/auth/login                              (publik)
POST   /api/auth/google                             (publik) - body: {id_token} dari google_sign_in Flutter,
                                                      backend verifikasi ke Google, cari/link/buat user,
                                                      balikin Sanctum token - sama persis shape-nya
                                                      kayak response /login biasa
POST   /api/auth/logout                             - butuh token (buat tahu token mana yang direvoke),
                                                      ini kenapa tidak boleh ikut grup publik

Profil
GET    /api/profile/preferences                    - default_interest_category_ids + user_criteria_weights
PUT    /api/profile/preferences                     - update default (dari layar Profil, atau saat "simpan sebagai default" di trip setup)

Trip setup
POST   /api/trips                                 - create trip (langsung terikat user login)
                                                      body: num_days, budget_total, start_date,
                                                      daily_start_time?, daily_end_time?, has_own_hotel
GET    /api/trips/{id}                             - trip detail (+ itinerary + polyline_to_here tiap stop setelah generate)
POST   /api/trips/{id}/hotel                       - set hotel pilihan/sendiri sebagai titik awal/akhir
GET    /api/trips/{id}/hotel-options                - top-3 hotel ranking TOPSIS (skip kalau has_own_hotel)

Wishlist
POST   /api/trips/{id}/wishlist                    - tambah wishlist (place_id, atau custom name+lat+lng)
GET    /api/trips/{id}/wishlist                     - list wishlist
DELETE /api/trips/{id}/wishlist/{wishlist_id}       - hapus item wishlist

Bobot & generate
POST   /api/trips/{id}/weights                     - submit 4 slider rating -> bobot ternormalisasi
POST   /api/trips/{id}/generate                     - jalankan K-Means + TOPSIS + Nearest-Neighbor -> itinerary
GET    /api/trips                                   - list trip tersimpan
DELETE /api/trips/{id}                               - hapus trip tersimpan

Swap
GET    /api/itinerary-items/{id}/swap-candidates     - alternatif ranking (mode=ranked)
GET    /api/places?search=&category=&near_itinerary_day={day_id}   - "cari lainnya" manual
PATCH  /api/itinerary-items/{id}                     - commit swap {place_id}, re-run NN hari itu

Live tracking
POST   /api/itinerary-items/{id}/visit               - tandai visited_at (dipanggil mobile saat geofence entry)

Places & review
GET    /api/places                                  - browse/search umum (katalog tempat)          (publik)
GET    /api/places/{id}                              - detail tempat                                (publik)
POST   /api/places/{id}/reviews                      - submit rating/review in-app
PATCH/DELETE /api/reviews/{id}                        - edit/hapus review milik sendiri

Admin                                                (role admin)
GET/POST/PATCH        /api/admin/places
GET/POST/PATCH        /api/admin/place-attributes
GET/POST/PATCH/DELETE /api/admin/categories
POST                  /api/admin/places/discover     - trigger fase Discovery (isi place_candidates)
GET                   /api/admin/place-candidates     - list candidate (filter status/search_area)
POST                  /api/admin/place-candidates/{id}/approve  - promosikan ke places (trigger enrichment)
POST                  /api/admin/place-candidates/{id}/reject
GET                   /api/admin/places/sync-status
GET                   /api/admin/analytics           - tempat terfavorit, rata-rata rating, volume trip
```

Tidak ada endpoint notifikasi - reminder mulai hari & notif mendekati stop sepenuhnya dijadwalkan/dipicu di device (lihat Section 2), tidak butuh backend.

## 10. Mobile App Flow (Flutter)

0. Pilihan bahasa (ID/EN) - default ikut bahasa device, bisa diganti kapan saja lewat settings
1. Home (browse katalog tempat bisa tanpa login) -> tap "Buat Trip" -> kalau belum login, diarahkan ke Login/Register dulu (wajib, tidak ada opsi "lanjut sebagai guest"). Layar ini juga ada tombol "Masuk pakai Google" (`google_sign_in` Flutter package -> `POST /api/auth/google`) selain email/password.
1a. **Onboarding minat - gate berdasarkan kondisi, bukan event sekali jalan:** setiap kali app dibuka dengan sesi login aktif (bukan cuma tepat setelah Register - checked di app launch DAN tiap habis Login berhasil), cek `default_interest_category_ids` user. Kalau kosong, layar Pilih Minat (multi-select chip, wajib pilih minimal 1) muncul dan **memblokir** semua layar lain sampai terisi - hasilnya langsung `PUT /api/profile/preferences`. Kalau sudah ada isinya, langsung lanjut seperti biasa tanpa muncul apa-apa. **Ini otomatis nutup edge case user nutup app tepat setelah Register** (sebelum sempat isi minat) - tidak butuh flag/state "baru saja register" sama sekali, gate-nya murni cek kondisi "masih kosong atau tidak" tiap kali sesi mulai, jadi kalau ke-skip kemarin (app ditutup paksa), bakal ke-tangkep lagi pas dibuka lagi. Setelah keisi, lanjut ke tujuan awal (trip setup kalau trigger-nya dari "Buat Trip", atau Home kalau login biasa). Berlaku sama persis buat akun baru dari Google Sign-In - tidak butuh kode khusus, karena akun baru (dari jalur manapun) otomatis punya `default_interest_category_ids` kosong dan langsung ke-gate oleh pengecekan yang sama.
2. Trip setup: num_days, budget_total, start_date, daily start/end time (opsional, default ditampilkan), toggle "sudah punya hotel?"
3. Wishlist (opsional): katalog tempat gaya e-commerce (grid/list, filter kategori, infinite scroll) dengan tombol "+ wishlist" per kartu. Tempat yang tidak ada di katalog bisa ditambah manual: cari dulu, kalau tidak ketemu baru tap/drag pin di peta (`google_maps_flutter`) + nama bebas - tanpa Geocoding API.
4. Pilih minat (multi-select chip kategori) + slider preferensi (4 kriteria, 0-10) - dua langkah beda tujuan, lihat Section 7 langkah 3. Kalau `default_interest_category_ids`/`user_criteria_weights` sudah ada (dari Profil atau trip sebelumnya), layar ini pre-filled - user tinggal edit kalau mau beda buat trip ini. Ada toggle "simpan sebagai default" (opsional, tidak auto-overwrite diam-diam) buat update `user_criteria_weights`/`default_interest_category_ids` dari pilihan trip ini.
5. Kalau sudah punya hotel: cari di katalog (pola sama persis kayak wishlist di atas - search dulu, pin manual kalau tidak ketemu). Kalau belum: tampilkan top-3 pilihan hotel hasil TOPSIS.
6. Loading -> hasil itinerary (otomatis tersimpan ke akun, tidak ada langkah "simpan" terpisah): kartu per hari, tiap tempat ada badge source (wishlist/recommended). Reminder "mulai hari ini" otomatis terjadwal (local notification) untuk tiap hari di itinerary.
7. Menu "..." per item -> swap (alternatif ranking atau cari manual)
8. Tombol "Buka Peta" per hari -> live map (lihat Section 8): marker hotel, lokasi user saat ini, pin bernomor per stop, polyline abu-abu/biru sesuai status kunjungan; geofencing otomatis aktif selama layar ini/trip berjalan. Notif "sudah dekat stop berikutnya" muncul saat geofence entry terpicu.
9. List trip tersimpan -> buka lagi, edit (regenerate penuh kalau ubah num_days/budget/hotel, partial swap kalau cuma ganti 1 tempat), hapus, tambah review in-app setelah kunjungan
10. Tab Profil - edit `default_interest_category_ids` + `user_criteria_weights` langsung (di luar alur bikin trip), lewat `GET/PUT /api/profile/preferences`

Alur di atas berlaku buat semua user. Kalau `role = admin`, ada tab/menu tambahan yang muncul di atas alur ini - lihat Section 11.

## 11. Admin Screens (Flutter, role-gated - bukan web panel terpisah)

Semua ini adalah layar tambahan di app Flutter yang sama, cuma muncul kalau `users.role = admin` (Section 2) - dikonsumsi lewat endpoint `/api/admin/*` yang sama seperti kalau backend-nya dipakai web panel, cuma UI-nya native Flutter:

- **CRUD Places** - list/search places (data hasil Google + manual), form edit atribut custom (estimated_cost_idr, description_override, description_en, estimated_visit_minutes), tambah manual tempat yang tidak ada di Google
- **CRUD Categories** - list/tambah/edit/hapus tag kategori, jaga `slug` unik biar tidak ada duplikat mirip kayak "kuliner" vs "wisata kuliner"
- **Review candidate tempat** (Section 3) - tombol trigger discovery per area/kategori, list `place_candidates` (filter per search_area/status), approve (promosikan + fetch detail lengkap + AI enrichment) atau reject - bisa satu-satu atau bulk-select
- Status sync terakhir (kapan discovery/enrichment terakhir jalan, berapa candidate pending)
- Dashboard analitik (chart/kartu ringkas) - tempat paling di-wishlist, rata-rata rating in-app, volume trip, **daftar tempat yang belum ada estimated_cost_idr**, **daftar tempat yang category_tags-nya belum direview**

**Catatan effort:** layar-layar ini (terutama list+filter place_candidates dan dashboard chart) secara teknis lebih banyak kerjaan buat dibangun native di Flutter dibanding kalau pakai admin panel web siap pakai (Blade+DataTables/Filament) - trade-off yang disadari demi satu codebase mobile-only, bukan oversight.

## 12. Testing Approach

- Backend: unit test untuk bagian matematis murni (normalisasi bobot, scoring TOPSIS, Haversine, K-Means clustering, blend rating Bayesian) karena deterministik dan gampang diverifikasi terhadap input yang sudah diketahui hasilnya - bagian ini juga paling penting untuk dipertanggungjawabkan metodenya.
- Feature test untuk endpoint API (alur create trip -> generate -> swap -> visit).
- Flutter: widget test untuk layar input slider/wishlist dan layar admin (form CRUD, list place_candidates), QA manual untuk alur penuh termasuk geofencing (auto-generate output & lokasi GPS tidak praktis diasersi persis lewat widget test).

## 13. Out of Scope (semester ini)

- Laporan akademik (di luar dokumen ini per instruksi user)
- Scraping platform lain (TripAdvisor/Traveloka/Tiket.com) - hanya Google Places sebagai sumber data eksternal
- True AHP pairwise comparison - dipakai direct-rating slider yang lebih simpel untuk UX mobile
- Kolaborasi/sharing itinerary antar user
- Re-routing otomatis kalau user menyimpang dari rute (out of order visit tetap dicatat per-stop, tapi tidak ada logika "hitung ulang rute optimal dari posisi user sekarang")
- Publish ke Play Store/App Store (kalau nanti perlu, siapkan privacy policy + justifikasi background location permission dulu)
- Booking/reservasi/pembayaran (tiket masuk, kamar hotel, meja restoran) - app murni rekomendasi & perencanaan, bukan transaksi
- Ganti hotel di tengah trip (1 hotel = 1 titik awal/akhir buat seluruh trip, wajar untuk kota sekecil Batam)
- Batas num_days disarankan max 7 hari (bukan hard rule teknis, tapi realistis mengingat pool awal cuma ~300-500 tempat kurasi - bisa direvisit setelah lihat kepadatan data asli Batam pasca sync pertama)
- Multi-kota - skema Batam-only, tidak ada field `city` di manapun (places, trips, area list Discovery semua hardcode buat Batam). Kalau nanti mau ekspansi ke kota lain, butuh migration + refactor Discovery, bukan cuma config baru - keputusan sadar buat menghindari kerja di muka buat kemungkinan yang belum pasti kejadian semester ini.
- Jam operasional per-hari berbeda dalam 1 trip (misal hari kedatangan mulai lebih siang, hari kepulangan selesai lebih awal) - `daily_start_time`/`daily_end_time` tetap 1 nilai berlaku semua hari; kalau ada hari yang perlu jam beda, user swap manual tempat yang kepepet waktu
