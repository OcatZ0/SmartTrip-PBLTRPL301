import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/providers.dart';
import '../core/error/api_failure.dart';
import '../models/saved_trip.dart';
import '../models/trip.dart';
import 'visit_sync.dart';

/// Trip setup + itinerary endpoints (design spec Section 12, F008/F013).
class TripService {
  TripService(this._apiClient);

  /// Generate runs K-Means, TOPSIS and the Routes API in one request, so it
  /// gets more time than the client default (US4 target is ~15s).
  static const _generateTimeout = Duration(seconds: 60);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<int> createTrip({
    String? title,
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    final body = await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips',
          data: {
            if (title != null) 'title': title,
            'num_days': numDays,
            'budget_total': budgetTotal,
            'start_date': _formatDate(startDate),
            'daily_start_time': dailyStartTime,
            'daily_end_time': dailyEndTime,
          },
        ));
    return body['trips_id'] as int;
  }

  Future<void> updateTrip(
    int tripsId, {
    String? title,
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    await _call(() => _dio.patch<Map<String, dynamic>>(
          '/trips/$tripsId',
          data: {
            if (title != null) 'title': title,
            'num_days': numDays,
            'budget_total': budgetTotal,
            'start_date': _formatDate(startDate),
            'daily_start_time': dailyStartTime,
            'daily_end_time': dailyEndTime,
          },
        ));
  }

  Future<List<TripCategory>> fetchCategories() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/categories'));
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(TripCategory.fromJson)
        .toList();
  }

  Future<PreferenceDefaults> fetchPreferenceDefaults() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/profile/preferences'));
    return PreferenceDefaults.fromJson(body);
  }

  /// [ratings] are the four 0-10 sliders in kategori, jarak, anggaran, rating
  /// order; the backend normalizes them into weights.
  Future<void> saveTripPreferences(
    int tripsId, {
    required Set<int> categoryIds,
    required List<double> ratings,
  }) async {
    await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips/$tripsId/weights',
          data: _preferenceBody(categoryIds, ratings),
        ));
  }

  Future<void> saveProfileDefaults({
    required Set<int> categoryIds,
    required List<double> ratings,
  }) async {
    await _call(() => _dio.put<Map<String, dynamic>>(
          '/profile/preferences',
          data: _preferenceBody(categoryIds, ratings),
        ));
  }

  Future<List<HotelOption>> fetchHotelOptions(int tripsId) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/trips/$tripsId/hotel-options'));
    final options = (body['data'] as List).cast<Map<String, dynamic>>();
    return [
      for (var i = 0; i < options.length; i++)
        HotelOption(place: TripPlace.fromJson({...options[i], 'type': 'lodging'}), rank: i + 1),
    ];
  }

  Future<List<TripPlace>> searchHotels(String query) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>(
          '/places',
          queryParameters: {
            'type': 'lodging',
            if (query.trim().isNotEmpty) 'search': query.trim(),
            'per_page': 20,
          },
        ));
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(TripPlace.fromJson)
        .toList();
  }

  Future<void> setCatalogHotel(int tripsId, int placesId) async {
    await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips/$tripsId/hotel',
          data: {'places_id': placesId},
        ));
  }

  /// One day's start and/or end (detail mode). [start] / [end] are a
  /// `{places_id}` or `{custom_name, custom_lat, custom_lng}` point; with
  /// [resetEnd] the day ends where it starts again. A day with stops gets its
  /// route recomputed by the server.
  Future<void> setDayPoints(
    int tripsId,
    int dayNumber, {
    Map<String, dynamic>? start,
    Map<String, dynamic>? end,
    bool resetEnd = false,
  }) async {
    await _call(() => _dio.put<Map<String, dynamic>>(
          '/trips/$tripsId/days/$dayNumber/points',
          data: {
            if (start != null) 'start': start,
            if (end != null) 'end': end else if (resetEnd) 'end': null,
          },
        ));
  }

  Future<void> setCustomHotel(
    int tripsId, {
    required String name,
    required double lat,
    required double lng,
  }) async {
    await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips/$tripsId/hotel',
          data: {'custom_name': name, 'custom_lat': lat, 'custom_lng': lng},
        ));
  }

  Future<GenerateResult> generate(int tripsId) async {
    final body = await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips/$tripsId/generate',
          options: Options(receiveTimeout: _generateTimeout),
        ));
    return GenerateResult.fromJson(body);
  }

  /// The user's own trips, newest first (first page is plenty for a picker).
  Future<List<TripSummary>> fetchMyTrips() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/trips', queryParameters: {'per_page': 50}));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TripSummary.fromJson)
        .toList();
  }

  /// Trip Tersimpan: the user's own trips with each card's summary (status,
  /// progress, photos), newest first.
  Future<List<TripModel>> fetchSavedTrips() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/trips', queryParameters: {'per_page': 50}));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TripModel.fromJson)
        .toList();
  }

  /// Step C2: the trip's wishlist, catalog places and custom pins.
  Future<List<TripWishlistItem>> fetchTripWishlist(int tripsId) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/trips/$tripsId/wishlist'));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TripWishlistItem.fromJson)
        .toList();
  }

  /// Adds a pin dropped on the map, with how long the user plans to stay.
  Future<void> addCustomPinToTripWishlist(
    int tripsId, {
    required String name,
    required double lat,
    required double lng,
    required int visitMinutes,
  }) async {
    await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips/$tripsId/wishlist',
          data: {
            'custom_name': name,
            'custom_lat': lat,
            'custom_lng': lng,
            'custom_visit_minutes': visitMinutes,
          },
        ));
  }

  Future<void> removeFromTripWishlist(int tripsId, int wishlistItemId) async {
    await _call(() => _dio.delete<Map<String, dynamic>>('/trips/$tripsId/wishlist/$wishlistItemId'));
  }

  /// Adds a catalog place to a trip's wishlist; false when it was already
  /// there (the API answers 200 instead of 201).
  Future<bool> addPlaceToTripWishlist(int tripsId, int placesId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/trips/$tripsId/wishlist',
        data: {'places_id': placesId},
      );
      return response.statusCode == 201;
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  /// Ranked replacements for one stop (D2), best first.
  Future<List<TripPlace>> fetchSwapCandidates(int itineraryItemsId) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>(
          '/itinerary-items/$itineraryItemsId/swap-candidates',
        ));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TripPlace.fromJson)
        .toList();
  }

  /// Any catalog place except hotels, for the D2 "Cari Manual" tab.
  Future<List<TripPlace>> searchPlaces(String query) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>(
          '/places',
          queryParameters: {
            if (query.trim().isNotEmpty) 'search': query.trim(),
            'per_page': 20,
          },
        ));
    return (body['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(TripPlace.fromJson)
        .where((place) => place.type != 'lodging')
        .toList();
  }

  Future<void> swapItineraryItem(int itineraryItemsId, int placesId) async {
    await _call(() => _dio.patch<Map<String, dynamic>>(
          '/itinerary-items/$itineraryItemsId',
          data: {'places_id': placesId},
        ));
  }

  Future<Trip> fetchTrip(int tripsId) async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/trips/$tripsId'));
    return Trip.fromJson(body);
  }

  /// Toggles `visited_at` on the server and returns the new value.
  Future<DateTime?> toggleVisit(int itineraryItemsId) async {
    final body = await _call(() => _dio.post<Map<String, dynamic>>(
          '/itinerary-items/$itineraryItemsId/visit',
        ));
    final visitedAt = body['visited_at'];
    return visitedAt == null ? null : DateTime.tryParse(visitedAt.toString());
  }

  Map<String, dynamic> _preferenceBody(Set<int> categoryIds, List<double> ratings) {
    return {
      'category_ids': categoryIds.toList(),
      'rating_kategori': ratings[0],
      'rating_jarak': ratings[1],
      'rating_anggaran': ratings[2],
      'rating_rating': ratings[3],
    };
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Map<String, dynamic>> _call(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? const {};
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(ref.watch(apiClientProvider));
});

