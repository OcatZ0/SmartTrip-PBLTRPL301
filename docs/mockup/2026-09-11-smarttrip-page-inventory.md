# SmartTrip Batam - Page Inventory for Mockup

Source: `docs/superpowers/specs/2026-09-07-smarttrip-itinerary-recommendation-design.md` + `docs/prd/2026-09-07-smarttrip-prd.md` (v1.6). One Flutter app, role-gated - the Admin section (G) is the same app, not a separate build.

26 screens total: 19 end-user, 7 admin (C2a is one shared reusable screen, used by both the wishlist and hotel flows).

---

## A. Onboarding & Auth

### A1. Splash / Language Selection
**Purpose:** First screen on cold start. Sets language before anything else renders.
**Info shown:** App logo/name, brief tagline.
**Buttons:** Bahasa Indonesia / English (2 options, large tap targets). Auto-selects device language as default, this screen may auto-skip if already set previously (`shared_preferences`).
**Navigates to:** Home (A2 in flow terms, but see B1 below).

### A2. Login
**Purpose:** Email/password or Google sign-in. Reached from Home when tapping "Buat Trip" while logged out.
**Info shown:** App logo, "Masuk" header.
**Fields:** Email, Password.
**Buttons:** "Masuk" (primary), "Masuk pakai Google" (secondary, `google_sign_in` flow), "Belum punya akun? Daftar" (link to A3). No "continue as guest" option anywhere on this screen - that path was deliberately removed from scope.
**Error states:** Invalid credentials, invalid/expired Google token (US9 AC).

### A3. Register
**Purpose:** New account creation.
**Fields:** Name, Email, Password, Confirm Password.
**Buttons:** "Daftar" (primary), "Daftar pakai Google" (secondary), "Sudah punya akun? Masuk" (link back to A2).
**Behavior:** On success, always routes through A4 next (see below) - registration never lands directly on Home.

