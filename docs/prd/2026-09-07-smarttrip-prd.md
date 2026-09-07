# SmartTrip Batam - Product Requirements Document

## 0. Metadata & Revision History

**Type:** Full PRD
**Status:** Draft — pre-implementation
**Version:** 1.4
**Last Updated:** 2026-09-07
**Source of truth for implementation detail:** `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` (this PRD is a reformatted, audience-oriented view of the same decisions — where they ever conflict, the design spec wins, since it carries finer-grained rationale)

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-09-07 | Initial PRD generated from the design spec via `/prd-draft` |
| 1.1 | 2026-09-07 | Applied `/prd-analyze` findings: added Metadata, Entity Lifecycles, Glossary, Observability, Competitive Landscape, Decisions Log sections; expanded Acceptance Criteria to cover all 14 user stories; fixed untestable SLA criterion; added data model validation rules |
| 1.2 | 2026-09-07 | Replaced the unresearched Competitive Landscape placeholder with real research (Wanderlog, TripIt, the LLM-chat AI-planner category, and Atourin as the closest Indonesian comparable) |
| 1.3 | 2026-09-07 | Resolved hosting open question: Windows Server + PostgreSQL for both dev and deployment (overrides team's usual MySQL default) |
| 1.4 | 2026-09-07 | Decided Riverpod (team has no prior experience with either option); removed accessibility entirely per explicit instruction - not pursuing it this project |

---

## 1. Overview

**Feature / Project Name:** SmartTrip Batam - Sistem Rekomendasi Itinerary Liburan Berbasis Preferensi Pengguna

**Problem Statement:**
Wisatawan Batam kesulitan menentukan destinasi wisata dan kuliner yang sesuai dengan minat, lokasi, waktu, dan anggaran mereka, karena informasi tersebar di berbagai platform dan butuh usaha untuk membandingkan. Banyak wisatawan tidak punya perencanaan terstruktur, sehingga rute perjalanan jadi tidak efisien dan destinasi menarik terlewatkan.

*(No formal user research or usage data backs this statement — it's a reasoned problem framing appropriate for a college project's scope, not a data-backed claim. Flagged here rather than silently presented as evidence-based.)*

**Proposed Solution:**
Aplikasi mobile yang merekomendasikan tempat wisata/kuliner/hotel sesuai preferensi pengguna (minat, jarak, anggaran, rating) memakai Weighted-TOPSIS, lalu otomatis menyusun jadwal perjalanan multi-hari dengan pengelompokan lokasi (K-Means) dan urutan rute (Nearest-Neighbor + Google Routes API), termasuk pelacakan progres kunjungan secara live.

**AI Build Summary:**
> Build a Laravel 12 REST API backend + single Flutter mobile app (role-gated for both end-users and admins, no separate web panel) for a Batam trip-itinerary recommender. Auth via Laravel Sanctum (opaque tokens) with email/password and Google Sign-In. Core algorithm pipeline: user-weighted TOPSIS scoring (4 criteria: category-fit via Jaccard similarity, distance via Haversine, budget via a 4-tier fallback chain, rating via a Bayesian Google+in-app blend) → K-Means day clustering → Nearest-Neighbor route ordering → Google Routes API for real road polylines. Place data sourced exclusively from Google Places API (New) via an admin-reviewed two-phase Discovery/Enrichment pipeline (never scraped from other platforms), enriched by Gemini (free tier) for translation, category tagging, and visit-duration estimation. Live trip map with GPS-geofencing-based visit tracking. No booking/payment, no multi-city, no web admin panel, one-semester scope for a 6-person student team.

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
- Not trying to build a web admin panel (mobile-only, role-gated)
- Not trying to achieve Play Store publish-readiness (background location permission justification/privacy policy work is out of scope)

---

## 4. Target Users & Personas

*(Kept intentionally light — proportionate to a college project scope, not a market-research-backed persona set.)*

- **Wisatawan (primary user)** — a tourist visiting Batam who wants a personalized, low-effort trip plan. May be domestic or, given Batam's proximity to Singapore/Malaysia, international (hence the bilingual ID/EN UI). No account required to browse; account required to plan.
- **Admin (secondary user, same app)** — a team member (or eventually, someone maintaining the app) responsible for curating place data quality: reviewing Discovery candidates, filling in missing price/category data, monitoring the dashboard.

---

## 5. Scope & Constraints

**In scope:** everything in the accompanying design spec — trip creation, wishlist, preference sliders + minat selection, hotel resolution (search or custom pin), TOPSIS/K-Means/NN/Routes generation pipeline, swap, live map with geofencing, in-app reviews, profile preference defaults, mandatory onboarding, Google Sign-In, and the full admin data-curation loop (Discovery → review → Enrichment → AI tagging/translation → ongoing curation).

**Out of scope** (see design spec Section 13 for full detail):
- Booking/reservation/payment of any kind
- Multi-city support (no `city` field anywhere; Batam-only, hardcoded area list)
- Web admin panel (all admin functionality is role-gated inside the same Flutter app)
- Scraping any platform besides Google Places (TripAdvisor/Traveloka/Tiket.com explicitly rejected — ToS/legal risk)
- True pairwise AHP (replaced with simpler direct-rating sliders feeding the same TOPSIS scoring)
- Itinerary sharing/collaboration between users
- Automatic re-routing when a user deviates from the planned route
- Play Store/App Store publish readiness
- Per-day time windows (single trip-wide `daily_start_time`/`daily_end_time` only)
- Mid-trip hotel changes (one hotel = one trip's start/end point)

**Technical constraints:**
- Platform: **Android/iOS via Flutter** (single codebase for end-users and admins)
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
- Admin: review candidates, CRUD places/categories, dashboard analitik
- Empty state: katalog kosong (belum ada data tersinkron), wishlist kosong, trip list kosong
- Error state: generate gagal (pool kandidat tidak cukup → flag "tidak muat"/"padat"), geofence permission ditolak (fallback manual), offline saat visit-tracking (antri lokal)
- Loading state: skeleton/spinner saat generate (proses multi-tahap: TOPSIS → K-Means → NN → Routes API)

**Interaction Model:**
- Primary flow: Section 10 of design spec (numbered end-to-end)
- Long-press pin di peta = tandai/batalkan kunjungan manual
- Tap "+wishlist" di kartu katalog = tambah tanpa keluar dari browsing (tidak ada modal blocking)

**Figma / Design Link:** none — no visual design phase happened, this PRD and the design spec are text-only artifacts

---

## 9. Component Inventory

| Component | Type | Description | Linked Stories |
|-----------|------|--------------|------------------|
| CategoryChipSelector | Form | Multi-select minat categories | US1, US8 |
| CriteriaSliderGroup | Form | 4 sliders 0-10 (kategori/jarak/anggaran/rating) | US1, US8 |
| PlaceCatalogGrid | Display | Infinite-scroll place browsing with category filter | US3 |
| PlaceCard | Display | Thumbnail, name, rating, badge (wishlist/recommended) | US3, US4 |
| WishlistButton | Action | Toggle add/remove place to trip wishlist | US3 |
| MapPinPicker | Form | Tap/drag pin on `google_maps_flutter` for custom locations | US3 (hotel/wishlist custom pin) |
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
| CandidateReviewList | Display + Action | Admin candidate list with filter, approve/reject | US11, US12 |
| PlaceAdminForm | Form | Admin CRUD for place_attributes overrides | US13 |
| AdminDashboard | Display | Charts/cards for wishlist popularity, missing data lists | US14 |
| CategoryAdminForm | Form | CRUD for `categories` taxonomy | (admin) |
| LanguageToggle | Action | ID/EN switch, settings | - |

---

## 10. Data Models

Backend is Laravel/Eloquent (not TypeScript) — schema shown as field lists per the design spec's Data Model section (full authoritative version there; summarized here for cross-reference):

```
places(id, google_place_id?, name, type[attraction|culinary|lodging], lat, lng, address,
  price_level?, rating, review_count, opening_hours[json], photo_url, description?,
  phone?, website?, google_maps_uri?, business_status[operational|closed_temporarily|closed_permanently],
  types[json], source[google|manual], timestamps)

place_attributes(place_id FK, category_tags[json:categories.id], category_tags_reviewed[bool],
  estimated_visit_minutes, estimated_cost_idr?, description_override?, description_en?, timestamps)

categories(id, name_id, name_en, slug[unique], timestamps)

place_candidates(google_place_id[unique], name, type, lat, lng, search_area,
  status[pending|approved|rejected], timestamps)

place_photos(place_id FK, photo_url, sort_order)

place_reviews(place_id FK, user_id FK, rating[1-5], comment?, itinerary_item_id? FK, timestamps)

users(..., password?, google_id?[unique], role[user|admin], default_interest_category_ids[json], timestamps)

user_criteria_weights(user_id FK, criterion, weight)

trips(id, user_id FK, title, num_days, budget_total, has_own_hotel[bool], hotel_place_id? FK,
  hotel_custom_name?, hotel_lat?, hotel_lng?, interest_category_ids[json], start_date,
  daily_start_time, daily_end_time, timestamps)

trip_wishlist_places(trip_id FK, place_id? FK, custom name/lat/lng if not in places)

trip_criteria_weights(trip_id FK, criterion, weight)

itinerary_days(trip_id FK, day_number, start_place_id, end_place_id)

itinerary_items(itinerary_day_id FK, place_id FK, visit_order, topsis_score, source[wishlist|recommended],
  polyline_to_here, visited_at?)
```

> Full field-level rationale for every table lives in the design spec Section 4 — this is a cross-reference summary, not the source of truth.

**Key Validation Rules** *(the ones that matter most for correctness — not an exhaustive re-derivation of every field; defer the rest to implementation)*:

| Field | Rule |
|-------|------|
| `trips.num_days` | integer, ≥ 1; soft cap of 7 (design spec — a recommendation, not a hard technical block) |
| `trips.budget_total` | integer, IDR, > 0 |
| `trips.daily_start_time` / `daily_end_time` | time; `daily_end_time` must be after `daily_start_time` |
| `trips.interest_category_ids` | non-empty array on submit (empty only transiently allowed pre-onboarding-completion) |
| `place_attributes.estimated_cost_idr` | integer, IDR, ≥ 0, nullable |
| `place_reviews.rating` | integer, 1–5 inclusive |
| `categories.slug` | string, unique, lowercase-slug format (enforced to prevent near-duplicate tags like "kuliner" vs "wisata-kuliner") |
| `users.email` | unique, valid email format |
| `users.google_id` | unique when present; nullable |
| `place_candidates.google_place_id` | unique — this is the idempotency key preventing duplicate Discovery inserts (design spec Section 3) |

---

## 11. API / Integration Surface

Full endpoint list is design spec Section 9 — summarized by group:

| Group | Example | Auth |
|-------|---------|------|
| Auth | `/api/auth/register`, `/api/auth/login`, `/api/auth/google` | Public |
| Auth | `/api/auth/logout` | Token required |
| Profile | `/api/profile/preferences` (GET/PUT) | Token |
| Trip setup | `/api/trips` (POST/GET/DELETE), `/api/trips/{id}/hotel`, `/api/trips/{id}/hotel-options` | Token |
| Wishlist | `/api/trips/{id}/wishlist` (POST/GET/DELETE) | Token |
| Generate | `/api/trips/{id}/weights`, `/api/trips/{id}/generate` | Token |
| Swap | `/api/itinerary-items/{id}/swap-candidates`, `/api/places?...`, `PATCH /api/itinerary-items/{id}` | Token |
| Live tracking | `POST /api/itinerary-items/{id}/visit` | Token |
| Places/review | `GET /api/places`, `GET /api/places/{id}` (public), `/api/places/{id}/reviews`, `/api/reviews/{id}` | Mixed |
| Admin | `/api/admin/places`, `/api/admin/place-attributes`, `/api/admin/categories`, `/api/admin/places/discover`, `/api/admin/place-candidates`, `/api/admin/analytics` | Admin role |

**External integrations:**
- Google Places API (New) — Nearby/Text Search (Pro SKU) + Place Details (Enterprise SKU) for place data
- Google Routes API (`computeRoutes`) — real road polylines, Essentials SKU
- Google Maps SDK via `google_maps_flutter` — map rendering, free
- Gemini API — bilingual content + AI category tagging + visit-duration estimation, one combined call per place (Gemini chosen for its genuine free tier)
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
      --(edit num_days/budget/hotel)--> has itinerary [regenerated from scratch]
  --(delete)--> [terminal]
```

**`itinerary_items.visited_at`**
```
null (not visited) --(geofence entry OR manual tap)--> timestamp set (visited)
timestamp set --(manual toggle off)--> null [correction path for false-positive geofence triggers]
```

---

## 13. Client-Side State Management

*(Renamed from "State Management Map" for clarity against Section 12's entity lifecycles — this section is specifically about where Flutter app state lives, not backend entity status.)*

| State | Location | Persistence | Notes |
|-------|----------|-------------|-------|
| Auth token | Local secure storage (`flutter_secure_storage`) | Persistent | Sanctum bearer token |
| Active trip being built (setup/wishlist/weights before generate) | Local UI state (**Riverpod**) | Session (survives navigation, not app restart) | Multi-step wizard state |
| Generated itinerary | Server (source of truth) + local cache for offline viewing | Persistent (server), cached locally | Re-fetched via `GET /api/trips/{id}` |
| Live GPS position | Local UI state (stream) | None | From `geolocator`, not persisted |
| Geofence registration | OS-level (native, outside Flutter widget tree) | Persistent until deregistered | Survives app kill (Section 8 of design spec) |
| Pending offline visit events | Local SQLite/shared prefs queue | Persistent until synced | Section 8 edge case handling |
| Profile default preferences | Server + local cache | Persistent (server) | `user_criteria_weights` |
| Language selection | Local (`shared_preferences`) | Persistent | Client-side only, no backend |

**Decided: Riverpod** — good fit for this app's async-heavy nature (API calls, geofence streams, live location), strong testability. Team has no prior experience with either Riverpod or Provider, so Provider's usual advantage (existing familiarity) didn't apply here.

---

## 14. Tech Stack Recommendation

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Backend | Laravel 12 (PHP), REST API only | Team's established stack; no Blade views needed (mobile-only) |
| Mobile | Flutter | Single codebase for iOS/Android, single app for users + role-gated admin |
| State management | Riverpod | See Section 13 |
| Database | PostgreSQL | Decided over the team's usual MySQL-with-Laravel default, to stay consistent with Windows Server + PostgreSQL already used across the team's other projects |
| Auth | Laravel Sanctum (API tokens) + Google Sign-In | First-party, easy revocation, sufficient at this scale (chosen over JWT after explicit comparison) |
| Maps | Google Maps SDK (`google_maps_flutter`) | Free unlimited rendering |
| Routing | Google Routes API | Real road-following polylines, generous free tier for this call volume |
| Place data | Google Places API (New) | Only source; no scraping (ToS/legal risk explicitly rejected) |
| AI enrichment | Gemini API (Flash/Flash-Lite) | Genuinely free ongoing tier vs. OpenAI/Claude's one-time trial credits |
| Notifications | `flutter_local_notifications` | Fully client-side, no Firebase needed |
| Geofencing | `geofence_service` (or equivalent native wrapper) | OS-level, survives app kill, battery-efficient |
| Hosting | Windows Server | Same environment for both development and deployment, decided 2026-09-07 |

---

## 15. Suggested File Structure

```
SmartTrip-Batam/
├── docs/
│   ├── superpowers/specs/
│   │   └── 2026-09-07-smarttrip-itinerary-recommendation-design.md   # source of truth
│   └── prd/
│       └── 2026-09-07-smarttrip-prd.md                                # this document
├── smarttrip-api/                     # Laravel backend (not yet scaffolded)
│   ├── app/Http/Controllers/          # Trip, Place, Admin, Auth controllers
│   ├── app/Models/                    # Place, Trip, ItineraryDay, ItineraryItem, ...
│   ├── app/Services/                  # TOPSIS scoring, K-Means clustering, route assembly
│   ├── app/Console/Commands/          # places:discover, places:enrich
│   ├── database/migrations/
│   └── database/seeders/              # categories seeder (must run before places bootstrap)
└── smarttrip-mobile/                  # Flutter app (not yet scaffolded)
    ├── lib/
    │   ├── features/
    │   │   ├── onboarding/            # Pilih Minat gate
    │   │   ├── trip_setup/
    │   │   ├── wishlist/
    │   │   ├── itinerary/
    │   │   ├── live_map/
    │   │   ├── profile/
    │   │   └── admin/                 # role-gated screens
    │   ├── core/                      # API client, auth, i18n
    │   └── main.dart
    └── ...
```

---

## 16. Acceptance Criteria

**US1 — Pilih minat & atur bobot preferensi**
- [ ] User can select 1 or more category chips from the seeded `categories` list
- [ ] User can set 4 sliders (0-10), backend normalizes to weights summing to 1
- [ ] Selections persist to `trips.interest_category_ids` / `trip_criteria_weights` on submit
- [ ] Edge case handled: 0 sliders touched still submits with equal weights (all defaulted, not blocked)
- [ ] Error state: attempting to proceed with 0 categories selected during **onboarding** is blocked (min 1 required); during regular trip setup with an existing profile default, this can't happen since it's pre-filled

**US2 — Atur jumlah hari, anggaran, tanggal trip**
- [ ] User can set `num_days` (integer ≥ 1), `budget_total` (IDR, positive integer), `start_date`
- [ ] `daily_start_time`/`daily_end_time` default to 09:00/19:00 if left unset, editable
- [ ] Values persist to `trips` on submit
- [ ] Edge case handled: `num_days` > 7 is allowed but shown a soft warning, not hard-blocked (design spec: soft cap, not a technical rule)
- [ ] Error state: `budget_total` ≤ 0 is rejected client-side before submit, with a clear inline message

**US3 — Tambah tempat ke wishlist**
- [ ] User can search the catalog and add a place to `trip_wishlist_places`
- [ ] User can add a custom pin (free-text name + lat/lng from a map tap) if the place isn't in the catalog
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

**US6 — Live map**
- [ ] All stops for the active day render as numbered pins immediately, not progressively revealed
- [ ] Polyline segments render gray when the destination stop is visited, blue otherwise
- [ ] Live user location renders and updates while the map screen is open

**US7 — Manual visit toggle**
- [ ] Long-press (or button) marks/unmarks a stop's `visited_at` regardless of geofence state
- [ ] Works when location permission was denied (feature isn't fully broken, just not automatic)

**US8 — Simpan preferensi default**
- [ ] A "simpan sebagai default" toggle during trip setup writes to `default_interest_category_ids`/`user_criteria_weights` via `PUT /api/profile/preferences`
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
- [ ] `itinerary_item_id` is populated only when the review is submitted from a post-visit "rate your trip" flow; otherwise it's null
- [ ] A submitted review is reflected in that place's Bayesian-blended rating on the next TOPSIS scoring run

**US11 — Trigger discovery (Admin)**
- [ ] Discovery re-runs do not re-insert `google_place_id`s already present in `places` or `place_candidates`, in any status (including `rejected`)
- [ ] `categories` must be seeded before the first Discovery/Enrichment run — documented setup order, not a runtime technical block

**US12 — Review & approve/reject candidates (Admin)**
- [ ] Approving a candidate triggers, in one flow: full Place Details fetch, photo download to local storage, and a single Gemini call (translation + category tags + visit duration)
- [ ] Rejecting a candidate sets `status = rejected` and it is excluded from future Discovery re-inserts (see US11)

**US13 — Admin lengkapi data**
- [ ] Admin can edit `estimated_cost_idr`, `description_override`, `description_en`, `estimated_visit_minutes`, and `category_tags` per place
- [ ] Manually editing `category_tags` sets `category_tags_reviewed = true`
- [ ] Edits take effect on the next TOPSIS scoring run without requiring a re-sync

**US14 — Dashboard admin**
- [ ] Dashboard lists places missing `estimated_cost_idr`
- [ ] Dashboard lists places with `category_tags_reviewed = false`
- [ ] Dashboard shows most-wishlisted places, average in-app rating, and trip volume
- [ ] Edge case handled: an empty dataset (before the first bootstrap) renders an empty state, not an error

> Full edge-case catalogue (beyond what's listed per-story above) lives in design spec Sections 3, 7, and 8.

---

## 17. Open Questions & Risks

- ~~**Q:** What's the target hosting environment for backend?~~ **Resolved 2026-09-07:** Windows Server + PostgreSQL, for both development and deployment.
- ~~**Q:** Riverpod vs. Provider for Flutter state management?~~ **Resolved 2026-09-07:** Riverpod - team has no prior experience with either, so no reason to prefer Provider's smaller learning curve over Riverpod's better fit for this app's async-heavy needs.
- **Risk:** Google Places Enterprise SKU quota (1,000 free calls/month) is the tightest constraint in the whole project — a rushed or careless bootstrap could burn it before the curated pool is complete — *Mitigation: the two-phase Discovery/Enrichment admin-review gate exists specifically to prevent this*
- **Risk:** Background location permission ("Allow all the time" / "Always") is a sensitive, store-reviewed permission — fine for demo/sideload, but a real blocker if the team later wants to publish to Play Store — *Mitigation: documented explicitly as out of scope for this semester (design spec Section 13)*
- **Risk:** Batam's island geography (irregular coastline, limited bridges) makes the Haversine-based day-budget travel-time estimate systematically optimistic — *Mitigation: circuity multiplier (~1.3-1.4x) applied, plus a post-hoc "padat" flag once real Routes API data comes back*
- **Tradeoff:** Choosing a fully mobile admin experience (no web panel) means admin screens like candidate review and analytics dashboards are more Flutter engineering work than a ready-made web admin tool would have been — accepted deliberately for a single mobile-only codebase
- **Tradeoff:** Open (unverified) in-app reviews vs. verified-visit-only — chosen open specifically because the Bayesian rating blend needs review volume to be useful, accepting lower per-review trust as the cost

---

## 18. Decisions Log

Key pivots made during the design process (all 2026-09-07, in one extended design session):

| Decision | Why |
|----------|-----|
| True pairwise AHP → direct-rating sliders + TOPSIS | Simpler mobile UX; same personalized-weight outcome without the pairwise-comparison UI overhead |
| Guest trips → login required from the start | Deliberate simplification — removed the guest-trip-token mechanism and its conditional auth logic entirely |
| JWT → Laravel Sanctum (API tokens) | Easier revocation, first-party Laravel support, sufficient at this project's scale |
| Web/Blade admin panel → role-gated Flutter screens | Committed to a fully mobile-only architecture, one codebase for users and admins |
| Single-shot Google sync → two-phase Discovery/Enrichment | The Enterprise SKU's 1,000/month quota is too tight for a naive one-shot sync; needed an admin-reviewed gate before spending it |
| Manual admin translation → Gemini auto-translation | Once the quota concern was correctly isolated to Place *Details* fetches (not text translation), there was no reason to hand-translate |
| Auto-assume skipped stops as "visited" → explicit manual-only resolution | A real skip is a valid user scenario, not just GPS error — false inference would hide genuine plan changes |

---

## 19. Rollout & Next Steps

**MVP scope:** Effectively the entire design spec as documented — for a 6-person, 1-semester team, there isn't much room for a smaller "true MVP" cut without undermining the thesis-worthy parts (the algorithm pipeline) or the differentiators (live tracking, AI enrichment). If time pressure hits mid-semester, the safest things to defer first would be: bilingual EN content, the live-map notification piggyback, and admin dashboard charts (keep the underlying data/lists, drop the visualization polish).

**Rough phase breakdown** *(illustrative, relative to semester start — no actual semester calendar was provided, so no real dates are given; replace with real milestones once the team has one)*:
- **Phase 1:** Backend scaffolding, data model migrations, Google Places bootstrap (categories seed → Discovery → first Enrichment batch)
- **Phase 2:** Core algorithm implementation (TOPSIS/K-Means/NN) + unit tests, Flutter trip-setup/wishlist/generate flow
- **Phase 3:** Live map + geofencing, swap, admin screens, AI enrichment pipeline
- **Phase 4:** Profile preferences, Google Sign-In, bilingual support, reviews, polish + testing, demo prep

**Phase 2+ ideas** *(explicitly out of scope this semester, per design spec Section 13)*:
- Multi-city expansion
- Booking/payment integration
- Itinerary sharing/collaboration
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
- **Environment configuration (dev/staging/prod):** not discussed — deferred to implementation planning, where the actual hosting decision (Section 17 open question) will shape this

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

---

*Source of truth for implementation detail remains the design spec at `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` — this PRD is a reformatted, audience-oriented view of the same decisions, not a competing document. Where they ever conflict, the design spec wins since it has finer-grained rationale.*
</content>
