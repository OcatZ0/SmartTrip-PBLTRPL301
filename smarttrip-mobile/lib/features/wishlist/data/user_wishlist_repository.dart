import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/error/api_failure.dart';

/// The user's own wishlist (heart on catalog cards, tab Wishlist), separate
/// from a trip's wishlist step (C2).
class UserWishlistRepository {
  UserWishlistRepository(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<Set<int>> fetchPlaceIds() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/wishlist'));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((place) => place['places_id'] as int)
        .toSet();
  }

  Future<void> add(int placesId) async {
    await _call(() => _dio.post<Map<String, dynamic>>('/wishlist', data: {'places_id': placesId}));
  }

  Future<void> remove(int placesId) async {
    await _call(() => _dio.delete<Map<String, dynamic>>('/wishlist/$placesId'));
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

final userWishlistRepositoryProvider = Provider<UserWishlistRepository>((ref) {
  return UserWishlistRepository(ref.watch(apiClientProvider));
});
