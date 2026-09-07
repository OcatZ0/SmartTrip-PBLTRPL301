# SmartTrip Batam - Product Requirements Document

## 1. Overview

**Feature / Project Name:** SmartTrip Batam - Sistem Rekomendasi Itinerary Liburan Berbasis Preferensi Pengguna

**Problem Statement:**
Wisatawan Batam kesulitan menentukan destinasi wisata dan kuliner yang sesuai dengan minat, lokasi, waktu, dan anggaran mereka, karena informasi tersebar di berbagai platform dan butuh usaha untuk membandingkan. Banyak wisatawan tidak punya perencanaan terstruktur, sehingga rute perjalanan jadi tidak efisien dan destinasi menarik terlewatkan.

**Proposed Solution:**
Aplikasi mobile yang merekomendasikan tempat wisata/kuliner/hotel sesuai preferensi pengguna (minat, jarak, anggaran, rating) memakai Weighted-TOPSIS, lalu otomatis menyusun jadwal perjalanan multi-hari dengan pengelompokan lokasi (K-Means) dan urutan rute (Nearest-Neighbor + Google Routes API), termasuk pelacakan progres kunjungan secara live.

**AI Build Summary:**
> Build a Laravel 12 REST API backend + single Flutter mobile app (role-gated for both end-users and admins, no separate web panel) for a Batam trip-itinerary recommender. Auth via Laravel Sanctum (opaque tokens) with email/password and Google Sign-In. Core algorithm pipeline: user-weighted TOPSIS scoring (4 criteria: category-fit via Jaccard similarity, distance via Haversine, budget via a 4-tier fallback chain, rating via a Bayesian Google+in-app blend) → K-Means day clustering → Nearest-Neighbor route ordering → Google Routes API for real road polylines. Place data sourced exclusively from Google Places API (New) via an admin-reviewed two-phase Discovery/Enrichment pipeline (never scraped from other platforms), enriched by Gemini (free tier) for translation, category tagging, and visit-duration estimation. Live trip map with GPS-geofencing-based visit tracking. No booking/payment, no multi-city, no web admin panel, one-semester scope for a 6-person student team.

---

## 2. Goals & Success Metrics

**Primary Goal:** Ship a working, demonstrable end-to-end app (not just a design) within one semester that a 6-person team can build, covering the full loop from admin data curation through personalized itinerary generation to live in-trip tracking.

**Success Metrics** *(proxies appropriate for a pre-launch student project, not live-usage metrics — adjust if you have specific skripsi/demo-day targets)*:
- A generated itinerary for a realistic Batam trip (3-5 days, real preferences) completes end-to-end (weights → TOPSIS → K-Means → NN → Routes API) in a single demo run without manual intervention
- The initial place-data bootstrap (Discovery → admin review → Enrichment) reaches the ~300-500 place target while staying inside Google's free API tiers (Pro 5,000/mo, Enterprise 1,000/mo)
- Core algorithm units (weight normalization, TOPSIS scoring, Haversine, K-Means, Bayesian rating blend) pass deterministic unit tests, since this is the part most likely to be questioned in a demo/defense
- Live map + geofencing visit-tracking demonstrably works on at least one real Android device outdoors (not just emulator)

**Anti-goals** *(explicitly NOT trying to do — see Section 3 for the full list)*:
- Not trying to support booking/payment/reservation
- Not trying to support more than one city this semester
- Not trying to build a web admin panel (mobile-only, role-gated)
- Not trying to achieve Play Store publish-readiness (background location permission justification/privacy policy work is out of scope)

---

## 3. Scope & Constraints

**In scope:** everything in the accompanying design spec — trip creation, wishlist, preference sliders + minat selection, hotel resolution (search or custom pin), TOPSIS/K-Means/NN/Routes generation pipeline, swap, live map with geofencing, in-app reviews, profile preference defaults, mandatory onboarding, Google Sign-In, and the full admin data-curation loop (Discovery → review → Enrichment → AI tagging/translation → ongoing curation).