/// One trip with its itinerary, shared by the itinerary screen (D1) and the
/// live map (E1) so a visit marked on the map shows up on D1 right away.
class TripDetailController extends AutoDisposeFamilyAsyncNotifier<Trip, int> {
  @override
  Future<Trip> build(int tripsId) async {
    final trip = await ref.read(tripServiceProvider).fetchTrip(tripsId);
    final changes = await ref.read(visitSyncProvider).flush(trip);
    return _applyVisits(trip, changes);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  /// Marks or unmarks a stop (manual toggle, US7). The change shows
  /// immediately; returns whether it reached the server or was queued.
  Future<VisitChange> setVisited(ItineraryItem item, {required bool visited}) async {
    applyVisit(item.itineraryItemsId, visited ? DateTime.now() : null);

    final change = await ref.read(visitSyncProvider).setVisited(item, visited: visited);
    if (change is VisitSynced) applyVisit(item.itineraryItemsId, change.visitedAt);
    return change;
  }

  void applyVisit(int itineraryItemsId, DateTime? visitedAt) {
    final trip = state.valueOrNull;
    if (trip == null) return;
    state = AsyncData(_applyVisits(trip, {itineraryItemsId: visitedAt}));
  }

  static Trip _applyVisits(Trip trip, Map<int, DateTime?> visits) {
    if (visits.isEmpty) return trip;

    var updated = trip;
    for (final day in trip.days) {
      if (!day.items.any((item) => visits.containsKey(item.itineraryItemsId))) continue;

      updated = updated.withDay(day.withItems([
        for (final item in day.items)
          visits.containsKey(item.itineraryItemsId)
              ? item.copyWith(visitedAt: () => visits[item.itineraryItemsId])
              : item,
      ]));
    }
    return updated;
  }
}

final tripDetailProvider =
    AsyncNotifierProvider.autoDispose.family<TripDetailController, Trip, int>(
  TripDetailController.new,
);

/// The `padat`/`tidak_muat` flags of the last generate run per trip. The
/// trip detail endpoint does not return them, so they live for the session.
final generatedFlagsProvider = StateProvider.family<GenerateResult?, int>((ref, tripsId) => null);