### A4. Pilih Minat (Onboarding Gate)
**Purpose:** Mandatory first-time interest selection. **Condition-gated, not event-gated** - shown on every app launch/login while `default_interest_category_ids` is empty, not just once right after registering (this is what makes it survive a user closing the app mid-onboarding).
**Info shown:** Short instruction text ("Pilih minimal 1 kategori yang kamu suka").
**Content:** Grid/wrap of category chips, pulled from `categories` (alam, kuliner seafood, belanja, sejarah, etc.) - multi-select.
**Buttons:** "Lanjut" (primary, disabled/greyed until ≥1 chip selected - this screen has no skip option).
**Blocking:** Cannot navigate away (no back button that escapes it) until submitted.
**On submit:** `PUT /api/profile/preferences`, then continues to wherever the user was headed (Home, or straight into Trip Setup if they'd tapped "Buat Trip" pre-login).

---

## B. Browse & Discovery

### B1. Home
**Purpose:** Landing screen, works fully without login.
**Info shown:** Featured/recent places, category filter chips.
**Content:** `PlaceCatalogGrid` - infinite-scroll grid/list of place cards (`PlaceCard`: thumbnail, name, category badge, rating, price tier).
**Buttons:** Category filter chips (multi-select), search bar, "+ wishlist" quick-add on each card (only meaningful once inside an active trip - see note below), tap card → C2 Place Detail. Bottom nav: Home / Trips / Profile (+ Admin tab if `role=admin`).
**Primary CTA:** "Buat Trip" (floating action button or prominent header button) → gated by A2 login if not authenticated.
**Empty state:** Katalog kosong (before first admin bootstrap) - "Belum ada data tempat, coba lagi nanti."

### B2. Place Detail
**Purpose:** Full info on one place. Reachable from Home, Wishlist browsing, Swap search, or a stop inside an itinerary.
**Info shown:** Photo carousel (`place_photos`), name, category tags, address, phone, website, opening hours, blended rating (Google + in-app, Bayesian), price tier/estimated cost, description (bilingual, falls back ID→shown if EN empty), "Buka di Google Maps" link (`google_maps_uri`).
**Buttons:** "+ Wishlist" (if inside an active trip-building flow), "Tulis Review" (opens D5), "Buka di Google Maps" (external), back.
**Reviews section:** List of existing `place_reviews` (rating + comment), average shown at top.
**Empty state:** No reviews yet - "Jadi yang pertama kasih review."

---

## C. Trip Creation Wizard

Reached only when authenticated (A2 gate applies before C1).

### C1. Trip Setup
**Purpose:** Step 1 of wizard - trip-level basics.
**Fields:** Jumlah hari (`num_days`, stepper, soft warning above 7), Anggaran total (`budget_total`, IDR input), Tanggal mulai (`start_date`, date picker), Jam mulai/selesai harian (`daily_start_time`/`daily_end_time`, optional, defaults 09:00/19:00 shown pre-filled), toggle "Sudah punya hotel?".
**Buttons:** "Lanjut" (primary, validates `budget_total` > 0 client-side before proceeding), back (discards wizard progress with a confirm dialog).
**Progress indicator:** Step 1 of ~4 (Trip Setup → Wishlist → Minat & Preferensi → Hotel → generate).

### C2. Wishlist Builder
**Purpose:** Optional - add must-visit places before generating.
**Content:** Same `PlaceCatalogGrid` pattern as B1, but with a persistent "+ wishlist" button per card and a running count ("3 tempat ditambahkan").
**Buttons:** "Tambah manual" (opens C2a map picker for places not in the catalog), "Lanjut" (proceeds even with 0 wishlist items - fully optional), "Lewati" (skip straight past), back.
**List view:** Toggle or separate tab showing currently-added wishlist items with a remove (×) button each.

### C2a. Custom Pin Picker (modal/full-screen)
**Purpose:** Add a place not in the catalog - reused identically for wishlist custom-add and for hotel custom-add (C4a).
**Content:** `google_maps_flutter` map, tap/drag to drop a pin, free-text name field below the map.
**Buttons:** "Simpan" (commits name + lat/lng), "Batal".
**Note:** No address-typing/autocomplete (would need Geocoding API, deliberately out of scope) - map tap only.

### C3. Pilih Minat + Slider Preferensi (trip-level)
**Purpose:** Two distinct things on one screen - which categories matter for this specific trip, and how much each of the 4 scoring criteria should weigh.
**Content, part 1 (minat):** Same chip-select as A4, **pre-filled** from `default_interest_category_ids` if set - editable for this trip without changing the saved default.
**Content, part 2 (bobot):** 4 sliders, 0-10 each: Kesesuaian kategori/minat, Jarak/lokasi, Kesesuaian anggaran, Rating/popularitas. Pre-filled from `user_criteria_weights` if set.
**Buttons:** Toggle "Simpan sebagai default" (off by default, opt-in - writing back to profile only happens if explicitly checked), "Lanjut", back.

### C4. Hotel Selection
**Purpose:** Resolve the trip's fixed start/end point.
**Branch A - "Sudah punya hotel" was toggled on (C1):** Search field (typeahead against `places` where `type=lodging`) → tap result to select, OR "Tidak ketemu?" → opens C2a-style map picker.
**Branch B - no hotel yet:** System runs the lighter 3-criteria TOPSIS pass, shows **top-3 hotel cards** (name, photo, price tier, rating, distance from area) with a select button on each.
**Buttons:** "Lanjut" (only enabled once a hotel is resolved either way), back.

### C5. Generating (Loading)
**Purpose:** Transitional screen while `POST /api/trips/{id}/generate` runs the full pipeline (TOPSIS → K-Means → NN → Routes API).
**Content:** Skeleton/spinner, short rotating status text is optional polish ("Menyusun rute...", "Menghitung skor tempat...").
**No buttons** - not cancellable in v1 (not specified as a requirement; keep simple).
**Error state:** If generation fails or returns a "tidak muat" flag, route to D1 anyway with that flag surfaced there rather than blocking here.

---

## D. Itinerary & Trip Management

### D1. Itinerary Result
**Purpose:** The main payoff screen - the generated (or reopened) trip.
**Info shown:** Trip title/dates header, day tabs or a vertically scrollable list of day cards.
**Per-day card content:** Day number/date, list of stops in visit order, each stop showing thumbnail, name, source badge (Wishlist / Recommended), estimated visit time. `WeatherForecastCard` appears on a day's header once `start_date` is within ~7 days. "Padat"/"tidak muat" flag banner if that day hit either condition during generation.
**Per-stop buttons:** Tap → B2 Place Detail, "..." menu → Swap (opens D2).
**Per-day buttons:** "Buka Peta" (opens E1 Live Map for that day), `WeatherSwapBadge` (only shown if outdoor stop + rain forecast - tapping jumps straight into D2 pre-scoped to that stop).
**Screen-level buttons:** "Edit Trip" (routes back into C1 with fields pre-filled - changing num_days/budget/hotel triggers a full regenerate, confirmed via dialog before submitting), "Hapus Trip" (confirm dialog), back to D3.

### D2. Swap Modal
**Purpose:** Replace one stop without touching the rest of the day.
**Content:** Two tabs/sections - "Rekomendasi" (ranked TOPSIS alternatives, same category/area radius) and "Cari Manual" (full `PlaceCatalogGrid`-style search).
**Buttons:** Tap a candidate card to select it as the replacement, "Batal".
**On commit:** Re-runs Nearest-Neighbor for just that day, refreshes only the affected leg's polyline - modal closes back to D1 with that day's card updated.

### D3. Saved Trips List
**Purpose:** All of the logged-in user's trips.
**Content:** List of trip cards - title, date range, day count, small thumbnail/preview.
**Buttons:** Tap card → D1 (that trip), "Buat Trip" (starts a new C1 flow), swipe-to-delete or a "..." menu per card with "Hapus" (confirm dialog).
**Empty state:** No trips yet - "Trip pertamamu tinggal 1 tap lagi" + prominent "Buat Trip" CTA.

### D4. Weather Forecast Detail (optional expanded view)
**Purpose:** Tapping `WeatherForecastCard` on D1 can either just show a tooltip inline, or expand to this small detail sheet - team's call on fidelity, listed here for completeness.
**Content:** Fuller per-day breakdown (temp range, rain probability, short description) sourced directly from Open-Meteo client-side.
**Buttons:** Close/dismiss.

### D5. Review Form
**Purpose:** Rate/review a place. Reachable from B2 (general review, `itinerary_item_id` stays null) or from a post-visit prompt on D1/E1 for a stop with `visited_at` set (`itinerary_item_id` populated).
**Fields:** Star rating (1-5, required), comment (optional, multi-line).
**Buttons:** "Kirim", "Batal".

---

## E. Live Trip Experience

### E1. Live Map (per active day)
**Purpose:** The GMaps-nav-style live tracking screen, opened from D1's "Buka Peta".
**Content:** `google_maps_flutter` map - hotel/start marker, numbered pins for every stop (all visible at once, not progressively revealed), per-leg polylines colored **gray** (visited) / **blue** (not yet), live user-location dot, `GeofenceStatusIndicator` (small badge confirming tracking is active), `WeatherForecastCard` if within the 7-day window.
**Buttons:** "Mulai Hari Ini" (first tap of the day - registers OS-level geofences for this day's unvisited stops, starts the whole tracking flow), long-press any pin → `ManualVisitToggle` (mark/unmark visited, works regardless of geofence state), tap a pin → mini info card with "..." → Swap (D2), back to D1.
**Notifications triggered from here (not a screen, but relevant):** proximity "sudah dekat stop berikutnya" local notification when a geofence fires, `WeatherSwapBadge` prompt if applicable.
**Permission flow:** First "Mulai Hari Ini" tap triggers the OS background-location permission prompt; if denied, map still works, just falls back to manual-only visit marking (no silent failure).

---

## F. Account

### F1. Profile
**Purpose:** Account-level settings, independent of any specific trip.
**Info shown:** Name, email, account type (password / Google-linked).
**Content:** `ProfilePreferencesScreen` - same chip-select + 4-slider UI as C3, but editing `default_interest_category_ids`/`user_criteria_weights` directly (`GET/PUT /api/profile/preferences`).
**Buttons:** "Simpan", `LanguageToggle` (ID/EN), "Keluar" (logout, confirm dialog).

---

## G. Admin (role-gated, same app - extra tab appears only when `role=admin`)

### G1. Admin Home / Dashboard
**Purpose:** Landing screen for the Admin tab.
**Content (`AdminDashboard`):** Cards/charts - tempat paling di-wishlist, rata-rata rating in-app, volume trip, **daftar tempat belum ada `estimated_cost_idr`** (actionable list, tap → G4 edit form), **daftar tempat `category_tags_reviewed=false`** (actionable list, tap → G4), last sync status (when Discovery/Enrichment last ran, how many candidates pending).
**Buttons:** Quick links into G2 (Candidates), G3 (Places list), G5 (Categories).
**Empty state:** Before first bootstrap - "Belum ada data, mulai dari Discovery" + button straight into G2's trigger action.

### G2. Place Candidates Review
**Purpose:** The Discovery → Enrichment gate (US11/US12).
**Buttons (top):** "Cari Tempat Baru" (triggers `POST /api/admin/places/discover` - runs across all area × category combos, shows a progress/toast when done).
**Content:** Filterable list (`CandidateReviewList`) by `search_area` and `status` (pending/approved/rejected). Each row: name, rough type, area, google_place_id.
**Per-row buttons:** "Approve" (triggers the full Place Details + photo + Gemini enrichment chain, then the row disappears from pending), "Reject" (sets `rejected`, excluded from future Discovery re-inserts).
**Bulk actions:** Multi-select checkboxes + bulk Approve/Reject.

### G3. Places List (Admin)
**Purpose:** Browse/search all live `places`, entry point to edit any of them.
**Content:** Searchable/filterable list (by type, business_status, missing-data flags).
**Buttons:** Tap row → G4, "+ Tambah Manual" (place not from Google - opens G4 in create mode).

### G4. Place Edit Form (Admin)
**Purpose:** CRUD for a single place's admin-owned fields.
**Fields:** `estimated_cost_idr`, `estimated_visit_minutes`, `is_outdoor` (toggle), `category_tags` (multi-select from `categories`, editing this sets `category_tags_reviewed=true`), `description_override`, `description_en`. Read-only display of Google-sourced fields (name, rating, address, etc.) for context.
**Buttons:** "Simpan", "Hapus" (only for `source=manual` places), back.

### G5. Categories List (Admin)
**Purpose:** Manage the `categories` taxonomy.
**Content:** List of categories (name_id, name_en, slug).
**Buttons:** "+ Tambah Kategori" (opens G6), tap row → G6 (edit), delete icon per row (confirm dialog, warns if in use).

### G6. Category Edit Form (Admin)
**Fields:** name_id, name_en, slug (auto-suggested from name_id, editable, uniqueness validated).
**Buttons:** "Simpan", "Batal".

### G7. Sync Status (Admin)
**Purpose:** Operational visibility - when Discovery/Enrichment last ran, quota usage awareness.
**Content:** Last Discovery run timestamp + area/category coverage, last Enrichment batch stats (approved count, failures), Google API quota usage indicator (rough count against the 1,000/month Enterprise cap) - ties to the Observability section of the PRD.
**Buttons:** Link back to G2 to act on pending candidates.

---

## Summary Table

| # | Screen | Section |
|---|--------|---------|
| A1 | Splash / Language | Onboarding |
| A2 | Login | Onboarding |
| A3 | Register | Onboarding |
| A4 | Pilih Minat (gate) | Onboarding |
| B1 | Home | Browse |
| B2 | Place Detail | Browse |
| C1 | Trip Setup | Wizard |
| C2 | Wishlist Builder | Wizard |
| C2a | Custom Pin Picker | Wizard (shared w/ C4) |
| C3 | Minat + Slider (trip) | Wizard |
| C4 | Hotel Selection | Wizard |
| C5 | Generating (loading) | Wizard |
| D1 | Itinerary Result | Trip Mgmt |
| D2 | Swap Modal | Trip Mgmt |
| D3 | Saved Trips List | Trip Mgmt |
| D4 | Weather Detail (optional) | Trip Mgmt |
| D5 | Review Form | Trip Mgmt |
| E1 | Live Map | Live Trip |
| F1 | Profile | Account |
| G1 | Admin Dashboard | Admin |
| G2 | Candidate Review | Admin |
| G3 | Places List | Admin |
| G4 | Place Edit Form | Admin |
| G5 | Categories List | Admin |
| G6 | Category Edit Form | Admin |
| G7 | Sync Status | Admin |

**19 end-user screens (A1-F1) + 7 admin screens (G1-G7) = 26 distinct screens.** C2a is one reusable screen shared by both the wishlist custom-add and hotel custom-add flows, not two separate builds. D4 is optional polish - a team pressed for time could fold its content into a D1 tooltip instead of a full screen.
</content>