**Out of scope** (see design spec Section 13 for full detail):
- Booking/reservation/payment of any kind
- Multi-city support (no `city` field anywhere; Batam-only, hardcoded area list)
- Web admin panel (all admin functionality is role-gated inside the same Flutter app)
- Scraping any platform besides Google Places (TripAdvisor/Traveloka/Tiket.com explicitly rejected — ToS/legal risk)
- True pairwise AHP (replaced with simpler direct-rating sliders)
- Itinerary sharing/collaboration between users
- Automatic re-routing when a user deviates from the planned route
- Play Store/App Store publish readiness
- Per-day time windows (single trip-wide `daily_start_time`/`daily_end_time` only)
- Mid-trip hotel changes (one hotel = one trip's start/end point)

**Technical constraints:**
- Platform: **Android/iOS via Flutter** (single codebase for end-users and admins)
- Auth: Laravel Sanctum (opaque bearer tokens), email/password + Google Sign-In, account linking by email
- Accessibility level: **not yet specified** — flagging as an open question (Section 14) rather than assuming a WCAG target that was never discussed
- Offline support: **partial only** — visit-tracking events queue locally and retry when connectivity returns; no general offline browsing/generation support was designed
- Performance: not formally targeted with numbers; Google Routes API is called once per day per generate/swap (not per view) specifically to keep this fast and cheap
- Data residency/compliance: none specified (not a concern raised for this project)
- Budget-hard constraint: Google Places Enterprise SKU capped at 1,000 free calls/month — directly shaped the two-phase Discovery/Enrichment architecture

---

## 4. Jobs to Be Done (JTBD)

| Priority | Job Statement |
|----------|---------------|
| 1 | When I'm planning a trip to Batam without local knowledge, I want a personalized day-by-day itinerary based on my interests, budget, and available time, so I can spend my trip enjoying it instead of researching it. |
| 2 | When I'm actually out on my trip, I want to see my planned route and know what I've already visited, so I don't get lost or lose track of my schedule. |
| 3 | When I already have specific places I want to visit (that I found elsewhere), I want to add them to my plan and have the system build the rest of the schedule around them, so I don't lose the personal research I already did. |
| 4 | When I'm the team managing the app's place data, I want a controlled way to bring new places into the system without blowing our API budget, so the recommendation quality stays high without unsustainable cost. |

---

## 5. User Stories

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

## 6. Proposed Experience

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

**Accessibility Notes:** *(open question — see Section 14, never formally discussed)*
- Keyboard navigation: N/A (mobile touch app)
- Screen reader considerations: not yet specified
- Color contrast: gray/blue polyline distinction (Section 8) should be checked against color-blind accessibility, not yet validated

**Figma / Design Link:** none — no visual design phase happened, this PRD and the design spec are text-only artifacts

---

## 7. Component Inventory

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

## 8. Data Models

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

---

## 9. API / Integration Surface

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
- Google Cloud Translation / Gemini API — bilingual content + AI category tagging (Gemini chosen for its genuine free tier)
- `geolocator` — device GPS, no API
- `geofence_service` (or equivalent) — OS-level geofencing for visit detection
- `flutter_local_notifications` — day-start and proximity reminders, fully local

---

## 10. State Management Map

*(This was never explicitly decided in our design discussion — proposing a default here, adjust as needed.)*

| State | Location | Persistence | Notes |
|-------|----------|-------------|-------|
| Auth token | Local secure storage (`flutter_secure_storage`) | Persistent | Sanctum bearer token |
| Active trip being built (setup/wishlist/weights before generate) | Local UI state (proposed: **Riverpod**) | Session (survives navigation, not app restart) | Multi-step wizard state |
| Generated itinerary | Server (source of truth) + local cache for offline viewing | Persistent (server), cached locally | Re-fetched via `GET /api/trips/{id}` |
| Live GPS position | Local UI state (stream) | None | From `geolocator`, not persisted |
| Geofence registration | OS-level (native, outside Flutter widget tree) | Persistent until deregistered | Survives app kill (Section 8 of design spec) |
| Pending offline visit events | Local SQLite/shared prefs queue | Persistent until synced | Section 8 edge case handling |
| Profile default preferences | Server + local cache | Persistent (server) | `user_criteria_weights` |
| Language selection | Local (`shared_preferences`) | Persistent | Client-side only, no backend |

**Recommendation:** Riverpod over Provider/Bloc — good fit for this app's async-heavy nature (API calls, geofence streams, live location), reasonable learning curve for a student team, strong testability. Open to Provider instead if the team already has more experience with it — this is a low-stakes choice either way at this scale.

---

## 11. Tech Stack Recommendation

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Backend | Laravel 12 (PHP), REST API only | Team's established stack; no Blade views needed (mobile-only) |
| Mobile | Flutter | Single codebase for iOS/Android, single app for users + role-gated admin |
| State management | Riverpod (proposed) | See Section 10 |
| Database | MySQL | Standard Laravel pairing per team convention |
| Auth | Laravel Sanctum (API tokens) + Google Sign-In | First-party, easy revocation, sufficient at this scale (chosen over JWT after explicit comparison) |
| Maps | Google Maps SDK (`google_maps_flutter`) | Free unlimited rendering |
| Routing | Google Routes API | Real road-following polylines, generous free tier for this call volume |
| Place data | Google Places API (New) | Only source; no scraping (ToS/legal risk explicitly rejected) |
| AI enrichment | Gemini API (Flash/Flash-Lite) | Genuinely free ongoing tier vs. OpenAI/Claude's one-time trial credits |
| Notifications | `flutter_local_notifications` | Fully client-side, no Firebase needed |
| Geofencing | `geofence_service` (or equivalent native wrapper) | OS-level, survives app kill, battery-efficient |
| Hosting | Not yet decided | Open question — see Section 14 |

---

## 12. Suggested File Structure

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

## 13. Acceptance Criteria

**US1 — Pilih minat & atur bobot preferensi**
- [ ] User can select 1 or more category chips from the seeded `categories` list
- [ ] User can set 4 sliders (0-10), backend normalizes to weights summing to 1
- [ ] Selections persist to `trips.interest_category_ids` / `trip_criteria_weights` on submit
- [ ] Edge case handled: 0 sliders touched still submits with equal weights (all defaulted, not blocked)
- [ ] Error state: attempting to proceed with 0 categories selected during **onboarding** is blocked (min 1 required); during regular trip setup with an existing profile default, this can't happen since it's pre-filled

**US4 — Generate itinerary**
- [ ] `POST /api/trips/{id}/generate` returns a full day-by-day itinerary within a reasonable time for a demo (no hard SLA defined — flag if this becomes an issue)
- [ ] Each day's stops respect the daily time window (visit duration + estimated travel time ≤ window)
- [ ] No place appears on more than one day within the same generate run
- [ ] Edge case handled: insufficient candidate pool returns a "tidak muat" flag rather than an error or silently duplicated content
- [ ] Edge case handled: real Routes API travel time significantly exceeding the estimate flags the day "padat" post-generation

**US6 — Live map**
- [ ] All stops for the active day render as numbered pins immediately, not progressively revealed
- [ ] Polyline segments render gray when the destination stop is visited, blue otherwise
- [ ] Live user location renders and updates while the map screen is open

**US7 — Manual visit toggle**
- [ ] Long-press (or button) marks/unmarks a stop's `visited_at` regardless of geofence state
- [ ] Works when location permission was denied (feature isn't fully broken, just not automatic)

**US11/US12 — Admin discovery & review**
- [ ] Discovery re-runs do not re-insert `google_place_id`s already in `places` or `place_candidates` in any status (including `rejected`)
- [ ] Approving a candidate triggers full Place Details fetch + photo download + Gemini enrichment (translation, tags, duration) in one flow
- [ ] `categories` must be seeded before the first Discovery/Enrichment run (dependency ordering, not a technical block, but a documented setup order)

> Full edge-case catalogue lives in design spec Sections 3, 7, and 8 — this section surfaces the highest-signal, most testable subset rather than duplicating everything.

---

## 14. Open Questions & Risks

- **Q:** What's the target hosting environment for backend + how does the team demo this (local, shared server, cloud)? — *Owner: Team, not yet decided*
- **Q:** What accessibility level (if any) is expected for the app? — *Owner: Team — never discussed in the design phase*
- **Q:** Riverpod vs. Provider for Flutter state management — this PRD proposes Riverpod, but the actual mobile team's prior experience should have the final say — *Owner: Mobile team*
- **Risk:** Google Places Enterprise SKU quota (1,000 free calls/month) is the tightest constraint in the whole project — a rushed or careless bootstrap could burn it before the curated pool is complete — *Mitigation: the two-phase Discovery/Enrichment admin-review gate exists specifically to prevent this*
- **Risk:** Background location permission ("Allow all the time" / "Always") is a sensitive, store-reviewed permission — fine for demo/sideload, but a real blocker if the team later wants to publish to Play Store — *Mitigation: documented explicitly as out of scope for this semester (design spec Section 13)*
- **Risk:** Batam's island geography (irregular coastline, limited bridges) makes the Haversine-based day-budget travel-time estimate systematically optimistic — *Mitigation: circuity multiplier (~1.3-1.4x) applied, plus a post-hoc "padat" flag once real Routes API data comes back*
- **Tradeoff:** Choosing a fully mobile admin experience (no web panel) means admin screens like candidate review and analytics dashboards are more Flutter engineering work than a ready-made web admin tool would have been — accepted deliberately for a single mobile-only codebase
- **Tradeoff:** Open (unverified) in-app reviews vs. verified-visit-only — chosen open specifically because the Bayesian rating blend needs review volume to be useful, accepting lower per-review trust as the cost

---

## 15. Rollout & Next Steps

**MVP scope:** Effectively the entire design spec as documented — for a 6-person, 1-semester team, there isn't much room for a smaller "true MVP" cut without undermining the thesis-worthy parts (the algorithm pipeline) or the differentiators (live tracking, AI enrichment). If time pressure hits mid-semester, the safest things to defer first would be: bilingual EN content, the live-map notification piggyback, and admin dashboard charts (keep the underlying data/lists, drop the visualization polish).

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
3. Resolve the three open questions in Section 14 before or during planning, not after — *Owner: Team*

---

*Source of truth for implementation detail remains the design spec at `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` — this PRD is a reformatted, audience-oriented view of the same decisions, not a competing document. Where they ever conflict, the design spec wins since it has finer-grained rationale.*
</content>
