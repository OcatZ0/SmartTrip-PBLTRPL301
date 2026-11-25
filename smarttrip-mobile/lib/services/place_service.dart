import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/providers.dart';
import '../core/error/api_failure.dart';
import '../models/place.dart';

/// F005 catalog browsing (design spec Section 12, public endpoint).
class PlaceService {
  PlaceService(this._apiClient);

  static const pageSize = 20;

  final ApiClient _apiClient;

  Future<CatalogPage> fetchPlaces({
    required int page,
    String search = '',
    String? categorySlug,
    String? type,
    String? kecamatan,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/places',
        queryParameters: {
          'page': page,
          'per_page': pageSize,
          if (search.isNotEmpty) 'search': search,
          if (categorySlug != null) 'category': categorySlug,
          if (type != null) 'type': type,
          if (kecamatan != null) 'kecamatan': kecamatan,
        },
      );
      return CatalogPage.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<List<KecamatanOption>> fetchKecamatan() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/places/kecamatan');
      return (response.data?['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(KecamatanOption.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<PlaceDetail> fetchPlaceDetail(int placesId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/places/$placesId');
      return PlaceDetail.fromJson(response.data?['data'] as Map<String, dynamic>? ?? const {});
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
  /// F014 / UC-016: one active review per user and place. [itineraryItemsId]
  /// links it to the trip stop it was written from (A3).
  Future<void> createReview(int placesId, {required int rating, String? comment, int? itineraryItemsId}) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>('/places/$placesId/reviews', data: {
        'rating': rating,
        'comment': comment,
        if (itineraryItemsId != null) 'itinerary_items_id': itineraryItemsId,
      });
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<void> updateReview(int placeReviewsId, {required int rating, String? comment}) async {
    try {
      await _apiClient.dio.patch<Map<String, dynamic>>('/reviews/$placeReviewsId', data: {'rating': rating, 'comment': comment});
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }

  Future<void> deleteReview(int placeReviewsId) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>('/reviews/$placeReviewsId');
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
  }
}

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(ref.watch(apiClientProvider));
});
