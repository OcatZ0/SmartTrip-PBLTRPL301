<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Services\Itinerary\HotelRecommender;
use App\Services\Itinerary\ItineraryGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\ProhibitedIf;
use Illuminate\Validation\ValidationException;
use RuntimeException;

/**
 * Trip setup + F008 (docs/prd design spec Section 7 & 12).
 */
class TripController extends Controller
{
    /**
     * Places whose photos the Trip Tersimpan card shows, at most.
     */
    private const CARD_PHOTO_LIMIT = 4;

    /**
     * F011: daftar trip yang pernah dibuat user login - punya sendiri saja
     * (bukan yang dibagikan ke dia - itu GET /api/trips/shared, F016).
     * Terurut trip terbaru dulu. Each trip also carries a "summary" for the
     * Trip Tersimpan card (see tripSummary()).
     */
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $trips = $request->user()->trips()
            ->withCount(['days as days_count' => fn ($days) => $days->whereHas('items')])
            ->with([
                'days' => fn ($days) => $days->orderBy('day_number'),
                'days.items' => fn ($items) => $items->orderBy('visit_order'),
                'days.items.place:places_id,photo_url,estimated_cost_idr',
                'wishlistPlaces.place:places_id,photo_url',
            ])
            ->orderByDesc('created_at')
            ->paginate($perPage);

        // Trip dates are Batam dates.
        $today = now('Asia/Jakarta')->startOfDay();
        $trips->getCollection()->transform(function (Trip $trip) use ($today) {
            $trip->setAttribute('summary', $this->tripSummary($trip, $today));

            // Loaded only for the summary; the list stays as light as before.
            return $trip->unsetRelation('days')->unsetRelation('wishlistPlaces');
        });

