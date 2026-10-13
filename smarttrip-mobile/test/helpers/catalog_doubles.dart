import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/features/catalog/data/catalog_models.dart';
import 'package:smarttrip_mobile/features/catalog/data/catalog_repository.dart';
import 'package:smarttrip_mobile/features/trip/data/trip_models.dart';
import 'package:smarttrip_mobile/features/trip/data/trip_repository.dart';
import 'package:smarttrip_mobile/features/wishlist/data/user_wishlist_repository.dart';

const pantai = TripCategory(categoriesId: 1, nameId: 'Pantai', nameEn: 'Beach', slug: 'pantai');
const kulinerSeafood =
    TripCategory(categoriesId: 2, nameId: 'Kuliner Seafood', nameEn: 'Seafood', slug: 'kuliner-seafood');

/// Place number [index] + 1. The first one is free to enter, the second has
/// no rating and no known price.
CatalogPlace catalogPlace(int index) {
  return CatalogPlace(
    placesId: index + 1,
    name: 'Tempat ${index + 1}',
    type: 'attraction',
    rating: index == 1 ? null : 4.5,
    reviewCount: 1200,
    estimatedCostIdr: switch (index) {
      0 => 0,
      1 => null,
      _ => 15000,
    },
    categories: const [pantai],
  );
}

typedef CatalogCall = ({int page, String search, String? categorySlug, String? type});

/// [total] places served 20 per page, like the API.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.total = 30});

  int total;
  Object? failWith;

  /// When set, every request waits for it before answering.
  Completer<void>? gate;

  final calls = <CatalogCall>[];

  @override
  Future<CatalogPage> fetchPlaces({
    required int page,
    String search = '',
    String? categorySlug,
    String? type,
  }) async {
    calls.add((page: page, search: search, categorySlug: categorySlug, type: type));
    await gate?.future;
    final error = failWith;
    if (error != null) throw error;

    const size = CatalogRepository.pageSize;
    final start = (page - 1) * size;
    final end = min(start + size, total);
    return CatalogPage(
      places: [for (var i = start; i < end; i++) catalogPlace(i)],
      currentPage: page,
      lastPage: max(1, (total / size).ceil()),
    );
  }
}

class FakeTripRepository implements TripRepository {
  @override
  Future<List<TripCategory>> fetchCategories() async => const [kulinerSeafood, pantai];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeUserWishlistRepository implements UserWishlistRepository {
  FakeUserWishlistRepository({Set<int>? saved}) : saved = saved ?? {};

  final Set<int> saved;
  bool failNext = false;
  final added = <int>[];
  final removed = <int>[];

  @override
  Future<Set<int>> fetchPlaceIds() async => {...saved};

  @override
  Future<void> add(int placesId) async {
    _maybeFail();
    added.add(placesId);
    saved.add(placesId);
  }

  @override
  Future<void> remove(int placesId) async {
    _maybeFail();
    removed.add(placesId);
    saved.remove(placesId);
  }

  void _maybeFail() {
    if (!failNext) return;
    failNext = false;
    throw const NetworkFailure();
  }
}

/// Session that is already resolved, without the `GET /api/user` round trip.
class FakeSessionController extends SessionController {
  FakeSessionController(this.user);

  final AuthUser? user;

  @override
  Future<AuthUser?> build() async => user;
}

/// Keeps the catalog (the logged-in landing screen) off the network in
/// tests that only pass through it.
List<Override> catalogOverrides({
  FakeCatalogRepository? catalog,
  FakeUserWishlistRepository? wishlist,
}) {
  return [
    catalogRepositoryProvider.overrideWithValue(catalog ?? FakeCatalogRepository()),
    tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
    userWishlistRepositoryProvider.overrideWithValue(wishlist ?? FakeUserWishlistRepository()),
  ];
}
