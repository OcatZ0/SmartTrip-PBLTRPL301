import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/providers.dart';
import '../core/auth/session_controller.dart';
import '../core/error/api_failure.dart';
import '../models/place.dart';

/// The user's own wishlist (heart on catalog cards, tab Wishlist), separate
/// from a trip's wishlist step (C2).
class WishlistService {
  WishlistService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  Future<Set<int>> fetchPlaceIds() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/wishlist'));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((place) => place['places_id'] as int)
        .toSet();
  }

  /// The saved places themselves, newest first (step C2 suggests them).
  Future<List<CatalogPlace>> fetchPlaces() async {
    final body = await _call(() => _dio.get<Map<String, dynamic>>('/wishlist'));
    return (body['data'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(CatalogPlace.fromJson)
        .toList();
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

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService(ref.watch(apiClientProvider));
});

/// Ids of the places in the logged-in user's wishlist; empty for a guest.
/// Reloads whenever the logged-in user changes.
class UserWishlistController extends AsyncNotifier<Set<int>> {
  final _pending = <int>{};

  @override
  Future<Set<int>> build() async {
    final usersId = ref.watch(sessionControllerProvider.select((session) => session.valueOrNull?.usersId));
    if (usersId == null) return const {};

    return ref.read(wishlistServiceProvider).fetchPlaceIds();
  }

  /// The heart flips at once and flips back if the request fails. A second
  /// tap while the first request is still running is ignored.
  Future<void> toggle(int placesId) async {
    if (!_pending.add(placesId)) return;

    final wasSaved = (state.valueOrNull ?? const {}).contains(placesId);
    _set(placesId, saved: !wasSaved);

    try {
      final repository = ref.read(wishlistServiceProvider);
      if (wasSaved) {
        await repository.remove(placesId);
      } else {
        await repository.add(placesId);
      }
    } catch (_) {
      _set(placesId, saved: wasSaved);
      rethrow;
    } finally {
      _pending.remove(placesId);
    }
  }

  void _set(int placesId, {required bool saved}) {
    final ids = {...?state.valueOrNull};
    if (saved) {
      ids.add(placesId);
    } else {
      ids.remove(placesId);
    }
    state = AsyncData(ids);
  }
}

final userWishlistControllerProvider =
    AsyncNotifierProvider<UserWishlistController, Set<int>>(UserWishlistController.new);