        return response()->json($trips);
    }

    /**
     * What the Trip Tersimpan card shows for one trip:
     * - status: "draft" until an itinerary is generated, then "akan_datang",
     *   "berlangsung" or "selesai" from start_date and num_days (Batam time)
     * - current_day: the trip day today is, only while "berlangsung"
     * - places_count and visited_count: itinerary stops and those marked visited
     * - wishlist_count: places in the trip wishlist
     * - spent_estimate_idr: the estimated cost of the visited places (a guess
     *   from places.estimated_cost_idr; the app does not track real spending)
     * - photo_urls: up to four place photos, itinerary order first, then the wishlist
     */
    private function tripSummary(Trip $trip, Carbon $today): array
    {
        $items = $trip->days->flatMap->items;
        $start = $trip->start_date ? Carbon::parse($trip->start_date->toDateString(), 'Asia/Jakarta') : null;
        $end = $start?->copy()->addDays(max(1, (int) $trip->num_days) - 1);

        $status = match (true) {
            $items->isEmpty() || $start === null => 'draft',
            $today->lt($start) => 'akan_datang',
            $today->gt($end) => 'selesai',
            default => 'berlangsung',
        };

        $photos = $items->map(fn ($item) => $item->place?->photo_url)
            ->merge($trip->wishlistPlaces->map(fn ($wishlist) => $wishlist->place?->photo_url))
            ->filter()
            ->unique()
            ->take(self::CARD_PHOTO_LIMIT)
            ->values();

        $visited = $items->whereNotNull('visited_at');

        return [
            'status' => $status,
            'current_day' => $status === 'berlangsung' ? (int) $start->diffInDays($today) + 1 : null,
            'places_count' => $items->count(),
            'visited_count' => $visited->count(),
            'wishlist_count' => $trip->wishlistPlaces->count(),
            'spent_estimate_idr' => (int) $visited->sum(fn ($item) => $item->place?->estimated_cost_idr ?? 0),
            'photo_urls' => $photos->all(),
        ];
    }

    /**
     * F016: tab "Dibagikan ke Saya" - trip yang di-share ke user login
     * sebagai viewer (baris trip_viewers), bukan trip miliknya sendiri.
     * Terurut kapan diundang (added_at) terbaru dulu.
     */
    public function shared(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $trips = $request->user()->sharedTrips()
            ->withCount(['days as days_count' => fn ($days) => $days->whereHas('items')])
            ->orderByDesc('trip_viewers.added_at')
            ->paginate($perPage);

        return response()->json($trips);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'num_days' => ['required', 'integer', 'min:1'],
            'budget_total' => ['required', 'integer', 'min:1'],
            'start_date' => ['required', 'date'],
            'daily_start_time' => ['nullable', 'date_format:H:i'],
            'daily_end_time' => ['nullable', 'date_format:H:i', 'after:daily_start_time'],
            'has_own_hotel' => ['sometimes', 'boolean'],
        ]);

        $trip = $request->user()->trips()->create([
            'title' => $data['title'] ?? 'Trip Batam',
            'num_days' => $data['num_days'],
            'budget_total' => $data['budget_total'],
            'start_date' => $data['start_date'],
            'has_own_hotel' => $data['has_own_hotel'] ?? false,
            ...array_filter([
                'daily_start_time' => $data['daily_start_time'] ?? null,
                'daily_end_time' => $data['daily_end_time'] ?? null,
            ]),
        ]);
        $trip->syncDays();

        return response()->json($trip, 201);
    }

    public function show(Request $request, Trip $trip)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        // Hasil itinerary (D1) dan peta live (E1) butuh nama/koordinat/foto
        // tiap stop dan titik awal/akhir tiap hari sekaligus.
        return response()->json($this->withDays($trip));
    }

    /**
     * The trip with its days, stops and where each day starts and ends
     * (start / end: the day's own point, its end falling back to its start).
     */
    private function withDays(Trip $trip): Trip
    {
        $placeColumns = 'places_id,name,type,lat,lng,address,kecamatan,photo_url,estimated_visit_minutes,is_outdoor';

        $trip->load([
            'days' => fn ($dayQuery) => $dayQuery->orderBy('day_number'),
            'days.items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order'),
            "days.items.place:{$placeColumns}",
            'days.startPlace:places_id,name,lat,lng',
            'days.endPlace:places_id,name,lat,lng',
        ]);

        $trip->days->each(function (ItineraryDay $day) {
            $day->setAttribute('start', $day->startPoint());
            $day->setAttribute('end', $day->endPoint());
            $day->setAttribute('has_own_end', $day->hasOwnEnd());
            $day->makeHidden(['startPlace', 'endPlace']);
        });

        return $trip;
    }

    /**
     * F008 langkah 3: minat (trip_interest_category) + bobot 4 kriteria
     * dalam satu request - dua hal yang disatukan sengaja, sesuai flow di
     * mobile (satu layar). US1: 0 slider disentuh tetap submit dengan
     * bobot sama rata, tidak diblokir.
     */
    public function weights(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'category_ids' => ['required', 'array', 'min:1'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
            'rating_kategori' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_jarak' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_anggaran' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_rating' => ['required', 'numeric', 'min:0', 'max:10'],
        ]);

        $sum = $data['rating_kategori'] + $data['rating_jarak'] + $data['rating_anggaran'] + $data['rating_rating'];

        if ($sum > 0) {
            $weights = [
                'weight_kategori' => $data['rating_kategori'] / $sum,
                'weight_jarak' => $data['rating_jarak'] / $sum,
                'weight_anggaran' => $data['rating_anggaran'] / $sum,
                'weight_rating' => $data['rating_rating'] / $sum,
            ];
        } else {
            $weights = [
                'weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25,
            ];
        }

        DB::transaction(function () use ($trip, $data, $weights) {
            $trip->interestCategories()->sync($data['category_ids']);
            $trip->update($weights);
        });

        return response()->json($trip->fresh(['interestCategories']));
    }

    /**
     * F008 langkah 4: set hotel - dari katalog (places_id) atau custom pin.
     */
    public function hotel(Request $request, Trip $trip, ItineraryGenerator $generator)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $point = $this->pointColumns('start', $this->validatedPoint($request, ''));

        // Simple mode: every day starts and ends at this one hotel.
        DB::transaction(function () use ($trip, $point) {
            $trip->syncDays();
            $trip->days()->update([
                ...$point,
                ...array_fill_keys(ItineraryDay::END_COLUMNS, null),
            ]);
        });

        $this->resequenceDaysWithStops($trip, $generator);

        return response()->json($this->withDays($trip->fresh()));
    }

    /**
     * Detail mode: where one day starts and ends. "end": null makes the day
     * end where it starts. A day that already has stops gets its route
     * recomputed; its places stay.
     */
    public function dayPoints(Request $request, Trip $trip, int $dayNumber, ItineraryGenerator $generator)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($dayNumber < 1 || $dayNumber > $trip->num_days) {
            abort(404, 'Hari tidak ditemukan.');
        }

        $request->validate([
            'start' => ['sometimes', 'array'],
            'end' => ['sometimes', 'nullable', 'array'],
        ]);

        $changes = [];
        if ($request->has('start')) {
            $changes += $this->pointColumns('start', $this->validatedPoint($request, 'start.'));
        }
        if ($request->has('end')) {
            $changes += $request->input('end') === null
                ? array_fill_keys(ItineraryDay::END_COLUMNS, null)
                : $this->pointColumns('end', $this->validatedPoint($request, 'end.'));
        }

        $trip->syncDays();
        $day = $trip->days()->where('day_number', $dayNumber)->firstOrFail();
        $day->update($changes);

        if ($day->items()->exists()) {
            $this->resequence($generator, $trip, $day);
        }

        return response()->json($this->withDays($trip->fresh()));
    }

    /**
     * A catalog place or a custom pin, under $prefix ("" for the top level,
     * "start." / "end." for a day point).
     *
     * @return array{places_id?: int, custom_name?: string, custom_lat?: float, custom_lng?: float}
     */
    private function validatedPoint(Request $request, string $prefix): array
    {
        $hasPlacesId = $request->filled($prefix.'places_id');

        $data = $request->validate([
            $prefix.'places_id' => ['nullable', 'integer', Rule::exists('places', 'places_id')->whereNull('deleted_at')],
            $prefix.'custom_name' => ['required_without:'.$prefix.'places_id', new ProhibitedIf($hasPlacesId), 'string', 'max:255'],
            $prefix.'custom_lat' => ['required_without:'.$prefix.'places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-90,90'],
            $prefix.'custom_lng' => ['required_without:'.$prefix.'places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-180,180'],
        ]);

        return $prefix === '' ? $data : ($data[rtrim($prefix, '.')] ?? []);
    }

    /**
     * @return array<string, mixed> the start_* or end_* columns for $point
     */
    private function pointColumns(string $side, array $point): array
    {
        if (! empty($point['places_id'])) {
            return [
                "{$side}_places_id" => $point['places_id'],
                "{$side}_custom_name" => null, "{$side}_lat" => null, "{$side}_lng" => null,
            ];
        }

        return [
            "{$side}_places_id" => null,
            "{$side}_custom_name" => $point['custom_name'],
            "{$side}_lat" => $point['custom_lat'],
            "{$side}_lng" => $point['custom_lng'],
        ];
    }

    private function resequenceDaysWithStops(Trip $trip, ItineraryGenerator $generator): void
    {
        $trip->days()->whereHas('items')->get()->each(fn (ItineraryDay $day) => $this->resequence($generator, $trip, $day));
    }

    /**
     * A failed route call leaves the day's order as it was; the new start and
     * end are already saved and the next generate uses them.
     */
    private function resequence(ItineraryGenerator $generator, Trip $trip, ItineraryDay $day): void
    {
        try {
            $generator->resequenceDay($trip, $day);
        } catch (RuntimeException) {
            // OpenRouteService unreachable or over quota.
        }
    }

    /**
     * F008 langkah 4: top-3 rekomendasi hotel TOPSIS. Kosong kalau trip
     * sudah pakai has_own_hotel (tidak butuh rekomendasi).
     */
    public function hotelOptions(Request $request, Trip $trip, HotelRecommender $recommender)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        if ($trip->has_own_hotel) {
            return response()->json(['data' => []]);
        }

        try {
            $options = $recommender->topThree($trip);
        } catch (RuntimeException $exception) {
            throw ValidationException::withMessages(['hotel' => [$exception->getMessage()]]);
        }

        return response()->json([
            'data' => $options->map(fn ($option) => [
                'places_id' => $option['place']->places_id,
                'name' => $option['place']->name,
                'address' => $option['place']->address,
                'lat' => (float) $option['place']->lat,
                'lng' => (float) $option['place']->lng,
                'photo_url' => $option['place']->photo_url,
                'rating' => $option['place']->ratingBlend(),
                'topsis_score' => $option['topsis_score'],
            ])->values(),
        ]);
    }

    /**
     * F008: K-Means + TOPSIS + Nearest-Neighbor + Routes API -> itinerary.
     */
    public function generate(Request $request, Trip $trip, ItineraryGenerator $generator)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        try {
            $result = $generator->generate($trip);
        } catch (RuntimeException $exception) {
            throw ValidationException::withMessages(['trip' => [$exception->getMessage()]]);
        }

        return response()->json([
            'trip' => $trip->fresh(),
            'days' => collect($result['days'])->map(fn ($day) => [
                'itinerary_days_id' => $day['day']->itinerary_days_id,
                'day_number' => $day['day']->day_number,
                'tidak_muat' => $day['tidak_muat'],
                'padat' => $day['padat'],
                'items' => $day['day']->items->map(fn ($item) => [
                    'itinerary_items_id' => $item->itinerary_items_id,
                    'places_id' => $item->places_id,
                    'visit_order' => $item->visit_order,
                    'topsis_score' => $item->topsis_score,
                    'source' => $item->source,
                    'polyline_to_here' => $item->polyline_to_here,
                ])->values(),
            ])->values(),
            'dropped_wishlist_places' => $result['dropped_wishlist_places'],
            // Wishlist places closed on every day of the trip, left out.
            'closed_wishlist_places' => $result['closed_wishlist_places'],
        ]);
    }

    /**
     * F011: edit trip tersimpan (PRD audit 2026-10-10 - endpoint ini
     * sebelumnya tidak ada walau Section 12/13 mengasumsikan trip bisa
     * diedit). Owner-only. Kalau field yang menentukan susunan hari berubah
     * (num_days, budget_total, jam harian) dan itinerary sudah ada, itinerary
     * lama dibuang - design spec Section 13 langkah 9 memang "regenerate
     * penuh"; mobile memanggil POST /generate lagi setelah ini. start_date
     * dan title tidak membuang itinerary.
     */
    public function update(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'num_days' => ['sometimes', 'integer', 'min:1'],
            'budget_total' => ['sometimes', 'integer', 'min:1'],
            'start_date' => ['sometimes', 'date'],
            'daily_start_time' => ['sometimes', 'date_format:H:i'],
            'daily_end_time' => ['sometimes', 'date_format:H:i'],
        ]);

        $dailyStart = $data['daily_start_time'] ?? substr((string) $trip->daily_start_time, 0, 5);
        $dailyEnd = $data['daily_end_time'] ?? substr((string) $trip->daily_end_time, 0, 5);

        if ($dailyEnd <= $dailyStart) {
            throw ValidationException::withMessages([
                'daily_end_time' => ['Jam selesai harus setelah jam mulai.'],
            ]);
        }

        $structural = ['num_days', 'budget_total', 'daily_start_time', 'daily_end_time'];
        $itineraryCleared = false;

        DB::transaction(function () use ($trip, $data, $structural, &$itineraryCleared) {
            $trip->fill($data);
            $structuralChanged = collect($structural)->contains(fn ($field) => $trip->isDirty($field));
            $trip->save();

            // The day rows stay with their start and end points; only the
            // stops go, and the app generates again.
            if ($structuralChanged && $trip->days()->whereHas('items')->exists()) {
                ItineraryItem::whereIn('itinerary_days_id', $trip->days()->select('itinerary_days_id'))->delete();
                $trip->days()->update(['polyline_to_end' => null]);
                $itineraryCleared = true;
            }

            if ($trip->wasChanged('num_days')) {
                $trip->syncDays();
            }
        });

        return response()->json([
            ...$trip->fresh()->toArray(),
            'itinerary_cleared' => $itineraryCleared,
        ]);
    }

    /**
     * F011: hapus trip tersimpan - soft delete (trips.deleted_at),
     * riwayat kunjungan yang sudah pernah dilihat viewer dkk tetap utuh
     * di database, cuma hilang dari daftar/pencarian aktif.
     */
    public function destroy(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->delete();

        return response()->json(['message' => 'Trip dihapus.']);
    }

    /**
     * F017 (docs/prd design spec Section 10) - generate/ambil share_token
     * publik. Idempotent - link yang sama terus dipakai sampai sengaja
     * di-reset, bukan generate ulang tiap tap.
     */
    public function storeShareLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($trip->share_token === null) {
            $trip->update(['share_token' => $this->generateUniqueShareToken()]);
        }

        return response()->json(['share_token' => $trip->share_token]);
    }

    /**
     * Matikan link publik - link lama langsung mati buat siapapun yang
     * masih pegang, beda dari viewer_invite_token (F015) yang cuma
     * menutup jalur masuk baru tanpa mencabut akses yang sudah join
     * (share link anon tidak punya baris akses yang bisa "sudah join").
     */
    public function destroyShareLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->update(['share_token' => null]);

        return response()->json(['message' => 'Link publik dimatikan.']);
    }

    private function generateUniqueShareToken(): string
    {
        do {
            $token = Str::random(32);
        } while (Trip::where('share_token', $token)->exists());

        return $token;
    }
}
