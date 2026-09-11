# SmartTrip Batam - Daftar Halaman untuk Mockup

Sumber: `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` + `docs/prd/2026-09-07-smarttrip-prd.md` (v1.6). Satu app Flutter, role-gated - bagian Admin (G) adalah app yang sama, bukan build terpisah.

26 layar total: 19 buat user biasa, 7 buat admin (C2a adalah satu layar reusable yang dipakai bareng di alur wishlist dan hotel).

---

## A. Onboarding & Auth

### A1. Splash / Pilihan Bahasa
**Tujuan:** Layar pertama saat cold start. Nentuin bahasa sebelum apapun lain dirender.
**Info yang ditampilkan:** Logo/nama app, tagline singkat.
**Tombol:** Bahasa Indonesia / English (2 pilihan, tap target besar). Default ngikut bahasa device, layar ini bisa auto-skip kalau sudah pernah diset sebelumnya (`shared_preferences`).
**Lanjut ke:** Home (lihat B1 di bawah).

### A2. Login
**Tujuan:** Masuk pakai email/password atau Google. Dicapai dari Home saat tap "Buat Trip" dalam keadaan belum login.
**Info yang ditampilkan:** Logo app, header "Masuk".
**Field:** Email, Password.
**Tombol:** "Masuk" (utama), "Masuk pakai Google" (sekunder, alur `google_sign_in`), "Belum punya akun? Daftar" (link ke A3). Tidak ada opsi "lanjut sebagai guest" di layar manapun - jalur itu sudah sengaja dihapus dari scope.
**Error state:** Kredensial salah, token Google tidak valid/expired (US9 AC).

### A3. Daftar (Register)
**Tujuan:** Bikin akun baru.
**Field:** Nama, Email, Password, Konfirmasi Password.
**Tombol:** "Daftar" (utama), "Daftar pakai Google" (sekunder), "Sudah punya akun? Masuk" (link balik ke A2).
**Perilaku:** Setelah berhasil, selalu lanjut ke A4 dulu (lihat di bawah) - registrasi tidak pernah langsung mendarat di Home.

### A4. Pilih Minat (Gerbang Onboarding)
**Tujuan:** Pemilihan minat wajib pertama kali. **Gate berdasarkan kondisi, bukan event** - muncul tiap kali app dibuka/login selama `default_interest_category_ids` masih kosong, bukan cuma sekali persis setelah register (ini yang bikin gate-nya tetap jalan walau user nutup app di tengah onboarding).
**Info yang ditampilkan:** Teks instruksi singkat ("Pilih minimal 1 kategori yang kamu suka").
**Konten:** Grid/wrap chip kategori, diambil dari `categories` (alam, kuliner seafood, belanja, sejarah, dst) - bisa pilih lebih dari satu.
**Tombol:** "Lanjut" (utama, disabled/abu-abu sampai minimal 1 chip dipilih - layar ini tidak ada opsi lewati).
**Blocking:** Tidak bisa pindah layar (tidak ada tombol back yang bisa kabur) sampai disubmit.
**Setelah submit:** `PUT /api/profile/preferences`, lalu lanjut ke tujuan awal (Home, atau langsung ke Trip Setup kalau tadinya tap "Buat Trip" sebelum login).

---

## B. Jelajah & Penemuan Tempat

### B1. Home
**Tujuan:** Layar pendaratan, sepenuhnya bisa dipakai tanpa login.
**Info yang ditampilkan:** Tempat unggulan/terbaru, chip filter kategori.
**Konten:** `PlaceCatalogGrid` - grid/list infinite-scroll kartu tempat (`PlaceCard`: thumbnail, nama, badge kategori, rating, tingkat harga).
**Tombol:** Chip filter kategori (bisa pilih lebih dari satu), search bar, "+ wishlist" quick-add di tiap kartu (baru berarti kalau lagi di dalam alur bikin trip aktif - lihat catatan di bawah), tap kartu → C2 Detail Tempat. Bottom nav: Home / Trip / Profil (+ tab Admin kalau `role=admin`).
**CTA utama:** "Buat Trip" (floating action button atau tombol header menonjol) → di-gate login (A2) kalau belum masuk.
**Empty state:** Katalog kosong (sebelum bootstrap admin pertama) - "Belum ada data tempat, coba lagi nanti."

