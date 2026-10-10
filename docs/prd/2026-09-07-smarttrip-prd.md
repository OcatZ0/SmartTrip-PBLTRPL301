# SmartTrip Batam - Product Requirements Document

## 0. Metadata & Revision History

**Type:** Full PRD
**Status:** In progress — backend (`smarttrip-api`) and mobile (`smarttrip-mobile`) scaffolds exist with most F001-F024 implemented; see Sections 15 and 19
**Version:** 1.22
**Last Updated:** 2026-10-10
**Source of truth for implementation detail:** `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` (this PRD is a reformatted, audience-oriented view of the same decisions — where they ever conflict, the design spec wins, since it carries finer-grained rationale)

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-09-07 | Initial PRD generated from the design spec via `/prd-draft` |
| 1.1 | 2026-09-07 | Applied `/prd-analyze` findings: added Metadata, Entity Lifecycles, Glossary, Observability, Competitive Landscape, Decisions Log sections; expanded Acceptance Criteria to cover all 14 user stories; fixed untestable SLA criterion; added data model validation rules |
| 1.2 | 2026-09-07 | Replaced the unresearched Competitive Landscape placeholder with real research (Wanderlog, TripIt, the LLM-chat AI-planner category, and Atourin as the closest Indonesian comparable) |
| 1.3 | 2026-09-07 | Resolved hosting open question: Windows Server + PostgreSQL for both dev and deployment (overrides team's usual MySQL default) |
| 1.4 | 2026-09-07 | Decided Riverpod (team has no prior experience with either option); removed accessibility entirely per explicit instruction - not pursuing it this project |
| 1.5 | 2026-09-11 | Added weather forecast + swap suggestion feature (US15), sourced real ToS text for the scraping-avoidance rationale (TripAdvisor, Traveloka confirmed with exact quotes; Tiket.com could not be independently verified) |
| 1.6 | 2026-09-11 | Confirmed Open-Meteo over Google Weather API after cost/architecture comparison; fixed stale design-spec section cross-references left over from the weather-section renumbering |
| 1.7 | 2026-09-11 | Reverted admin from Flutter role-gated screens back to a separate web panel (Blade + Bootstrap) - removed /api/admin/* from the API surface, removed Flutter admin components, updated tech stack/file structure/personas/rollout accordingly |
| 1.8 | 2026-09-17 | Hosting changed to Linux + PostgreSQL (client decision, overrides 1.3); added automatic push/local notification when the weather forecast window opens (US15), on top of the existing per-screen-open check |
| 1.9 | 2026-09-22 | Merged `place_attributes` back into `places` (one table); overwrite protection on Google re-sync moved from schema separation to a code-level whitelist-update discipline in the sync job |
| 1.10 | 2026-09-22 | Data model audit findings applied: JSON-array category tags replaced with pivot tables (`place_category`, `trip_interest_category`, `user_default_interest_category`) with FK RESTRICT; EAV-style `*_criteria_weights` tables replaced with fixed `weight_*` columns on `users`/`trips`; added `deleted_at` soft delete to `places`/`users`/`trips`/`place_reviews`/`categories`; added `UNIQUE(user_id, place_id)` on `place_reviews`; added CHECK constraint requiring at least one auth method on `users`; clarified `topsis_score` is NULL (not fabricated) for manually-swapped-in items |
| 1.11 | 2026-09-22 | Added admin audit trail: `activity_log` table via `spatie/laravel-activitylog`, `LogsActivity` trait on `Place`/`Category` models, "Riwayat Perubahan" change-history tab in admin panel - answers "who changed this place's price/category, and when" (previously an explicitly-deferred known gap) |
| 1.12 | 2026-09-22 | Renamed every primary key from generic `id` to explicit `{table_name}_id` (`places_id`, `users_id`, etc.) and updated all foreign keys to match, so a column name is self-describing outside JOIN context; `google_place_id`/`google_id` (external Google IDs) and `activity_log`'s package-owned `id`/`subject_id`/`causer_id` deliberately excluded |
| 1.13 | 2026-09-22 | Removed `places.google_maps_uri` (built on the fly from lat/lng instead, avoids staleness after coordinate corrections); added `places.kecamatan` (copied from `place_candidates.search_area` at promotion, admin-editable, powers a new browse filter); added `trip_wishlist_places.custom_visit_minutes` (fixes a real gap - custom map-pin wishlist items had no `places` row to source `estimated_visit_minutes` from for the day time-budget calculation, so the user now enters it manually) |
| 1.14 | 2026-09-22 | Fixed stale admin-architecture references left over from the 2026-09-11 reversal (web panel, not Flutter role-gated): corrected the Section 1 AI Build Summary and the Section 5 Out of Scope bullet, both of which still described the old Flutter-role-gated admin design |
| 1.15 | 2026-09-23 | Added US16, read-only trip sharing (`trip_viewers` table, invite/revoke by email, "Dibagikan ke Saya" tab) - a rework of the earlier out-of-scope call, not deferred future work; new design spec Section 9 pushed Weather/API/Mobile Flow/Admin Panel/Testing/Out of Scope sections down by 1 (all cross-references updated in both documents) |
| 1.16 | 2026-09-23 | Added US17, anonymous public "Share Itinerary" link (`trips.share_token`, `GET /api/shared-itinerary/{share_token}`) - a standalone mechanism unrelated to US16's Trip Viewer, explicitly no login/account; strict response whitelist excludes `visited_at`/owner identity/`budget_total` per explicit "no privacy leak" requirement; also added link-based invite (`viewer_invite_token`) as a second way into US16's `trip_viewers`, alongside the existing email search; new design spec Section 10 pushed Weather/API/Mobile Flow/Admin Panel/Testing/Out of Scope sections down by 1 again (all cross-references updated in both documents) |
| 1.17 | 2026-09-28 | Added Section 7.1 Kebutuhan Fungsional (F001-F024), a flat functional-requirement checklist cross-referenced to the existing User Stories (Section 7) - requested as a standalone functional-requirements view for documentation/reporting purposes, no scope change |
| 1.18 | 2026-10-02 | PRD review pass: (1) fixed Section 5 Technical Constraints, which still said the Flutter codebase was shared "for end-users and admins" - contradicted Section 8/9/Decisions Log; (2) documented the actual registration/password flow found in `smarttrip-api` - `pending_registrations` staging table, email-verification link, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`, `PUT /api/auth/password`, none of which were in the data model or API surface before; (3) resolved the duplicate/out-of-order "1.7" entries in this table (see old 1.3-1.8 above) by renumbering chronologically - no version before this one changes meaning, only its label; (4) reworded Section 20 to stop calling the (already-Resolved) hosting decision an "open question"; (5) added `trip_viewers`/`share_token` lifecycle to Section 12; (6) updated Status/Section 15 from "pre-implementation"/"not yet scaffolded" to reflect that implementation has started |
| 1.19 | 2026-10-04 | Synced docs with the implemented backend: documented that UNIQUE constraints on soft-deletable tables must be partial indexes (`WHERE deleted_at IS NULL`) where the value must be reusable after soft delete - `place_reviews (users_id, places_id)` and `categories.slug` (both already fixed by corrective migrations in `smarttrip-api`), `places.google_place_id` kept plain unique on purpose, `users.email`/`users.google_id` flagged as an open decision; F015 wording restored to cover both invite-by-email and invite link, matching `TripViewerController` |
| 1.20 | 2026-10-04 | Resolved the `users.email`/`users.google_id` open decision from 1.19: partial unique index (`WHERE deleted_at IS NULL`) so a deactivated account's email can be re-registered; migration and the account-deactivation feature itself are not implemented yet |
| 1.21 | 2026-10-04 | Implemented the 1.20 decision in `smarttrip-api`: migration converting `users.email`/`users.google_id` to partial unique indexes (`WHERE deleted_at IS NULL`) plus 3 `AuthTest` cases; full backend suite green (273 tests) |
| 1.22 | 2026-10-10 | PRD audit (data model + consistency), fixes applied in docs AND `smarttrip-api`: (1) `ON DELETE RESTRICT` never protected soft-deleted categories (soft delete is an UPDATE), so `CategoryController::destroy` now refuses a category still referenced by `place_category`/`trip_interest_category`/`user_default_interest_category`; (2) trip-history relations (`itinerary_items.places_id`, `itinerary_days.start/end_places_id`, `trips.hotel_places_id`, `trip_wishlist_places.places_id`) now use `withTrashed()` so a soft-deleted place no longer vanishes from existing itineraries, while generate/swap/catalog still exclude it; (3) documented `itinerary_days.start/end_places_id` as nullable (migration `2026_09_29_071806`, custom-pin hotel) and `places.rating` as nullable with a new 3-tier rating fallback (`PlaceRatingEstimator`: blend, median of same type, neutral 3.5) replacing the old silent `?? 0.0`; (4) added `PATCH /api/trips/{id}` (owner-only edit; changing `num_days`/`budget_total`/daily times clears the existing itinerary, client calls generate again); (5) added DB uniques `trip_wishlist_places(trips_id, places_id)`, `itinerary_days(trips_id, day_number)`, `itinerary_items(itinerary_days_id, places_id)`, `place_photos(places_id, sort_order)` (migration `2026_10_10_000000`); (6) documented FK `ON DELETE` policy per table, framework-owned tables (`personal_access_tokens`, `password_reset_tokens`, `sessions`), the `activity_log.attribute_changes` column, review orphaning on regenerate, and `GET /api/user` + web reset-password routes; (7) consistency fixes: duplicate `users.email`/`google_id` validation rows removed, Section 9 component table un-split and its admin cross-reference corrected to Section 8, Figma link added, Section 15 file structure updated to what exists, sync status noted as part of the Dashboard. Backend suite 290 tests green |

---

## 1. Overview

**Feature / Project Name:** SmartTrip Batam - Sistem Rekomendasi Itinerary Liburan Berbasis Preferensi Pengguna

**Problem Statement:**
Wisatawan Batam kesulitan menentukan destinasi wisata dan kuliner yang sesuai dengan minat, lokasi, waktu, dan anggaran mereka, karena informasi tersebar di berbagai platform dan butuh usaha untuk membandingkan. Banyak wisatawan tidak punya perencanaan terstruktur, sehingga rute perjalanan jadi tidak efisien dan destinasi menarik terlewatkan.

*(No formal user research or usage data backs this statement — it's a reasoned problem framing appropriate for a college project's scope, not a data-backed claim. Flagged here rather than silently presented as evidence-based.)*

**Proposed Solution:**
Aplikasi mobile yang merekomendasikan tempat wisata/kuliner/hotel sesuai preferensi pengguna (minat, jarak, anggaran, rating) memakai Weighted-TOPSIS, lalu otomatis menyusun jadwal perjalanan multi-hari dengan pengelompokan lokasi (K-Means) dan urutan rute (Nearest-Neighbor + Google Routes API), termasuk pelacakan progres kunjungan secara live.

**AI Build Summary:**
> Build a Laravel 12 REST API backend + Flutter mobile app for end users, plus a separate Laravel Blade/Bootstrap web admin panel (session-based auth, not part of the Flutter app) for a Batam trip-itinerary recommender. Mobile auth via Laravel Sanctum (opaque tokens) with email/password and Google Sign-In. Core algorithm pipeline: user-weighted TOPSIS scoring (4 criteria: category-fit via Jaccard similarity, distance via Haversine, budget via a 4-tier fallback chain, rating via a Bayesian Google+in-app blend) → K-Means day clustering → Nearest-Neighbor route ordering → Google Routes API for real road polylines. Place data sourced exclusively from Google Places API (New) via an admin-reviewed two-phase Discovery/Enrichment pipeline (never scraped from other platforms), enriched by Gemini (free tier) for translation, category tagging, and visit-duration estimation. Live trip map with GPS-geofencing-based visit tracking, plus read-only trip sharing so an invited user can view (never edit) someone else's trip. No booking/payment, no multi-city, no multi-editor collaboration, one-semester scope for a 6-person student team.

---

## 2. Competitive Landscape

*(Researched 2026-09-07, replacing the earlier unresearched placeholder — kept intentionally light, proportionate to a college project, but now backed by actual findings rather than assertion.)*

**Global AI/planning trip apps:**
- **Wanderlog** — the strongest "planning canvas" competitor: users manually save places, arrange them on a map, and get basic route optimization ("stops grouped by location to avoid zig-zagging"). This is drag-and-drop assisted planning, not algorithmic personalization — the user still builds the schedule by hand. Freemium, ~$40/year for premium (offline access, email import).
- **TripIt** — organizes bookings you've already made (parses confirmation emails into a timeline). Not a recommender or planner at all; solves a different problem (post-booking organization).
- **Mindtrip, Ribbit, Wonderplan, Layla, GuideGeek, MonkeyTravel** — the broader "AI trip planner" category, and all of them generate itineraries via **LLM chat conversation**, not a weighted multi-criteria algorithm. This means their output quality depends on prompt interpretation and isn't reproducible or explainable the way a scored ranking is.
- **None of the researched apps support live GPS-based tracking of visited stops during the actual trip.** This was checked specifically since it's one of SmartTrip's features — genuinely unaddressed in this category, not just an assumption.

**Indonesian market — the closest real comparable:**
- **Atourin** (est. 2019) — covers 200 regions across Indonesia, 3,000+ attractions, 600+ itineraries, with an "Itinerary Creator" that auto-calculates cost and travel time between stops. However, its core value is **browsing/adapting pre-made, community-contributed itineraries** rather than generating a new one from an individual's specific weighted preferences (budget/interest/rating/distance) — no comparable scoring algorithm was found. It's also national in scope, not Batam-specific.
- **Traveloka / Tiket.com** — Indonesian OTAs, focused on booking (flights, hotels, tickets), not itinerary structure or planning at all.

**SmartTrip's differentiation, now backed by this research rather than just asserted:**
1. A defensible, explainable weighted-scoring algorithm (TOPSIS over 4 explicit criteria) generating a full schedule automatically — distinct from both Wanderlog's manual canvas and the LLM-chat category's less predictable output.
2. Live GPS-geofencing visit tracking during the actual trip — not found in any researched competitor, global or Indonesian.
3. Batam-specific curation (admin-reviewed Google Places data, ~300-500 places) versus Atourin's broad-but-shallow national coverage — a deliberate depth-over-breadth bet for one city.

Sources: [Best AI Trip Planner Apps 2026 (Lindy)](https://www.lindy.ai/blog/trip-planner-app), [Atourin Itinerary Creator](https://blog.atourin.com/news/itinerary-creator-atourin/), [Aplikasi Wisata Atourin](https://blog.atourin.com/news/aplikasi-wisata-atourin/)

---

## 3. Goals & Success Metrics

**Primary Goal:** Ship a working, demonstrable end-to-end app (not just a design) within one semester that a 6-person team can build, covering the full loop from admin data curation through personalized itinerary generation to live in-trip tracking.

**Success Metrics** *(proxies appropriate for a pre-launch student project, not live-usage metrics — adjust if you have specific skripsi/demo-day targets)*:
- A generated itinerary for a realistic Batam trip (3-5 days, real preferences) completes end-to-end (weights → TOPSIS → K-Means → NN → Routes API) in a single demo run without manual intervention
- The initial place-data bootstrap (Discovery → admin review → Enrichment) reaches the ~300-500 place target while staying inside Google's free API tiers (Pro 5,000/mo, Enterprise 1,000/mo)
- Core algorithm units (weight normalization, TOPSIS scoring, Haversine, K-Means, Bayesian rating blend) pass deterministic unit tests, since this is the part most likely to be questioned in a demo/defense
- Live map + geofencing visit-tracking demonstrably works on at least one real Android device outdoors (not just emulator)

**Anti-goals** *(explicitly NOT trying to do — see Section 5 for the full list)*:
- Not trying to support booking/payment/reservation
- Not trying to support more than one city this semester
- Not trying to achieve Play Store publish-readiness (background location permission justification/privacy policy work is out of scope)

---

## 4. Target Users & Personas

*(Kept intentionally light — proportionate to a college project scope, not a market-research-backed persona set.)*

- **Wisatawan (primary user)** — a tourist visiting Batam who wants a personalized, low-effort trip plan. May be domestic or, given Batam's proximity to Singapore/Malaysia, international (hence the bilingual ID/EN UI). No account required to browse; account required to plan.
- **Admin (secondary user, separate web panel, not the mobile app)** — a team member (or eventually, someone maintaining the app) responsible for curating place data quality: reviewing Discovery candidates, filling in missing price/category data, monitoring the dashboard. Never opens the Flutter app at all — works entirely through the web panel.

---

## 5. Scope & Constraints

**In scope:** everything in the accompanying design spec — trip creation, wishlist, preference sliders + minat selection, hotel resolution (search or custom pin), TOPSIS/K-Means/NN/Routes generation pipeline, swap, live map with geofencing, read-only trip sharing to other users (added 2026-09-23), anonymous public itinerary share links (added 2026-09-23), weather forecast + swap suggestion, in-app reviews, profile preference defaults, mandatory onboarding, Google Sign-In, and the full admin data-curation loop (Discovery → review → Enrichment → AI tagging/translation → ongoing curation).

**Out of scope** (see design spec Section 16 for full detail):
- Booking/reservation/payment of any kind
- Multi-city support (no `city` field anywhere; Batam-only, hardcoded area list)
- Admin functionality inside the Flutter mobile app (admin is a separate web panel — see Section 8/14)
- Scraping any platform besides Google Places (TripAdvisor/Traveloka/Tiket.com explicitly rejected — ToS/legal risk)
- True pairwise AHP (replaced with simpler direct-rating sliders feeding the same TOPSIS scoring)
- Multi-editor trip collaboration, in-app comments/discussion, real-time conflict resolution — **read-only trip sharing IS in scope** (single owner + read-only viewers, added 2026-09-23, see US16/Section 9); true co-editing is not, since TOPSIS scoring is designed around one owner's preference weights, not a merged multi-user preference
- Automatic re-routing when a user deviates from the planned route
- Play Store/App Store publish readiness
- Per-day time windows (single trip-wide `daily_start_time`/`daily_end_time` only)
- Mid-trip hotel changes (one hotel = one trip's start/end point)

**Technical constraints:**
- Platform: **Android/iOS via Flutter** for the end-user mobile app only - admin uses a separate web panel (Laravel Blade + Bootstrap, see Section 8), not the Flutter codebase
- Auth: Laravel Sanctum (opaque bearer tokens), email/password + Google Sign-In, account linking by email
- Offline support: **partial only** — visit-tracking events queue locally and retry when connectivity returns; no general offline browsing/generation support was designed
- Performance: no hard SLA (see Section 16, US4) — Google Routes API is called once per day per generate/swap (not per view) specifically to keep this fast and cheap
- Data residency/compliance: none specified (not a concern raised for this project)
- Budget-hard constraint: Google Places Enterprise SKU capped at 1,000 free calls/month — directly shaped the two-phase Discovery/Enrichment architecture

---

## 6. Jobs to Be Done (JTBD)

| Priority | Job Statement |
|----------|---------------|
| 1 | When I'm planning a trip to Batam without local knowledge, I want a personalized day-by-day itinerary based on my interests, budget, and available time, so I can spend my trip enjoying it instead of researching it. |
| 2 | When I'm actually out on my trip, I want to see my planned route and know what I've already visited, so I don't get lost or lose track of my schedule. |
| 3 | When I already have specific places I want to visit (that I found elsewhere), I want to add them to my plan and have the system build the rest of the schedule around them, so I don't lose the personal research I already did. |
| 4 | When I'm the team managing the app's place data, I want a controlled way to bring new places into the system without blowing our API budget, so the recommendation quality stays high without unsustainable cost. |
| 5 | When my trip is coming up soon and rain is forecast, I want to know before I'm standing at an outdoor spot in a downpour, so I can swap to an indoor alternative ahead of time instead of during. |
| 6 | When I've planned a trip, I want family or friends to see my itinerary and live progress without being able to change anything, so they can follow along without me worrying they'll accidentally edit my plan. |
| 7 | When I'm proud of a trip plan I built, I want to send it to anyone — even someone who doesn't use this app — so they can see what I've planned without needing to sign up for anything. |

---

## 7. User Stories

| ID | Role | Action | Benefit | JTBD Ref |
|-----|------|--------|---------|----------|
| US1 | Wisatawan | pilih minat, atur bobot preferensi (kategori/jarak/anggaran/rating) | dapat rekomendasi tempat yang benar-benar sesuai selera saya | J1 |
| US2 | Wisatawan | atur jumlah hari, anggaran, dan tanggal trip | dapat jadwal yang realistis sesuai kondisi trip saya | J1 |
| US3 | Wisatawan | tambahkan tempat favorit ke wishlist sebelum generate | tempat yang sudah saya rencanakan sendiri tetap masuk itinerary | J3 |
| US4 | Wisatawan | generate itinerary otomatis | tidak perlu susun jadwal manual dari nol | J1 |
| US5 | Wisatawan | ganti satu tempat di itinerary tanpa mengubah yang lain | fleksibel kalau berubah pikiran, tanpa harus generate ulang semuanya | J1 |
| US6 | Wisatawan | buka peta live saat trip berjalan | tahu rute dan progres kunjungan hari itu | J2 |
| US7 | Wisatawan | tandai kunjungan manual kalau geofence tidak akurat | tetap bisa lacak progres walau deteksi otomatis gagal | J2 |
| US8 | Wisatawan | simpan preferensi default di profil | tidak perlu isi ulang minat/bobot tiap bikin trip baru | J1 |
| US9 | Wisatawan | login pakai Google | daftar/masuk lebih cepat tanpa isi form manual | - |
| US10 | Wisatawan | beri rating/review tempat kapan saja | bagikan pengalaman saya dan bantu rekomendasi jadi lebih akurat | - |
| US11 | Admin | trigger discovery tempat baru per area/kategori | temukan kandidat tempat baru dari Google tanpa buang kuota mahal | J4 |
| US12 | Admin | review dan approve/reject kandidat tempat | kontrol kualitas data sebelum masuk sistem rekomendasi | J4 |
| US13 | Admin | lengkapi estimasi harga/kategori yang belum lengkap | kriteria TOPSIS makin akurat seiring waktu | J4 |
| US14 | Admin | lihat dashboard tempat yang butuh perhatian (harga kosong, tag belum direview) | tahu prioritas kerja tanpa harus cek manual satu-satu | J4 |
| US15 | Wisatawan | lihat forecast cuaca per hari, dapat saran swap kalau hari itu ada stop outdoor + prediksi hujan | tidak kaget kehujanan di tempat outdoor, bisa antisipasi dari awal | J5 |
| US16 | Wisatawan | bagikan trip ke user lain sebagai viewer read-only, by email atau link undangan | keluarga/teman bisa lihat itinerary dan progres saya tanpa bisa mengubah apapun | J6 |
| US17 | Wisatawan | bagikan link publik itinerary yang sudah digenerate ke siapa saja | orang yang belum tentu pakai SmartTrip tetap bisa lihat rencana trip saya | J7 |

---

### 7.1 Kebutuhan Fungsional

Daftar flat kebutuhan fungsional (functional requirements), disilangrujuk ke User Story terkait di atas. Ini adalah reformat dari Section 7 untuk kebutuhan pelaporan/dokumentasi, bukan penambahan scope baru.

| ID | Kebutuhan Fungsional | US Ref |
|-----|------------------------|--------|
| F001 | Wisatawan dapat melakukan registrasi akun | - |
| F002 | Pengguna dapat melakukan autentikasi menggunakan akun Google maupun akun sistem | US9 |
| F003 | Pengguna dapat logout dari sistem | - |
| F004 | Wisatawan dapat mengubah kata sandi | - |
| F005 | Wisatawan dapat melihat katalog tempat wisata | US3 |
| F006 | Wisatawan dapat melihat detail tempat wisata | US3 |
| F007 | Wisatawan dapat mengatur wishlist tempat wisata | US3 |
| F008 | Sistem dapat membuat itinerary otomatis sesuai dengan masukan dan preferensi wisatawan | US1, US2, US4 |
| F009 | Wisatawan dapat mengelola preferensi wisata | US1, US8 |
| F010 | Wisatawan dapat mengganti satu tempat dengan tempat lainnya setelah itinerary dibuat | US5 |
| F011 | Wisatawan dapat mengelola trip yang pernah dibuat | US2 |
| F012 | Sistem dapat mengirim notifikasi saat pengguna mendekati lokasi tempat wisata | US6 |
| F013 | Wisatawan dapat melihat peta live dan melacak progres kunjungan tempat wisata secara real-time | US6, US7 |
| F014 | Wisatawan dapat mengelola ulasan tempat wisata | US10 |
| F015 | Wisatawan dapat membagikan trip ke pengguna lain sebagai viewer read-only, melalui pencarian email atau tautan undangan | US16 |
| F016 | Wisatawan dapat melihat trip yang dibagikan pengguna lain kepadanya | US16 |
| F017 | Wisatawan dapat membagikan itinerary trip melalui tautan publik tanpa memerlukan akun | US17 |
| F018 | Sistem dapat mengambil data tempat wisata melalui Google Places API | US11 |
| F019 | Admin dapat meninjau kandidat tempat wisata baru sebelum masuk ke sistem rekomendasi | US12 |
| F020 | Sistem dapat melakukan pengisian data otomatis pada tempat wisata menggunakan Gemini AI | US13 |
| F021 | Admin dapat mengelola data tempat wisata | US13 |
| F022 | Admin dapat mengelola kategori tempat wisata | US13 |
| F023 | Admin dapat melihat riwayat perubahan pada data tempat dan kategori | - |
| F024 | Sistem dapat menampilkan status sinkronisasi dan pemakaian kuota Google API | US14 |

---

## 8. Proposed Experience

**Design Direction:**
Terasa seperti aplikasi e-commerce untuk browsing tempat (grid/list, filter, infinite scroll) yang berujung ke wizard singkat (trip setup → wishlist → minat/preferensi → hotel) lalu hasil akhirnya terasa seperti Google Maps navigasi (pin bernomor, rute berwarna, progres live) tapi untuk keseluruhan trip multi-hari, bukan satu perjalanan mobil.

**Key Screens / States:**
- Onboarding Pilih Minat (gate wajib, kondisi-based, min 1 kategori) — [id/en] title
- Home / katalog tempat (browse tanpa login)
- Trip setup (num_days, budget, tanggal, jam, toggle hotel)
- Wishlist (katalog + custom pin di peta)
- Pilih minat + slider bobot (trip-level, pre-filled dari profil)
- Pilihan hotel (search/pin, atau top-3 TOPSIS)
- Loading/generate
- Hasil itinerary (kartu per hari)
- Detail tempat (foto carousel, deskripsi bilingual, rating blend)
- Live map per hari (gray/blue polyline, geofencing)
- Swap modal (ranked alternatives / manual search)
- Profil (default preferensi, bahasa)
- List trip tersimpan
- Empty state: katalog kosong (belum ada data tersinkron), wishlist kosong, trip list kosong
- Error state: generate gagal (pool kandidat tidak cukup → flag "tidak muat"/"padat"), geofence permission ditolak (fallback manual), offline saat visit-tracking (antri lokal)
- Loading state: skeleton/spinner saat generate (proses multi-tahap: TOPSIS → K-Means → NN → Routes API)

**Interaction Model:**
- Primary flow: Section 12 of design spec (numbered end-to-end)
- Long-press pin di peta = tandai/batalkan kunjungan manual
- Tap "+wishlist" di kartu katalog = tambah tanpa keluar dari browsing (tidak ada modal blocking)

**Figma / Design Link:** [Mockup](https://www.figma.com/design/W2WWAl1Oj1M7hbbZACI4i8/Mockup) (file key `W2WWAl1Oj1M7hbbZACI4i8`, added 2026-10-10; A2 Masuk = node `122:180`, A3 Daftar = node `122:267`, both implemented in `smarttrip-mobile`). The design spec and this PRD remain the text source of truth for behaviour; Figma only covers visual layout

**Admin Panel (separate web app, not part of the Flutter screens above):**
*(Reversed 2026-09-11 — admin was briefly role-gated inside the Flutter app, moved back to a standalone web panel.)*
Laravel Blade + Bootstrap, its own login (`/admin/login`, session-based, not the Sanctum tokens the Flutter app uses), controllers hit Eloquent models directly rather than calling the mobile REST API. Pages: Dashboard (stats + "needs attention" lists — missing price data, unreviewed category tags, last sync status), Candidate Review (trigger Discovery, filter/approve/reject `place_candidates`, bulk actions), Places list (filterable by kecamatan, added 2026-09-22) + edit form (admin-owned fields: estimated cost, description overrides, is_outdoor, category tags, kecamatan, manual add) with a "Riwayat Perubahan" change-history tab (reads `activity_log`, added 2026-09-22), Categories list + edit form (same change-history tab), and sync status (quota usage, last run stats) shown as cards on the Dashboard itself, not a separate page (clarified 2026-10-10; F024 is satisfied by the Dashboard). Admin never installs or opens the mobile app.

---

## 9. Component Inventory

| Component | Type | Description | Linked Stories |
|-----------|------|--------------|------------------|
| CategoryChipSelector | Form | Multi-select minat categories | US1, US8 |
| CriteriaSliderGroup | Form | 4 sliders 0-10 (kategori/jarak/anggaran/rating) | US1, US8 |
| PlaceCatalogGrid | Display | Infinite-scroll place browsing with category filter | US3 |
| PlaceCard | Display | Thumbnail, name, rating, badge (wishlist/recommended) | US3, US4 |
| WishlistButton | Action | Toggle add/remove place to trip wishlist | US3 |
| MapPinPicker | Form | Tap/drag pin on `google_maps_flutter` for custom locations + name; wishlist custom pins also require a manual estimated-visit-duration input (added 2026-09-22 — see US3) | US3 (hotel/wishlist custom pin) |
| HotelSearchOrPin | Form | Search catalog or fallback to map pin | US2 |
| TripSetupForm | Form | num_days, budget, dates, time window, hotel toggle | US2 |
| ItineraryDayCard | Display | One day's stops with source badges | US4 |
| SwapModal | Modal | Ranked alternatives or manual search for one stop | US5 |
| LiveMapView | Display | `google_maps_flutter` with markers, colored polylines, live location | US6 |
| GeofenceStatusIndicator | Display | Visual feedback that tracking is active | US6, US7 |
| ManualVisitToggle | Action | Long-press/button to mark/unmark visited | US7 |
| ReviewForm | Form | Rating + comment, optionally linked to visited itinerary_item | US10 |
| GoogleSignInButton | Action | Triggers `google_sign_in` package flow | US9 |
| ProfilePreferencesScreen | Form | Edit default minat + weights | US8 |
| LanguageToggle | Action | ID/EN switch, settings | - |

| WeatherForecastCard | Display | Per-day forecast summary, shown once trip is within ~7 days | US15 |
| WeatherSwapBadge | Action | Rain-warning badge on a day with outdoor stops, opens SwapModal on tap | US15 |
| ShareTripButton | Action | Opens the "Bagikan Trip" screen from a trip's detail page (owner only, added 2026-09-23) | US16, US17 |
| ViewerList | Display | List of invited viewers on a trip (by email or link), with a revoke-access action per row (owner only) | US16 |
| ViewerInviteLinkTile | Action | Generate/reset `viewer_invite_token`, share via OS share sheet — the link-based alternative to email search (added 2026-09-23) | US16 |
| SharedTripsTab | Display | Separate tab listing trips shared to the current user (`GET /api/trips/shared`), distinct from "Trip Saya" | US16 |
| ReadOnlyModeBanner | Display | Persistent indicator when viewing someone else's trip; action buttons (swap/generate/delete/visit) hidden in this mode | US16 |
| ShareItineraryTile | Action | Generate/reset `share_token` and hand the public link to the OS share sheet — a distinct, unrelated section of the same "Bagikan Trip" screen (anonymous, no account, added 2026-09-23) | US17 |
| SharedItineraryReadOnlyScreen | Display | Renders the anonymous public itinerary from `GET /api/shared-itinerary/{share_token}` — no login, nothing saved locally about the viewer | US17 |

**Admin (US11-US14) is not built as Flutter components at all** — it's a separate web panel (Blade views + Bootstrap, standard HTML forms/tables, not part of this Flutter component tree). See Section 8 (Admin Panel) for its page list instead of this table.

---

## 10. Data Models

Backend is Laravel/Eloquent (not TypeScript) — schema shown as field lists per the design spec's Data Model section (full authoritative version there; summarized here for cross-reference):

```
places(places_id, google_place_id?, name, type[attraction|culinary|lodging], lat, lng, address,
  kecamatan?, price_level?, rating?, review_count, opening_hours[json], photo_url?, description?,
  phone?, website?, business_status[operational|closed_temporarily|closed_permanently],
  types[json], source[google|manual],
  category_tags_reviewed[bool], estimated_visit_minutes,
  is_outdoor[bool], estimated_cost_idr?, description_override?, description_en?,
  timestamps, deleted_at?[soft delete])
  -- digabung dari places + place_attributes (revisi 2026-09-22); kolom kurasi admin
  -- (category_tags_reviewed..description_en, kecamatan) WAJIB diproteksi lewat whitelist-update di kode saat
  -- re-sync dari Google, bukan lewat pemisahan tabel lagi -- lihat design spec Section 4
  -- kategori sekarang lewat pivot place_category (lihat bawah), bukan kolom json lagi
  -- PK/FK renamed to {table}_id convention (revisi 2026-09-22, see note below) -- google_place_id
  -- is Google's own external ID, not a reference to our places_id, so it kept its name
  -- kecamatan added 2026-09-22: copied from place_candidates.search_area at promotion, admin-editable,
  -- powers GET /api/places?kecamatan= filter -- zero extra API cost, data already collected by Discovery
  -- google_maps_uri REMOVED 2026-09-22: not stored -- built on the fly from lat/lng (or google_place_id)
  -- instead, so it never goes stale if an admin later corrects the coordinates
  -- rating is NULLABLE (documented 2026-10-10): source=manual places have no Google rating, so the TOPSIS
  -- rating criterion uses a 3-tier fallback (PlaceRatingEstimator): Bayesian blend if any rating exists,
  -- else the median blend of the same `type` in the candidate pool, else a neutral 3.5 (mirrors the
  -- 4-tier budget fallback; previously an undocumented `?? 0.0` punished every unrated manual place)

categories(categories_id, name_id, name_en, slug[unique, partial WHERE deleted_at IS NULL], timestamps, deleted_at?[soft delete])
  -- delete diproteksi ON DELETE RESTRICT dari 3 tabel pivot di bawah
  -- name_id/name_en are language-code suffixes (Indonesian/English label), unrelated to the id/FK convention

place_category(places_id FK, categories_id FK[ON DELETE RESTRICT], unique[places_id, categories_id])
  -- revisi 2026-09-22, ganti places.category_tags json array - pivot standar, FK beneran

trip_interest_category(trips_id FK, categories_id FK[ON DELETE RESTRICT], unique[trips_id, categories_id])
  -- revisi 2026-09-22, ganti trips.interest_category_ids json array

user_default_interest_category(users_id FK, categories_id FK[ON DELETE RESTRICT], unique[users_id, categories_id])
  -- revisi 2026-09-22, ganti users.default_interest_category_ids json array

place_candidates(place_candidates_id, google_place_id[unique], name, type, lat, lng, search_area,
  status[pending|approved|rejected], timestamps)

place_photos(place_photos_id, places_id FK, photo_url, sort_order, unique[places_id, sort_order])

place_reviews(place_reviews_id, places_id FK, users_id FK, rating[1-5], comment?, itinerary_items_id? FK,
  unique[users_id, places_id; partial WHERE deleted_at IS NULL], timestamps, deleted_at?[soft delete])
  -- unique constraint revisi 2026-09-22: 1 user cuma boleh 1 review per tempat,
  -- review ulang = edit yang sudah ada, bukan baris baru (jaga integritas Bayesian blend)

users(users_id, name, email[unique, partial WHERE deleted_at IS NULL], password?, email_verified_at?,
  remember_token?, google_id?[unique, partial WHERE deleted_at IS NULL], role[user|admin],
  default_weight_kategori/jarak/anggaran/rating?[decimal], timestamps, deleted_at?[soft delete])
  -- CHECK constraint revisi 2026-09-22: password IS NOT NULL OR google_id IS NOT NULL
  -- default_weight_kategori/jarak/anggaran/rating[decimal, nullable] - revisi 2026-09-22,
  -- ganti tabel EAV user_criteria_weights (4 kriteria fixed, tidak butuh bentuk EAV)
  -- google_id is Google's own external ID, not a reference to our users_id, so it kept its name
  -- email_verified_at ditambahkan 2026-10-02 (ditemukan dari kode, belum pernah didokumentasikan) -
  -- diisi oleh alur verifikasi registrasi di bawah, atau langsung oleh Google Sign-In (identitas sudah
  -- terbukti dari provider)

pending_registrations(email[unique], name, password[hash], token[hash], created_at)
  -- ditambahkan 2026-10-02 (ditemukan dari kode, belum pernah didokumentasikan sama sekali)
  -- staging area registrasi manual - baris `users` BELUM dibuat saat form daftar disubmit
  -- POST /api/auth/register simpan ke sini + kirim email berisi signed URL verifikasi (berlaku 60 menit),
  -- baris `users` baru dibuat/diupdate begitu link diklik (lihat verify-registration di Section 11)
  -- kalau email itu sudah dipakai akun Google-only (password masih null), verifikasi MENAUTKAN password
  -- baru ke akun itu - bukan bikin akun baru - karena kepemilikan inbox sudah dibuktikan
  -- baris di sini dihapus begitu verifikasi sukses ATAU kedaluwarsa (>60 menit, link lama invalid)

trips(trips_id, users_id FK, title, num_days, budget_total, has_own_hotel[bool], hotel_places_id? FK,
  hotel_custom_name?, hotel_lat?, hotel_lng?, start_date,
  daily_start_time, daily_end_time, viewer_invite_token?[unique], share_token?[unique],
  timestamps, deleted_at?[soft delete])
  -- weight_kategori/jarak/anggaran/rating[decimal] - revisi 2026-09-22, ganti tabel EAV
  -- trip_criteria_weights (snapshot bobot 4 kriteria buat trip ini)
  -- minat trip ini lewat pivot trip_interest_category, bukan kolom json lagi
  -- viewer_invite_token added 2026-09-23 -- link-based alternative to email search for trip_viewers (US16)
  -- share_token added 2026-09-23 -- UNRELATED to viewer_invite_token, powers the anonymous public
  -- itinerary link (US17, design spec Section 10) -- do not conflate the two, different auth models

trip_wishlist_places(trip_wishlist_places_id, trips_id FK, places_id? FK,
  custom_name?, custom_lat?, custom_lng?, custom_visit_minutes?[integer],
  unique[trips_id, places_id], CHECK(places_id IS NOT NULL OR (custom_name, custom_lat, custom_lng, custom_visit_minutes all NOT NULL)))
  -- unique added 2026-10-10 (US3 "adding twice is a no-op" was only firstOrCreate before); the CHECK existed
  -- since the first migration but was never documented here
  -- custom_* only populated when places_id is null (map-pin addition not in the catalog)
  -- custom_visit_minutes added 2026-09-22: a custom pin has no places row, so no estimated_visit_minutes
  -- to draw from for the day time-budget math (Section 7 step 6b) -- user enters it manually when pinning,
  -- required on this path specifically (catalog picks use places.estimated_visit_minutes instead)

itinerary_days(itinerary_days_id, trips_id FK, day_number, start_places_id? FK, end_places_id? FK, unique[trips_id, day_number])
  -- start/end NULLABLE since migration 2026_09_29_071806 (documented 2026-10-10): a custom-pin hotel has no
  -- places row, NULL means the day starts/ends at trips.hotel_lat/hotel_lng; unique added 2026-10-10

itinerary_items(itinerary_items_id, itinerary_days_id FK, places_id FK, visit_order, topsis_score?, source[wishlist|recommended],
  polyline_to_here?, visited_at?, unique[itinerary_days_id, places_id])
  -- unique added 2026-10-10 (US4 "no place twice in one run" was code-only); visit_order is deliberately NOT
  -- unique because resequenceDay() rewrites it row by row after a swap and would collide mid-loop

trip_viewers(trip_viewers_id, trips_id FK, users_id FK, added_at, unique[trips_id, users_id])
  -- added 2026-09-23, read-only trip sharing (US16) -- pure invite pivot, trips.users_id (owner) untouched
  -- no role column -- only one access level (read-only viewer) exists right now
  -- read endpoints check owner OR trip_viewers row; every write endpoint stays owner-only, unchanged

activity_log(id, log_name, description, subject_type, subject_id, causer_type, causer_id,
  attribute_changes?[json], properties[json - old/attributes], event[created|updated|deleted], timestamps)
  -- attribute_changes is a LOCAL addition in 2026_09_29_025036 on top of the package columns (noted 2026-10-10);
  -- the package's batch_uuid column was not included
  -- added 2026-09-22, provided by spatie/laravel-activitylog package (stock migration, not hand-written)
  -- Place and Category models use the LogsActivity trait -- admin edit audit trail (who changed what, when)
  -- id/subject_id/causer_id kept as-is -- package-owned migration, out of scope for the PK/FK rename below

-- Framework-owned tables (documented 2026-10-10, not domain tables but the auth flow depends on them):
personal_access_tokens(id, tokenable_type, tokenable_id, name, token[unique], abilities?, last_used_at?, expires_at?, timestamps)
  -- Laravel Sanctum; one row per issued bearer token, POST /api/auth/logout deletes the current one
password_reset_tokens(email PK, token, created_at)
  -- Laravel default; written by POST /api/auth/forgot-password, consumed by the reset-password web form
sessions(id PK, user_id?, ip_address?, user_agent?, payload, last_activity)
  -- SESSION_DRIVER=database; used only by the admin web panel (guard web), never by the Flutter app
```

> Full field-level rationale for every table lives in the design spec Section 4 — this is a cross-reference summary, not the source of truth.

**PK/FK naming convention (added 2026-09-22):** every primary key is now explicit `{table_name}_id` instead of a generic `id` (`places_id`, `categories_id`, `users_id`, `trips_id`, etc.), so a column name is self-describing even outside JOIN context (`trips.users_id` reads as "this trip references a `users` row" on its own). Foreign keys follow the same target name (`place_id`→`places_id`, `category_id`→`categories_id`, `user_id`→`users_id`, `trip_id`→`trips_id`, `itinerary_day_id`→`itinerary_days_id`, `itinerary_item_id`→`itinerary_items_id`); role-prefixed FKs keep their prefix (`hotel_place_id`→`hotel_places_id`, `start_place_id`/`end_place_id`→`start_places_id`/`end_places_id`). **3 deliberate exceptions:** `google_place_id`/`google_id` (Google's own external IDs, not references to our tables — coincidentally similar-looking names only), `activity_log`'s `id`/`subject_id`/`causer_id` (owned by the `spatie/laravel-activitylog` package's stock migration), and the `{id}` path parameter in API routes (Section 11 — a REST resource-identifier convention, not a database column name; `trip_viewers_id` follows the standard convention, added 2026-09-23).

**Soft delete policy (added 2026-09-22, extended 2026-09-23):** `deleted_at` only on tables with an independent delete feature worth preserving history for — `places`, `users`, `trips`, `place_reviews`, `categories`. Deliberately excluded from pure pivot tables (`place_category`, `trip_interest_category`, `user_default_interest_category`, `trip_wishlist_places`, `trip_viewers` — Eloquent's `sync()`/`detach()` expect hard delete; revoking viewer access is a hard delete of that `trip_viewers` row), pure child/detail rows with no independent delete feature (`place_photos`, `itinerary_days`, `itinerary_items`), and `place_candidates` (its `status` column already serves this purpose via `rejected`). **Unique constraints on soft-deletable tables (added 2026-10-04, found during backend implementation):** a plain UNIQUE also counts soft-deleted rows, so values that must be reusable after a soft delete use a partial index `WHERE deleted_at IS NULL` (`place_reviews (users_id, places_id)`, `categories.slug`, and since 2026-10-04 `users.email`/`users.google_id`); `places.google_place_id` stays plain unique on purpose. See the Key Validation Rules table below and design spec Section 4 ("Aturan unique + soft delete").

**Soft delete, FK and history rules (added 2026-10-10 after the PRD audit):**
- **`ON DELETE RESTRICT` does not protect soft deletes.** A soft delete is an `UPDATE deleted_at`, so the FK RESTRICT from the three category pivots never fires for it. The earlier claim that "the database refuses to delete a category still in use" was wrong for soft delete; `CategoryController::destroy` now checks `place_category`, `trip_interest_category` and `user_default_interest_category` (including rows of soft-deleted places/trips) and refuses with a flash error instead. Same reasoning applies to any future soft-deletable table: usage checks live in code.
- **History relations must use `withTrashed()`.** The whole point of `places.deleted_at` is that an existing itinerary keeps showing the place. `Place` carries the `SoftDeletes` global scope, so `ItineraryItem::place()`, `ItineraryDay::startPlace()/endPlace()`, `Trip::hotelPlace()` and `TripWishlistPlace::place()` are declared `->withTrashed()`. Everything that *chooses* places (catalog browse, TOPSIS candidate pool, swap candidates, hotel options, wishlist/hotel validation) keeps the default scope and therefore never offers a soft-deleted place; `ItineraryGenerator` also skips wishlist rows whose place was soft-deleted. The same rule holds for `users` relations (`trips.owner`, `trip_viewers.user`) if account deactivation is ever built.
- **FK `ON DELETE` policy as implemented** (relevant only for `forceDelete`, since the parents above are soft-deleted in practice): `CASCADE` from `trips` to `itinerary_days`/`trip_interest_category`/`trip_wishlist_places`/`trip_viewers`, from `itinerary_days` to `itinerary_items`, from `places` to `place_photos`/`place_reviews`/`trip_wishlist_places`, from `users` to `trips`/`place_reviews`/`trip_viewers`/`user_default_interest_category`; `RESTRICT` from `categories` to all three pivots and from `places` to `place_category`/`itinerary_items`/`itinerary_days.start|end_places_id`; `SET NULL` from `places` to `trips.hotel_places_id` and from `itinerary_items` to `place_reviews.itinerary_items_id`. A hard delete of a place would therefore silently wipe users' reviews and wishlist rows, which is one more reason `forceDelete` is not exposed anywhere.
- **Reviews lose their itinerary link on regenerate.** `POST /api/trips/{id}/generate` and a structural `PATCH /api/trips/{id}` delete the old `itinerary_days` (cascading to `itinerary_items`), so `place_reviews.itinerary_items_id` is set to NULL for any post-visit review tied to the old plan. The review itself survives (it hangs off `places`/`users`); only the "written from this stop" link is lost. Accepted, not a bug.
- **Unique constraints that were code-only until 2026-10-10** now exist in the schema: `trip_wishlist_places(trips_id, places_id)`, `itinerary_days(trips_id, day_number)`, `itinerary_items(itinerary_days_id, places_id)`, `place_photos(places_id, sort_order)`. `itinerary_items.visit_order` stays non-unique on purpose (see the data model comment).
- **Trip viewer self-invite** is rejected in code (`POST /api/trips/{id}/viewers` returns 422 for the owner's own email; joining your own invite link is a no-op). No schema rule, since a CHECK cannot reference `trips.users_id`.

**Admin audit trail (added 2026-09-22):** `Place` and `Category` (the two admin-curated models that feed directly into recommendation scoring — price, category tags, description) get the `spatie/laravel-activitylog` package's `LogsActivity` trait, so every create/update/delete through the admin panel is automatically recorded to `activity_log` with no custom controller code. Scoped to just these two models rather than every table — `place_candidates` approve/reject already has an equivalent history via its `status` column, and a 6-person team with full DB access doesn't need a blanket audit trail for a one-semester project. Surfaced in the admin panel as a "Riwayat Perubahan" (change history) tab on each place/category's edit screen.

**Share Itinerary privacy boundary (added 2026-09-23, non-negotiable per explicit requirement):** `GET /api/shared-itinerary/{share_token}` is the one truly public, unauthenticated endpoint in the whole API — no Sanctum token, no account, no way to verify who's asking. The response is built from a **strict field whitelist**, not a blacklist, so a future field added to `trips`/`itinerary_items` is excluded by default unless deliberately added to the whitelist. Always excluded, no exceptions: `visited_at` (live/status data, not plan data), anything from the `users` relation (owner's name/email/photo), `budget_total`, and precise coordinates for a custom-pin hotel (shown as a generic "Hotel" label instead — catalog-sourced hotels are fine to show as-is, since that location is already public). This is a genuinely different trust boundary from Trip Viewer (`trip_viewers`, US16) — that feature requires login and grants live-progress access to a specific named person who can be individually revoked; this one is anonymous, snapshot-only, and all-or-nothing (resetting `share_token` kills the link for everyone, there's no per-person revoke because no per-person identity is ever recorded).

**Key Validation Rules** *(the ones that matter most for correctness — not an exhaustive re-derivation of every field; defer the rest to implementation)*:

| Field | Rule |
|-------|------|
| `trips.num_days` | integer, ≥ 1; soft cap of 7 (design spec — a recommendation, not a hard technical block) |
| `trips.budget_total` | integer, IDR, > 0 - **per orang**, bukan total rombongan; tidak ada field jumlah orang di skema, jadi `estimated_cost_idr` per tempat juga diasumsikan basis per-kepala |
| `trips.daily_start_time` / `daily_end_time` | time; `daily_end_time` must be after `daily_start_time` |
| `trip_interest_category` | at least one row per trip on submit (empty only transiently allowed pre-onboarding-completion) |
| `places.estimated_cost_idr` | integer, IDR, ≥ 0, nullable |
| `trip_wishlist_places.custom_visit_minutes` | integer, > 0, required when `places_id` is null (custom pin) - no `places` row to fall back on for the day time-budget calculation |
| `place_reviews.rating` | integer, 1–5 inclusive |
| `place_reviews` | unique(users_id, places_id) as a **partial index `WHERE deleted_at IS NULL`** - one active review per user per place; a plain unique would block re-reviewing after deleting your own review (soft-deleted row still counted) |
| `categories.slug` | string, unique as a **partial index `WHERE deleted_at IS NULL`** (so a soft-deleted category's slug can be reused), lowercase-slug format (enforced to prevent near-duplicate tags like "kuliner" vs "wisata-kuliner") |
| `places.google_place_id` | plain unique, **deliberately not partial** - a soft-deleted place must still block re-insertion; Discovery's idempotency check uses `withTrashed()` (design spec Section 3 step 1a) |
| `users.email` / `users.google_id` | unique as a **partial index `WHERE deleted_at IS NULL`** (decided 2026-10-04), so a soft-deactivated account's email can be re-registered as a new account; every lookup by email/google_id must ignore soft-deleted rows (`User` already uses `SoftDeletes`, so plain Eloquent queries are safe). **Implemented** via migration `2026_10_04_000000_make_users_unique_indexes_ignore_soft_deletes` and covered by `AuthTest`; no account-deactivation feature exists yet, so it is not triggered in practice |
| `users.email` | valid email format (uniqueness: see the partial-index row above) |
| `users` | CHECK: `password IS NOT NULL OR google_id IS NOT NULL` |
| `place_candidates.google_place_id` | unique — this is the idempotency key preventing duplicate Discovery inserts (design spec Section 3) |
| `trip_viewers` | unique(trips_id, users_id) - no duplicate invites; invited email must belong to an existing registered user, no invite-by-email-for-non-users flow |
| `trip_wishlist_places` | unique(trips_id, places_id) (added 2026-10-10) - a catalog place at most once per trip; custom pins (`places_id` NULL) are unaffected because NULLs never collide |
| `itinerary_days` | unique(trips_id, day_number) (added 2026-10-10) |
| `itinerary_items` | unique(itinerary_days_id, places_id) (added 2026-10-10); `visit_order` intentionally not unique |
| `place_photos` | unique(places_id, sort_order) (added 2026-10-10) |
| `places.rating` | nullable; when NULL the TOPSIS rating criterion falls back to the median blend of the same `type`, then to a neutral 3.5 (added 2026-10-10) |
| `categories` (delete) | soft delete refused while any `place_category`/`trip_interest_category`/`user_default_interest_category` row references it, checked in code because FK RESTRICT does not cover soft delete (added 2026-10-10) |
| `trips.viewer_invite_token` / `share_token` | both nullable, unique, high-entropy random strings; regenerating either invalidates the OLD link for new joins only, does not affect anyone who already joined/has the old link cached — genuinely two separate tokens for two separate purposes, never reused across each other |

---

## 11. API / Integration Surface

Full endpoint list is design spec Section 12 — summarized by group:

| Group | Example | Auth |
|-------|---------|------|
| Auth | `/api/auth/register` (stages to `pending_registrations`, sends verification email - see note below), `/api/auth/login`, `/api/auth/google` | Public |
| Auth | `/api/auth/logout` | Token required |
| Auth | `/api/auth/forgot-password`, `/api/auth/reset-password` (added 2026-10-02 - documents F004, previously implemented but undocumented) | Public |
| Auth | `PUT /api/auth/password` (change password while logged in, added 2026-10-02 - F004) | Token required |
| Auth (web, not API) | `GET /auth/verify-registration` (signed URL from the verification email, opened in a browser, not called by the Flutter app directly - added 2026-10-02); `GET`/`POST /auth/reset-password` (the browser form the forgot-password email links to, documented 2026-10-10) | Public, signed-URL / reset-token only |
| Session | `GET /api/user` (returns the authenticated user; the mobile app calls it on launch to restore a stored token, documented 2026-10-10) | Token required |
| Profile | `/api/profile/preferences` (GET/PUT) | Token |
| Trip setup | `/api/trips` (POST/GET), `/api/trips/{id}` (GET/PATCH/DELETE), `/api/trips/{id}/hotel`, `/api/trips/{id}/hotel-options` | Token (GET `/api/trips/{id}` also allows an invited viewer, added 2026-09-23). `PATCH /api/trips/{id}` added 2026-10-10: owner-only edit of `title`/`num_days`/`budget_total`/`start_date`/`daily_*_time`; when `num_days`, `budget_total` or the daily times change and an itinerary exists, it is cleared and the response carries `itinerary_cleared: true`, the app then calls generate again (design spec "regenerate penuh"); `title`/`start_date` alone keep the itinerary |
| Wishlist | `/api/trips/{id}/wishlist` (POST/GET/DELETE) | Token |
| Generate | `/api/trips/{id}/weights`, `/api/trips/{id}/generate` | Token |
| Trip Viewer | `POST/GET /api/trips/{id}/viewers`, `DELETE /api/trips/{id}/viewers/{viewer_id}`, `POST/DELETE /api/trips/{id}/viewer-invite-link`, `POST /api/trips/join-viewer/{viewer_invite_token}`, `GET /api/trips/shared` (added 2026-09-23) | Token — invite/revoke owner-only, joining via link still requires login |
| Share Itinerary | `POST/DELETE /api/trips/{id}/share-link` (owner only), `GET /api/shared-itinerary/{share_token}` (added 2026-09-23) | Owner actions need a token; the view itself is fully public, no Sanctum at all — deliberately a different path than `/api/trips/shared` above so the two don't get confused |
| Swap | `/api/itinerary-items/{id}/swap-candidates`, `/api/places?...`, `PATCH /api/itinerary-items/{id}` | Token |
| Live tracking | `POST /api/itinerary-items/{id}/visit` | Token |
| Places/review | `GET /api/places`, `GET /api/places/{id}` (public), `/api/places/{id}/reviews`, `/api/reviews/{id}` | Mixed |

**No `/api/admin/*` group anymore** — admin runs on the separate web panel (see Section 8), whose Blade controllers talk to Eloquent directly instead of consuming this REST API. Its routes live in `routes/web.php` under `/admin/*` with session auth, entirely separate from the `routes/api.php` table above.

**Trip viewer authorization (added 2026-09-23):** every trip-scoped read endpoint (trip detail, wishlist, itinerary) now allows the trip's owner OR any user with a `trip_viewers` row for that trip. Every write endpoint that touches a trip (generate, swap, delete, weights, visit, wishlist mutation) stays owner-only, unchanged — see design spec Section 9. `POST /api/trips/join-viewer/{viewer_invite_token}` is the one exception that *creates* a `trip_viewers` row via a non-owner action — it still requires a valid Sanctum token (the joining user must be logged in), it just doesn't require the owner to have looked up that specific person by email first.

**Share Itinerary is a fully separate, unrelated mechanism (added 2026-09-23):** `GET /api/shared-itinerary/{share_token}` has no authorization check at all — it's not "owner or viewer," it's genuinely public. See design spec Section 10 for the strict response field whitelist that keeps this safe (no `visited_at`, no owner identity, no `budget_total`).

**External integrations:**
- Google Places API (New) — Nearby/Text Search (Pro SKU) + Place Details (Enterprise SKU) for place data
- Google Routes API (`computeRoutes`) — real road polylines, Essentials SKU
- Google Maps SDK via `google_maps_flutter` — map rendering, free
- Gemini API — bilingual content + AI category tagging + visit-duration estimation + is_outdoor inference, one combined call per place (Gemini chosen for its genuine free tier)
- Open-Meteo — day-level weather forecast, called directly client-side (no API key needed, so nothing to protect server-side), only once a trip's `start_date` is within ~7 days
- `geolocator` — device GPS, no API
- `geofence_service` (or equivalent) — OS-level geofencing for visit detection
- `flutter_local_notifications` — day-start and proximity reminders, fully local

---

## 12. Entity Lifecycles & State Machines

*(This is distinct from Section 13's "state management" — that section covers where client-side app state lives; this one covers actual entity status transitions on the backend, which was previously undocumented as a discrete artifact despite existing implicitly in the data model.)*

**`place_candidates.status`**
```
pending --(admin approves)--> approved --(triggers Place Details fetch + photo download +
                                            Gemini enrichment, promoted into `places`)--> [terminal]
pending --(admin rejects)-----> rejected --[terminal; row stays to prevent re-discovery
                                             from re-inserting it as a duplicate candidate]
```

**`trips` (implicit lifecycle — no formal status column, but a real state progression)**
```
created (weights/wishlist/hotel being assembled, no itinerary yet)
  --(generate)--> has itinerary
      --(swap one stop)--> has itinerary [unchanged state; partial update only]
      --(PATCH num_days/budget_total/daily times)--> created [itinerary cleared, must generate again - added 2026-10-10]
      --(PATCH title/start_date, or POST hotel)--> has itinerary [unchanged; hotel change takes effect on the next generate]
  --(delete)--> [terminal]
```

**`itinerary_items.visited_at`**
```
null (not visited) --(geofence entry OR manual tap)--> timestamp set (visited)
timestamp set --(manual toggle off)--> null [correction path for false-positive geofence triggers]
```
Note (2026-10-10): the whole `itinerary_days`/`itinerary_items` set is hard-deleted and rebuilt by every generate (and by a structural `PATCH /api/trips/{id}`), so `visited_at` and `place_reviews.itinerary_items_id` do not survive a regenerate. This is by design (the old plan no longer exists), not data loss to guard against.

**`trip_viewers` (added 2026-10-02 - was missing despite US16 existing since 2026-09-23)**
```
no row --(owner invites by email, OR someone claims a viewer_invite_token)--> row exists (read access granted)
row exists --(owner revokes)--> [hard delete, not soft - see Section 10 soft-delete policy]
```
Note: `trips.viewer_invite_token` itself has its own independent lifecycle - `null --(owner generates)--> active token --(owner regenerates or clears)--> null/new token`. Clearing it stops *new* joins but does not touch existing `trip_viewers` rows already created through it.

**`trips.share_token` (added 2026-10-02 - was missing despite US17 existing since 2026-09-23)**
```
null --(owner generates)--> active token (GET /api/shared-itinerary/{token} now resolves)
active token --(owner regenerates or clears)--> null/new token [old token immediately stops resolving for everyone - all-or-nothing, no per-person revoke]
```

**`pending_registrations` (added 2026-10-02 - see Section 10)**
```
no row --(POST /api/auth/register)--> row exists, verification email sent
row exists --(link clicked within 60 min)--> [deleted; users row created/updated with email_verified_at set]
row exists --(60 min elapse without click)--> [deleted on next verification attempt; user must register again]
```

---

## 13. Client-Side State Management

*(Renamed from "State Management Map" for clarity against Section 12's entity lifecycles — this section is specifically about where Flutter app state lives, not backend entity status.)*

| State | Location | Persistence | Notes |
|-------|----------|-------------|-------|
| Auth token | Local secure storage (`flutter_secure_storage`), or memory only | Persistent only when "Ingat Saya" is ticked at login; otherwise kept in memory for the session (A2 implementation, documented 2026-10-10) | Sanctum bearer token; `GET /api/user` on launch restores the session from a stored token |
| Active trip being built (setup/wishlist/weights before generate) | Local UI state (**Riverpod**) | Session (survives navigation, not app restart) | Multi-step wizard state |
| Generated itinerary | Server (source of truth) + local cache for offline viewing | Persistent (server), cached locally | Re-fetched via `GET /api/trips/{id}` |
| Live GPS position | Local UI state (stream) | None | From `geolocator`, not persisted |
| Geofence registration | OS-level (native, outside Flutter widget tree) | Persistent until deregistered | Survives app kill (Section 8 of design spec) |
| Pending offline visit events | Local SQLite/shared prefs queue | Persistent until synced | Section 8 edge case handling |
| Profile default preferences | Server + local cache | Persistent (server) | `user_default_interest_category` + `users.default_weight_*` columns |
| Read-only viewer mode flag | Local UI state, derived from `GET /api/trips/{id}` response | Session | Determines which action buttons render (added 2026-09-23); enforced server-side regardless, this is UI convenience only |
| Language selection | Local (`shared_preferences`) | Persistent | Client-side only, no backend |

**Decided: Riverpod** — good fit for this app's async-heavy nature (API calls, geofence streams, live location), strong testability. Team has no prior experience with either Riverpod or Provider, so Provider's usual advantage (existing familiarity) didn't apply here.

---

## 14. Tech Stack Recommendation

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Backend | Laravel 12 (PHP), REST API (for Flutter) + Blade web routes (for admin) | Team's established stack; API and admin panel are two separate route groups in one Laravel app |
| Mobile | Flutter | Single codebase for iOS/Android, end-user only (not admin) |
| Admin panel | Laravel Blade + Bootstrap | Separate web app for admin - session auth, controllers hit Eloquent directly, no REST API in between |
| State management | Riverpod | See Section 13 |
| Database | PostgreSQL | Decided over the team's usual MySQL-with-Laravel default (client's own hosting decision) |
| Auth | Laravel Sanctum (API tokens) + Google Sign-In | First-party, easy revocation, sufficient at this scale (chosen over JWT after explicit comparison) |
| Maps | Google Maps SDK (`google_maps_flutter`) | Free unlimited rendering |
| Routing | Google Routes API | Real road-following polylines, generous free tier for this call volume |
| Place data | Google Places API (New) | Only source; no scraping (ToS/legal risk explicitly rejected) |
| AI enrichment | Gemini API (Flash/Flash-Lite) | Genuinely free ongoing tier vs. OpenAI/Claude's one-time trial credits |
| Notifications | `flutter_local_notifications` | Fully client-side, no Firebase needed - covers day-start reminders, next-stop-approaching alerts, and the weather-window-opened alert (US15) |
| Geofencing | `geofence_service` (or equivalent native wrapper) | OS-level, survives app kill, battery-efficient |
| Weather | Open-Meteo | No API key needed, called client-side; 16-day forecast far exceeds the ~7-day window where it's actually shown |
| Hosting | Linux server | Same environment for both development and deployment, updated 2026-09-17 per client decision (was Windows Server) |
| Audit trail | `spatie/laravel-activitylog` | Package-provided `activity_log` table + `LogsActivity` trait on `Place`/`Category` - who changed what, when, zero custom controller code (added 2026-09-22) |

---

## 15. Suggested File Structure

```
SmartTrip-Batam/
├── docs/
│   ├── superpowers/specs/
│   │   └── 2026-09-07-smarttrip-itinerary-recommendation-design.md   # source of truth
│   └── prd/
│       └── 2026-09-07-smarttrip-prd.md                                # this document
├── smarttrip-api/                     # Laravel backend (scaffolded, implementation in progress as of 2026-10-02)
│   ├── app/Http/Controllers/Api/      # Trip, Place, Auth controllers - for Flutter (routes/api.php)
│   ├── app/Http/Controllers/Admin/    # Places, Candidates, Categories controllers - for web panel (routes/web.php)
│   ├── app/Models/                    # Place, Trip, ItineraryDay, ItineraryItem, ...
│   ├── app/Services/Itinerary/        # Topsis, KMeans, NearestNeighborRoute, Haversine, JaccardSimilarity,
│   │                                  # PlaceCostEstimator, PlaceRatingEstimator, ItineraryGenerator,
│   │                                  # HotelRecommender, SwapCandidateFinder, GoogleRoutesClient
│   ├── app/Services/Places/           # Discovery/Details/Gemini clients, PlaceDiscoveryService, PlaceCandidateReviewService
│   ├── app/Console/Commands/          # DiscoverPlaces (places:discover); enrichment runs inside candidate approval, no separate command
│   ├── resources/views/admin/         # Blade views - dashboard, places, candidates, categories
│   ├── database/migrations/
│   └── database/seeders/              # categories seeder (must run before places bootstrap)
└── smarttrip-mobile/                  # Flutter app - end-users only, no admin code here (state as of 2026-10-10)
    ├── lib/
    │   ├── features/                  # feature-first, each with data/ + presentation/
    │   │   ├── auth/                  # A2 Masuk + A3 Daftar (built), forgot-password placeholder
    │   │   ├── splash/                # session restore gate (built)
    │   │   ├── onboarding/            # Pilih Minat gate (planned)
    │   │   ├── trip_setup/
    │   │   ├── wishlist/
    │   │   ├── itinerary/
    │   │   ├── live_map/
    │   │   └── profile/
    │   ├── core/                      # api/ (Dio client), auth/ (session controller, token storage), router/, theme/, widgets/, error/
    │   ├── l10n/                      # gen-l10n ARB (id, en)
    │   └── main.dart
    └── ...
```

---

## 16. Acceptance Criteria

**US1 — Pilih minat & atur bobot preferensi**
- [ ] User can select 1 or more category chips from the seeded `categories` list
- [ ] User can set 4 sliders (0-10), backend normalizes to weights summing to 1
- [ ] Selections persist to `trip_interest_category` rows / `trips.weight_*` columns on submit
- [ ] Edge case handled: 0 sliders touched still submits with equal weights (all defaulted, not blocked)
- [ ] Error state: attempting to proceed with 0 categories selected during **onboarding** is blocked (min 1 required); during regular trip setup with an existing profile default, this can't happen since it's pre-filled

**US2 — Atur jumlah hari, anggaran, tanggal trip**
- [ ] User can set `num_days` (integer ≥ 1), `budget_total` (IDR, positive integer, **per orang** - UI label harus eksplisit "per orang"/"per person", tidak ada input jumlah orang di form ini), `start_date`
- [ ] `daily_start_time`/`daily_end_time` default to 09:00/19:00 if left unset, editable
- [ ] Values persist to `trips` on submit
- [ ] Edge case handled: `num_days` > 7 is allowed but shown a soft warning, not hard-blocked (design spec: soft cap, not a technical rule)
- [ ] Error state: `budget_total` ≤ 0 is rejected client-side before submit, with a clear inline message

**US3 — Tambah tempat ke wishlist**
- [ ] User can search the catalog and add a place to `trip_wishlist_places`
- [ ] User can add a custom pin (free-text name + lat/lng from a map tap + a required estimated-visit-duration input, added 2026-09-22) if the place isn't in the catalog
- [ ] Wishlist items appear tagged `source=wishlist` in the generated itinerary
- [ ] Edge case handled: adding the same place twice to one trip's wishlist is a no-op (no duplicate row), not an error

**US4 — Generate itinerary**
- [ ] `POST /api/trips/{id}/generate` returns a full day-by-day itinerary in **under ~15 seconds for a typical 3-5 day trip** in a single demo run (soft target based on expected candidate-pool size, not load-tested against concurrent users — flag and revisit if consistently exceeded during implementation)
- [ ] Each day's stops respect the daily time window (visit duration + estimated travel time ≤ window)
- [ ] No place appears on more than one day within the same generate run
- [ ] Edge case handled: insufficient candidate pool returns a "tidak muat" flag rather than an error or silently duplicated content
- [ ] Edge case handled: real Routes API travel time significantly exceeding the estimate flags the day "padat" post-generation

**US5 — Swap satu tempat**
- [ ] Tapping swap on a stop shows ranked TOPSIS alternatives (same category, same day's area radius) plus a manual search option
- [ ] Committing a swap re-runs Nearest-Neighbor only for the affected day and refreshes only that leg's road polyline
- [ ] Other days and stops in the same trip are unaffected
- [ ] Edge case handled: zero ranked alternatives available still allows manual search to proceed without error
- [ ] Swapping in a ranked alternative persists its already-known `topsis_score`; swapping in a manual-search result leaves `topsis_score` NULL (never fabricated) since it was never scored against this trip's weights

**US6 — Live map**
- [ ] All stops for the active day render as numbered pins immediately, not progressively revealed
- [ ] Polyline segments render gray when the destination stop is visited, blue otherwise
- [ ] Live user location renders and updates while the map screen is open

**US7 — Manual visit toggle**
- [ ] Long-press (or button) marks/unmarks a stop's `visited_at` regardless of geofence state
- [ ] Works when location permission was denied (feature isn't fully broken, just not automatic)

**US8 — Simpan preferensi default**
- [ ] A "simpan sebagai default" toggle during trip setup writes to `user_default_interest_category`/`users.default_weight_*` via `PUT /api/profile/preferences`
- [ ] Leaving the toggle off means the trip's selections stay trip-specific; profile defaults are untouched
- [ ] The next new trip created pre-fills from the saved default
- [ ] Editing directly from the Profile screen produces the same stored result as the toggle

**US9 — Login pakai Google**
- [ ] `POST /api/auth/google` with a valid `id_token` returns the same Sanctum token shape as `/login`
- [ ] An existing password-based account with a matching email gets `google_id` linked to it, not duplicated into a second account
- [ ] A first-time Google sign-in creates a new user with `password = null`
- [ ] Error state: an invalid/expired `id_token` returns a clear auth error, not a silent failure or generic 500

**US10 — Beri rating/review**
- [ ] Any authenticated user can submit a rating (1-5) plus an optional comment on any place, at any time (open review policy — no visit proof required)
- [ ] `itinerary_items_id` is populated only when the review is submitted from a post-visit "rate your trip" flow; otherwise it's null
- [ ] A submitted review is reflected in that place's Bayesian-blended rating on the next TOPSIS scoring run

**US11 — Trigger discovery (Admin)**
- [ ] Discovery re-runs do not re-insert `google_place_id`s already present in `places` or `place_candidates`, in any status (including `rejected`)
- [ ] `categories` must be seeded before the first Discovery/Enrichment run — documented setup order, not a runtime technical block

**US12 — Review & approve/reject candidates (Admin)**
- [ ] Approving a candidate triggers, in one flow: full Place Details fetch, photo download to local storage, and a single Gemini call (translation + category tags + visit duration)
- [ ] Rejecting a candidate sets `status = rejected` and it is excluded from future Discovery re-inserts (see US11)

**US13 — Admin lengkapi data**
- [ ] Admin can edit `estimated_cost_idr`, `description_override`, `description_en`, `estimated_visit_minutes`, and the place's `place_category` rows
- [ ] Manually editing a place's categories sets `category_tags_reviewed = true`
- [ ] Edits take effect on the next TOPSIS scoring run without requiring a re-sync

**US14 — Dashboard admin**
- [ ] Dashboard lists places missing `estimated_cost_idr`
- [ ] Dashboard lists places with `category_tags_reviewed = false`
- [ ] Dashboard shows most-wishlisted places, average in-app rating, and trip volume
- [ ] Edge case handled: an empty dataset (before the first bootstrap) renders an empty state, not an error

**US15 — Weather forecast & swap suggestion**
- [ ] Forecast card appears on a day only once `trip.start_date` is within ~7 days of today — not shown before that (no reliable forecast exists yet)
- [ ] Forecast is fetched client-side directly from Open-Meteo using the hotel/start-location coordinate, no backend call involved
- [ ] A local notification (`flutter_local_notifications`, no backend/Firebase) is scheduled on the device as soon as the itinerary is generated, firing at `start_date - 7 days`, prompting the user to open the app and check the forecast; tapping it opens the itinerary screen. If `start_date` is already less than 7 days out at generate time, the notification is scheduled for the next morning instead of a past time
- [ ] Editing a trip's `num_days`/`start_date` (full regenerate) cancels the previously scheduled forecast-window notification and reschedules it against the new `start_date`, the same way the existing day-start reminders are rescheduled
- [ ] A day with ≥1 stop where `places.is_outdoor = true` AND significant rain in that day's forecast shows the rain-warning badge
- [ ] Tapping the badge opens the existing swap modal (US5) for the outdoor stop(s) on that day — no new swap mechanism, no automatic regenerate
- [ ] Edge case handled: a day with only indoor stops never shows the badge regardless of forecast
- [ ] Edge case handled: forecast fetch failure (offline, Open-Meteo unavailable) degrades to no forecast shown, not an error blocking the rest of the itinerary screen

**US16 — Share trip as read-only viewer** *(added 2026-09-23)*
- [ ] Trip owner can search a registered user by email from the trip's "Bagikan" screen and add them as a viewer, creating a `trip_viewers` row
- [ ] No accept/reject step — the invited user gets access immediately, no notification is pushed to them (consistent with this app's no-Firebase/no-backend-push design elsewhere)
- [ ] Inviting an email that doesn't belong to a registered account is rejected with a clear error, not silently ignored
- [ ] Invited viewer sees the trip under a separate "Dibagikan ke Saya" tab, distinct from their own "Trip Saya" list
- [ ] Viewer can see the same trip detail, itinerary, and live-progress state (`visited_at` per stop) the owner sees, via the same `GET /api/trips/{id}` and derived endpoints
- [ ] Viewer sees the owner's stored progress state (`visited_at`, day status flags), NOT the owner's live-moving GPS position — the owner's raw location is never sent to the server, this feature doesn't change that
- [ ] Every write action (swap, regenerate, delete, mark visited, edit weights/wishlist/hotel) is rejected with 403 for a viewer, enforced server-side regardless of what the UI hides
- [ ] Owner can revoke a viewer's access at any time from the same "Bagikan" screen; access is removed immediately (hard delete of the `trip_viewers` row), regardless of whether that viewer joined by email or by link
- [ ] Edge case handled: a user can be a viewer on a trip while also being the owner of their own separate trips — no conflict between the two roles
- [ ] Owner can also generate a `viewer_invite_token` link (added 2026-09-23) and share it via the OS share sheet, as an alternative to searching by email — this works even for people who don't have an account yet
- [ ] Opening a viewer-invite link while logged out routes through Login/Register first, then automatically creates the `trip_viewers` row and opens the trip — no separate "accept" screen after auth
- [ ] Opening a viewer-invite link while already logged in joins immediately, no extra step
- [ ] Regenerating or clearing `viewer_invite_token` stops new people from joining via the old link, but does NOT remove anyone who already joined through it — their `trip_viewers` row is untouched

**US17 — Share itinerary via anonymous public link** *(added 2026-09-23)*
- [ ] Trip owner can generate a `share_token` from the "Bagikan Trip" screen's separate "Share Itinerary" section (distinct UI from US16's viewer invite, not the same flow)
- [ ] The resulting link works for **anyone**, with no login and no SmartTrip account required at all
- [ ] `GET /api/shared-itinerary/{share_token}` is a fully public endpoint — no Sanctum token, no `trip_viewers` check, nothing recorded about who opened it
- [ ] Response strictly excludes: `visited_at` / any live-progress data, the owner's name/email/any `users` field, `budget_total`, and precise coordinates for a custom-pin hotel (shown as a generic "Hotel" label instead)
- [ ] Owner can reset/clear `share_token` at any time, which immediately invalidates the link for everyone who has it — since no per-viewer identity is tracked, this is all-or-nothing, there is no way to revoke one specific person while leaving the link live for others (this is a known, accepted limitation, not a bug)
- [ ] Edge case handled: requesting a `share_token` that's null, invalid, or already reset returns a generic 404, not a response that distinguishes "never existed" from "was reset" (avoids leaking trip existence)
- [ ] Edge case handled: this feature and US16 (Trip Viewer) are completely independent — a trip can have an active `share_token`, an active `viewer_invite_token`, specific named viewers, all three, or none, in any combination, with no interaction between them

> Full edge-case catalogue (beyond what's listed per-story above) lives in design spec Sections 3, 7, 8, 9, 10, and 11.

---

## 17. Open Questions & Risks

- ~~**Q:** What's the target hosting environment for backend?~~ **Resolved 2026-09-17 (updated from 2026-09-07):** Linux server + PostgreSQL, for both development and deployment — client decision, overrides the earlier Windows Server pick.
- ~~**Q:** Riverpod vs. Provider for Flutter state management?~~ **Resolved 2026-09-07:** Riverpod - team has no prior experience with either, so no reason to prefer Provider's smaller learning curve over Riverpod's better fit for this app's async-heavy needs.
- **Risk:** Google Places Enterprise SKU quota (1,000 free calls/month) is the tightest constraint in the whole project — a rushed or careless bootstrap could burn it before the curated pool is complete — *Mitigation: the two-phase Discovery/Enrichment admin-review gate exists specifically to prevent this*
- **Risk:** Background location permission ("Allow all the time" / "Always") is a sensitive, store-reviewed permission — fine for demo/sideload, but a real blocker if the team later wants to publish to Play Store — *Mitigation: documented explicitly as out of scope for this semester (design spec Section 16)*
- **Risk:** Batam's island geography (irregular coastline, limited bridges) makes the Haversine-based day-budget travel-time estimate systematically optimistic — *Mitigation: circuity multiplier (~1.3-1.4x) applied, plus a post-hoc "padat" flag once real Routes API data comes back*
- **Tradeoff:** Open (unverified) in-app reviews vs. verified-visit-only — chosen open specifically because the Bayesian rating blend needs review volume to be useful, accepting lower per-review trust as the cost

---

## 18. Decisions Log

Key pivots made during the design process (all 2026-09-07, in one extended design session):

| Decision | Why |
|----------|-----|
| True pairwise AHP → direct-rating sliders + TOPSIS | Simpler mobile UX; same personalized-weight outcome without the pairwise-comparison UI overhead |
| Guest trips → login required from the start | Deliberate simplification — removed the guest-trip-token mechanism and its conditional auth logic entirely |
| JWT → Laravel Sanctum (API tokens) | Easier revocation, first-party Laravel support, sufficient at this project's scale |
| Web/Blade admin panel → role-gated Flutter screens (2026-09-07) → **back to web/Blade admin panel (2026-09-11)** | First moved to mobile-only for one codebase; reversed once it was clear admin work (data tables, bulk review) fits a web panel much better, and admin never needs a phone for it anyway |
| Single-shot Google sync → two-phase Discovery/Enrichment | The Enterprise SKU's 1,000/month quota is too tight for a naive one-shot sync; needed an admin-reviewed gate before spending it |
| Manual admin translation → Gemini auto-translation | Once the quota concern was correctly isolated to Place *Details* fetches (not text translation), there was no reason to hand-translate |
| Auto-assume skipped stops as "visited" → explicit manual-only resolution | A real skip is a valid user scenario, not just GPS error — false inference would hide genuine plan changes |
| `places` + `place_attributes` (two tables) → merged into one `places` table (2026-09-22) | Team preferred one table over the schema-level split; overwrite risk on re-sync is now handled purely in code — the sync/enrichment job must `update()` an explicit whitelist of Google-sourced columns only, never mass-assign the full Google payload onto an existing row, or it would wipe out admin-curated fields (`category_tags`, `estimated_cost_idr`, `is_outdoor`, etc.) |
| "Trip collaboration is out of scope" → **read-only trip sharing is in scope** (2026-09-23) — this is a rework, not a deferred future-work idea | User explicitly reversed the earlier out-of-scope call for a narrower version: single owner keeps full control (generate/swap/delete/weights all stay owner-only), invited viewers get read access only, enforced server-side. Chosen over full co-editing because TOPSIS scoring is built around one owner's preference weights — merging multiple people's preferences into one score has no clean answer, so it was deliberately kept out |
| Viewer "live tracking" → polling stored `visited_at` state, NOT live GPS broadcast | Two interpretations existed: (a) viewer sees the same visited/not-visited state the owner already sees (cheap, no new plumbing), or (b) viewer sees the owner's GPS dot moving in real time (requires the owner's location to reach the server for the first time ever — a genuine privacy/architecture change from the existing design). Chose (a) explicitly, preserving the existing "owner's GPS never leaves their device" decision from Section 8 |
| Trip Viewer invites → email search AND link-based invite (2026-09-23) | Email-search-only had a real gap: it could only invite someone who *already* had a registered account. Added `viewer_invite_token` as a second on-ramp into the same `trip_viewers` table — link requires login/register but not a pre-existing account, closing that gap without building a second authorization system |
| Share Itinerary (US17) → a standalone mechanism, NOT built on top of Trip Viewer | User explicitly rejected reusing `trip_viewers`/login for this feature ("it's not related to the prev feature... this one genuinely just for sharing a trip") — Share Itinerary needed to work with zero account/login at all, which `trip_viewers` structurally can't do (its `users_id` FK requires a real user row). Built as one nullable `trips.share_token` column + one public endpoint instead, deliberately simpler and fully independent |
| Share Itinerary payload → whitelist, not blacklist, with `visited_at`/owner identity/`budget_total` excluded by design | Explicit "no privacy leak" requirement from the user. A blacklist risks forgetting to exclude a newly-added sensitive field later; a whitelist means new fields are invisible to the public endpoint by default until someone deliberately opts them in |

---

## 19. Rollout & Next Steps

**MVP scope:** Effectively the entire design spec as documented — for a 6-person, 1-semester team, there isn't much room for a smaller "true MVP" cut without undermining the thesis-worthy parts (the algorithm pipeline) or the differentiators (live tracking, AI enrichment). If time pressure hits mid-semester, the safest things to defer first would be: bilingual EN content, the live-map notification piggyback, and admin dashboard charts (keep the underlying data/lists, drop the visualization polish).

**Rough phase breakdown** *(illustrative, relative to semester start — no actual semester calendar was provided, so no real dates are given; replace with real milestones once the team has one)*:
- **Phase 1:** Backend scaffolding, data model migrations, Google Places bootstrap (categories seed → Discovery → first Enrichment batch)
- **Phase 2:** Core algorithm implementation (TOPSIS/K-Means/NN) + unit tests, Flutter trip-setup/wishlist/generate flow
- **Phase 3:** Live map + geofencing, swap, admin web panel (Blade views), AI enrichment pipeline
- **Phase 4:** Profile preferences, Google Sign-In, bilingual support, reviews, read-only trip sharing (US16) + anonymous itinerary share links (US17, both added 2026-09-23), polish + testing, demo prep

**Phase 2+ ideas** *(explicitly out of scope this semester, per design spec Section 16)*:
- Multi-city expansion
- Booking/payment integration
- Multi-editor trip collaboration (real-time co-editing, comments) — read-only sharing itself is in scope, see US16
- Play Store publish readiness

**Sign-off needed from:**
- [ ] Team (all 6 members should read the design spec + this PRD before implementation starts)
- [ ] Whoever is setting up the Google Cloud billing account (needed even for free-tier usage)

**Next steps:**
1. Review this PRD and the design spec together, flag any disagreement — *Owner: whole team*
2. Move to implementation planning (writing-plans skill) once both documents are approved — *Owner: whoever drives implementation*
3. Resolve the open questions in Section 17 before or during planning, not after — *Owner: Team*

---

## 20. Observability & Configuration

*(Not deeply specified during design — reasonable for a pre-implementation college project — but the two genuine operational risks flagged elsewhere, Google API quota exhaustion and background geofencing reliability, warrant at least a baseline plan rather than silence.)*

- **Backend logging:** log every Google Places/Routes/Gemini API call (which endpoint, cost-relevant SKU tier, success/failure) so quota usage is traceable proactively, not discovered only after the free tier is already exhausted
- **Backend logging:** log `places:discover` runs and each candidate-approval Enrichment (counts, failures) — these are the highest-cost operations in the system
- **Mobile crash/analytics reporting:** no tooling specified — acceptable gap for a college project, flagged here rather than silently absent
- **Environment configuration (dev/staging/prod):** no separate staging/prod split is planned — Section 14 deliberately uses **one Linux server for both development and deployment** (hosting decision already Resolved, see Section 17); a dev/staging/prod split was never raised as a requirement for this one-semester scope, not an oversight

---

## 21. Glossary

| Term | Meaning |
|------|---------|
| **TOPSIS** | Technique for Order of Preference by Similarity to Ideal Solution — a multi-criteria decision-making method that ranks options by closeness to a hypothetical "ideal" score across weighted criteria |
| **Jaccard similarity** | Overlap ratio between two sets — used here to compare a user's selected interest tags against a place's category tags |
| **K-Means clustering** | Groups nearby points into K clusters — used here to assign wishlist place coordinates to specific trip days |
| **Nearest-Neighbor (NN)** | A routing heuristic that always visits the closest unvisited stop next — used to order each day's visit sequence |
| **Haversine distance** | Straight-line ("as the crow flies") distance between two lat/lng coordinates on a sphere |
| **Circuity/detour multiplier** | A correction factor (~1.3-1.4x here) applied to straight-line distance to approximate real road distance |
| **Bayesian rating blend** | A weighted-average technique (same principle as IMDB's rating formula) blending a place's Google rating with its in-app review average, weighted by how many in-app reviews exist |
| **Geofencing** | OS-level detection of a device entering/exiting a defined radius around a coordinate — used here to auto-detect a visited stop |
| **Enterprise / Pro SKU** | Google Places API pricing tiers — Enterprise (rating, hours, price fields) has a much tighter free quota (1,000/mo) than Pro (Nearby/Text Search, 5,000/mo), which shaped the two-phase Discovery/Enrichment design |
| **Trip viewer** | A user invited by a trip's owner (by email or link) to see that trip read-only — itinerary, live progress, status — with no ability to modify it. Requires an account and login (added 2026-09-23, US16) |
| **Share Itinerary link** | An anonymous, no-account public link to a trip's static generated plan. Unrelated to Trip Viewer — no login, no live progress, no per-person tracking, all-or-nothing revoke (added 2026-09-23, US17) |

---

*Source of truth for implementation detail remains the design spec at `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` — this PRD is a reformatted, audience-oriented view of the same decisions, not a competing document. Where they ever conflict, the design spec wins since it has finer-grained rationale.*
</content>
