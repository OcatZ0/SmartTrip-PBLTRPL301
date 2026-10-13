import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/error/api_failure.dart';
import 'trip_models.dart';

/// Trip setup + itinerary endpoints (design spec Section 12, F008/F013).
class TripRepository {
  TripRepository(this._apiClient);

  /// Generate runs K-Means, TOPSIS and the Routes API in one request, so it
  /// gets more time than the client default (US4 target is ~15s).
  static const _generateTimeout = Duration(seconds: 60);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<int> createTrip({
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    final body = await _call(() => _dio.post<Map<String, dynamic>>(
          '/trips',
          data: {
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
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    await _call(() => _dio.patch<Map<String, dynamic>>(
          '/trips/$tripsId',
          data: {
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

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(apiClientProvider));
});