### B2. Detail Tempat
**Tujuan:** Info lengkap satu tempat. Bisa dicapai dari Home, browsing Wishlist, search Swap, atau salah satu stop di dalam itinerary.
**Info yang ditampilkan:** Carousel foto (`place_photos`), nama, tag kategori, alamat, telepon, website, jam buka, rating gabungan (Google + in-app, Bayesian), tingkat harga/estimasi biaya, deskripsi (dwibahasa, fallback ke ID kalau EN kosong), link "Buka di Google Maps" (`google_maps_uri`).
**Tombol:** "+ Wishlist" (kalau lagi di dalam alur bikin trip aktif), "Tulis Review" (buka D5), "Buka di Google Maps" (eksternal), back.
**Bagian review:** List `place_reviews` yang sudah ada (rating + komentar), rata-rata ditampilkan di atas.
**Empty state:** Belum ada review - "Jadi yang pertama kasih review."

---

## C. Wizard Bikin Trip

Cuma bisa dicapai kalau sudah login (gate A2 berlaku sebelum C1).

### C1. Trip Setup
**Tujuan:** Langkah 1 wizard - dasar-dasar level trip.
**Field:** Jumlah hari (`num_days`, stepper, peringatan lembut di atas 7), Anggaran total (`budget_total`, input IDR), Tanggal mulai (`start_date`, date picker), Jam mulai/selesai harian (`daily_start_time`/`daily_end_time`, opsional, default 09:00/19:00 sudah keisi), toggle "Sudah punya hotel?".
**Tombol:** "Lanjut" (utama, validasi `budget_total` > 0 di client sebelum lanjut), back (batalkan progress wizard dengan dialog konfirmasi).
**Indikator progress:** Langkah 1 dari ~4 (Trip Setup → Wishlist → Minat & Preferensi → Hotel → generate).

### C2. Susun Wishlist
**Tujuan:** Opsional - tambah tempat wajib-dikunjungi sebelum generate.
**Konten:** Pola `PlaceCatalogGrid` sama seperti B1, tapi ada tombol "+ wishlist" persisten di tiap kartu dan hitungan berjalan ("3 tempat ditambahkan").
**Tombol:** "Tambah manual" (buka C2a pemilih peta buat tempat yang tidak ada di katalog), "Lanjut" (tetap bisa lanjut walau 0 item wishlist - sepenuhnya opsional), "Lewati" (langsung lompat), back.
**Tampilan list:** Toggle atau tab terpisah nampilin item wishlist yang sudah ditambah dengan tombol hapus (×) di tiap item.

### C2a. Pemilih Pin Manual (modal/full-screen)
**Tujuan:** Tambah tempat yang tidak ada di katalog - dipakai persis sama buat tambah manual wishlist dan tambah manual hotel (C4a).
**Konten:** Peta `google_maps_flutter`, tap/drag buat naruh pin, field nama bebas di bawah peta.
**Tombol:** "Simpan" (commit nama + lat/lng), "Batal".
**Catatan:** Tidak ada ketik-alamat/autocomplete (butuh Geocoding API, sengaja di luar scope) - cuma tap di peta.

### C3. Pilih Minat + Slider Preferensi (level trip)
**Tujuan:** Dua hal berbeda di satu layar - kategori mana yang penting buat trip spesifik ini, dan seberapa besar bobot tiap 4 kriteria skoring.
**Konten bagian 1 (minat):** Chip-select sama seperti A4, **pre-filled** dari `default_interest_category_ids` kalau sudah diset - bisa diedit khusus buat trip ini tanpa mengubah default tersimpan.
**Konten bagian 2 (bobot):** 4 slider, 0-10 masing-masing: Kesesuaian kategori/minat, Jarak/lokasi, Kesesuaian anggaran, Rating/popularitas. Pre-filled dari `user_criteria_weights` kalau sudah diset.
**Tombol:** Toggle "Simpan sebagai default" (mati secara default, opt-in - baru nulis balik ke profil kalau dicentang eksplisit), "Lanjut", back.

### C4. Pilih Hotel
**Tujuan:** Tentukan titik awal/akhir trip.
**Cabang A - toggle "Sudah punya hotel" aktif (dari C1):** Field search (typeahead ke `places` yang `type=lodging`) → tap hasil buat pilih, ATAU "Tidak ketemu?" → buka pemilih peta gaya C2a.
**Cabang B - belum punya hotel:** Sistem jalankan TOPSIS 3-kriteria yang lebih ringan, tampilkan **top-3 kartu hotel** (nama, foto, tingkat harga, rating, jarak dari area) dengan tombol pilih di tiap kartu.
**Tombol:** "Lanjut" (baru aktif setelah hotel terpilih lewat cara manapun), back.

### C5. Sedang Generate (Loading)
**Tujuan:** Layar transisi selama `POST /api/trips/{id}/generate` menjalankan pipeline lengkap (TOPSIS → K-Means → NN → Routes API).
**Konten:** Skeleton/spinner, teks status berputar itu polish opsional ("Menyusun rute...", "Menghitung skor tempat...").
**Tanpa tombol** - belum bisa dibatalkan di v1 (tidak jadi requirement; biar tetap simpel).
**Error state:** Kalau generate gagal atau balikin flag "tidak muat", tetap arahkan ke D1 dan flag-nya ditampilkan di sana, bukan diblokir di sini.

---

## D. Itinerary & Manajemen Trip

### D1. Hasil Itinerary
**Tujuan:** Layar utama hasil akhir - trip yang baru digenerate (atau dibuka lagi).
**Info yang ditampilkan:** Header judul/tanggal trip, tab per hari atau list scroll vertikal kartu hari.
**Konten tiap kartu hari:** Nomor/tanggal hari, list stop sesuai urutan kunjungan, tiap stop nampilin thumbnail, nama, badge sumber (Wishlist / Rekomendasi), estimasi waktu kunjungan. `WeatherForecastCard` muncul di header hari begitu `start_date` sudah dalam window ~7 hari. Banner flag "padat"/"tidak muat" kalau hari itu kena salah satunya saat generate.
**Tombol per stop:** Tap → B2 Detail Tempat, menu "..." → Swap (buka D2).
**Tombol per hari:** "Buka Peta" (buka E1 Live Map buat hari itu), `WeatherSwapBadge` (cuma muncul kalau ada stop outdoor + prediksi hujan - tap langsung lompat ke D2 yang sudah di-scope ke stop tsb).
**Tombol level layar:** "Edit Trip" (balik ke C1 dengan field pre-filled - ubah num_days/budget/hotel memicu regenerate penuh, dikonfirmasi lewat dialog sebelum disubmit), "Hapus Trip" (dialog konfirmasi), back ke D3.

### D2. Modal Swap
**Tujuan:** Ganti satu stop tanpa mengubah yang lain di hari itu.
**Konten:** Dua tab/bagian - "Rekomendasi" (alternatif ranking TOPSIS, kategori/radius area yang sama) dan "Cari Manual" (search gaya `PlaceCatalogGrid` penuh).
**Tombol:** Tap kartu kandidat buat pilih jadi pengganti, "Batal".
**Setelah commit:** Nearest-Neighbor dihitung ulang cuma buat hari itu, cuma polyline segmen yang terpengaruh yang di-refresh - modal ketutup balik ke D1 dengan kartu hari itu terupdate.

### D3. List Trip Tersimpan
**Tujuan:** Semua trip milik user yang sedang login.
**Konten:** List kartu trip - judul, rentang tanggal, jumlah hari, thumbnail/preview kecil.
**Tombol:** Tap kartu → D1 (trip tsb), "Buat Trip" (mulai alur C1 baru), swipe-to-delete atau menu "..." per kartu dengan "Hapus" (dialog konfirmasi).
**Empty state:** Belum ada trip - "Trip pertamamu tinggal 1 tap lagi" + CTA "Buat Trip" yang menonjol.

### D4. Detail Prediksi Cuaca (opsional, tampilan lebih lengkap)
**Tujuan:** Tap `WeatherForecastCard` di D1 bisa langsung nampilin tooltip inline, atau expand ke sheet detail kecil ini - keputusan tim soal fidelity, dimasukin di sini biar lengkap.
**Konten:** Breakdown per hari lebih detail (rentang suhu, probabilitas hujan, deskripsi singkat) sumbernya langsung dari Open-Meteo client-side.
**Tombol:** Tutup/dismiss.

### D5. Form Review
**Tujuan:** Kasih rating/review tempat. Bisa dicapai dari B2 (review umum, `itinerary_item_id` tetap null) atau dari prompt pasca-kunjungan di D1/E1 buat stop yang `visited_at`-nya sudah keisi (`itinerary_item_id` keisi).
**Field:** Rating bintang (1-5, wajib), komentar (opsional, multi-baris).
**Tombol:** "Kirim", "Batal".

---

## E. Pengalaman Trip Live

### E1. Peta Live (per hari aktif)
**Tujuan:** Layar tracking live gaya navigasi GMaps, dibuka dari tombol "Buka Peta" di D1.
**Konten:** Peta `google_maps_flutter` - marker hotel/titik awal, pin bernomor buat tiap stop (semua langsung kelihatan sekaligus, tidak progresif), polyline per segmen diwarnai **abu-abu** (sudah dikunjungi) / **biru** (belum), titik lokasi user live, `GeofenceStatusIndicator` (badge kecil konfirmasi tracking aktif), `WeatherForecastCard` kalau sudah dalam window 7 hari.
**Tombol:** "Mulai Hari Ini" (tap pertama di hari itu - daftarin geofence level OS buat stop-stop yang belum dikunjungi hari itu, mulai seluruh alur tracking), long-press pin manapun → `ManualVisitToggle` (tandai/batalkan kunjungan, jalan terlepas dari status geofence), tap pin → kartu info mini dengan "..." → Swap (D2), back ke D1.
**Notifikasi yang dipicu dari sini (bukan layar, tapi relevan):** notif lokal "sudah dekat stop berikutnya" saat geofence terpicu, prompt `WeatherSwapBadge` kalau berlaku.
**Alur permission:** Tap "Mulai Hari Ini" pertama kali memicu prompt permission lokasi background OS; kalau ditolak, peta tetap jalan, cuma fallback ke tandai-manual-saja (tidak gagal diam-diam).

---

## F. Akun

### F1. Profil
**Tujuan:** Pengaturan level akun, terpisah dari trip manapun.
**Info yang ditampilkan:** Nama, email, tipe akun (password / terhubung Google).
**Konten:** `ProfilePreferencesScreen` - UI chip-select + 4-slider sama seperti C3, tapi langsung ngedit `default_interest_category_ids`/`user_criteria_weights` (`GET/PUT /api/profile/preferences`).
**Tombol:** "Simpan", `LanguageToggle` (ID/EN), "Keluar" (logout, dialog konfirmasi).

---

## G. Admin (role-gated, app yang sama - tab tambahan cuma muncul kalau `role=admin`)

### G1. Dashboard Admin
**Tujuan:** Layar pendaratan tab Admin.
**Konten (`AdminDashboard`):** Kartu/chart - tempat paling di-wishlist, rata-rata rating in-app, volume trip, **daftar tempat belum ada `estimated_cost_idr`** (list actionable, tap → G4 form edit), **daftar tempat `category_tags_reviewed=false`** (list actionable, tap → G4), status sync terakhir (kapan Discovery/Enrichment terakhir jalan, berapa candidate pending).
**Tombol:** Quick link ke G2 (Candidates), G3 (List Places), G5 (Categories).
**Empty state:** Sebelum bootstrap pertama - "Belum ada data, mulai dari Discovery" + tombol langsung ke aksi trigger di G2.

### G2. Review Candidate Tempat
**Tujuan:** Gerbang Discovery → Enrichment (US11/US12).
**Tombol (atas):** "Cari Tempat Baru" (trigger `POST /api/admin/places/discover` - jalan di semua kombinasi area × kategori, tampilkan progress/toast begitu selesai).
**Konten:** List filterable (`CandidateReviewList`) berdasarkan `search_area` dan `status` (pending/approved/rejected). Tiap baris: nama, tipe dugaan, area, google_place_id.
**Tombol per baris:** "Approve" (memicu rangkaian lengkap Place Details + foto + enrichment Gemini, baris hilang dari pending), "Reject" (set `rejected`, dikecualikan dari re-insert Discovery selanjutnya).
**Aksi bulk:** Checkbox multi-select + Approve/Reject massal.

### G3. List Places (Admin)
**Tujuan:** Browse/search semua `places` yang live, titik masuk buat edit tempat manapun.
**Konten:** List searchable/filterable (per type, business_status, flag data yang kurang).
**Tombol:** Tap baris → G4, "+ Tambah Manual" (tempat bukan dari Google - buka G4 mode buat baru).

### G4. Form Edit Tempat (Admin)
**Tujuan:** CRUD buat field-field yang dimiliki admin di satu tempat.
**Field:** `estimated_cost_idr`, `estimated_visit_minutes`, `is_outdoor` (toggle), `category_tags` (multi-select dari `categories`, edit ini set `category_tags_reviewed=true`), `description_override`, `description_en`. Tampilan read-only field bersumber Google (nama, rating, alamat, dst) buat konteks.
**Tombol:** "Simpan", "Hapus" (cuma buat tempat `source=manual`), back.

### G5. List Categories (Admin)
**Tujuan:** Kelola taksonomi `categories`.
**Konten:** List kategori (name_id, name_en, slug).
**Tombol:** "+ Tambah Kategori" (buka G6), tap baris → G6 (edit), ikon hapus per baris (dialog konfirmasi, warning kalau masih dipakai).

### G6. Form Edit Category (Admin)
**Field:** name_id, name_en, slug (auto-suggest dari name_id, bisa diedit, validasi keunikan).
**Tombol:** "Simpan", "Batal".

### G7. Status Sync (Admin)
**Tujuan:** Visibilitas operasional - kapan Discovery/Enrichment terakhir jalan, kesadaran pemakaian kuota Google.
**Konten:** Timestamp Discovery terakhir + cakupan area/kategori, statistik batch Enrichment terakhir (jumlah approved, kegagalan), indikator pemakaian kuota API Google (perkiraan hitungan terhadap cap 1.000/bulan Enterprise) - nyambung ke bagian Observability di PRD.
**Tombol:** Link balik ke G2 buat aksi terhadap candidate pending.

---

## Tabel Ringkasan

| # | Layar | Bagian |
|---|--------|---------|
| A1 | Splash / Bahasa | Onboarding |
| A2 | Login | Onboarding |
| A3 | Daftar | Onboarding |
| A4 | Pilih Minat (gate) | Onboarding |
| B1 | Home | Jelajah |
| B2 | Detail Tempat | Jelajah |
| C1 | Trip Setup | Wizard |
| C2 | Susun Wishlist | Wizard |
| C2a | Pemilih Pin Manual | Wizard (dipakai bareng C4) |
| C3 | Minat + Slider (trip) | Wizard |
| C4 | Pilih Hotel | Wizard |
| C5 | Sedang Generate (loading) | Wizard |
| D1 | Hasil Itinerary | Manajemen Trip |
| D2 | Modal Swap | Manajemen Trip |
| D3 | List Trip Tersimpan | Manajemen Trip |
| D4 | Detail Cuaca (opsional) | Manajemen Trip |
| D5 | Form Review | Manajemen Trip |
| E1 | Peta Live | Trip Live |
| F1 | Profil | Akun |
| G1 | Dashboard Admin | Admin |
| G2 | Review Candidate | Admin |
| G3 | List Places | Admin |
| G4 | Form Edit Tempat | Admin |
| G5 | List Categories | Admin |
| G6 | Form Edit Category | Admin |
| G7 | Status Sync | Admin |

**19 layar user biasa (A1-F1) + 7 layar admin (G1-G7) = 26 layar berbeda.** C2a adalah satu layar reusable yang dipakai bareng buat alur tambah manual wishlist dan tambah manual hotel, bukan dibangun dua kali. D4 itu polish opsional - kalau tim kepepet waktu, kontennya bisa dilebur jadi tooltip di D1 saja tanpa layar penuh.
</content>
