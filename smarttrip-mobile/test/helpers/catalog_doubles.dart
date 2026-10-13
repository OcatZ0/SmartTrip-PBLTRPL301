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
const kulinerSeafood = TripCategory(
  categoriesId: 2,
  nameId: 'Kuliner Seafood',
  nameEn: 'Seafood',
  slug: 'kuliner-seafood',
);

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

typedef CatalogCall = ({int page, String search, String? categorySlug, String? type, String? kecamatan});

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
    String? kecamatan,
  }) async {
    calls.add((page: page, search: search, categorySlug: categorySlug, type: type, kecamatan: kecamatan));
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

  List<KecamatanOption> kecamatan = const [
    KecamatanOption(name: 'Batam Kota', placesCount: 10),
    KecamatanOption(name: 'Nongsa', placesCount: 1),
  ];
  Object? kecamatanFailWith;

  @override
  Future<List<KecamatanOption>> fetchKecamatan() async {
    final error = kecamatanFailWith;
    if (error != null) throw error;
    return kecamatan;
  }

  /// Per-id overrides; any other id gets [placeDetail].
  final details = <int, PlaceDetail>{};
  Object? detailFailWith;
  final detailCalls = <int>[];

  @override
  Future<PlaceDetail> fetchPlaceDetail(int placesId) async {
    detailCalls.add(placesId);
    final error = detailFailWith;
    if (error != null) throw error;
    return details[placesId] ?? placeDetail(placesId);
  }
}

/// Detail for place number [placesId] (see [catalogPlace]): free entry,
/// a 90 minute visit, OSM hours, a description and two reviews.
PlaceDetail placeDetail(
  int placesId, {
  String type = 'attraction',
  String description = 'Pantai berpasir putih dengan bianglala di tepi laut.',
  List<PlaceReview>? reviews,
}) {
  final base = catalogPlace(placesId - 1);
  return PlaceDetail(
    summary: CatalogPlace(
      placesId: base.placesId,
      name: base.name,
      type: type,
      kecamatan: 'Batam Kota',
      rating: 4.5,
      reviewCount: 2,
      estimatedCostIdr: 0,
      categories: const [pantai],
    ),
    lat: 1.1519,
    lng: 104.0547,
    address: 'Jl. Hang Lekiu, Batam Centre',
    mapsUrl: 'https://www.google.com/maps/search/?api=1&query=1.1519,104.0547',
    descriptionId: description,
    openingHours: 'Mo-Su 08:00-21:00',
    estimatedVisitMinutes: 90,
    reviews:
        reviews ??
        [
          PlaceReview(
            placeReviewsId: 1,
            usersId: 3,
            userName: 'Dian Pratama',
            rating: 5,
            comment: 'Senjanya indah.',
            createdAt: DateTime.now(),
          ),
          PlaceReview(placeReviewsId: 2, usersId: 4, userName: 'Sarah Wijaya', rating: 4, comment: 'Parkir luas.'),
        ],
  );
}

class FakeTripRepository implements TripRepository {
  FakeTripRepository({List<TripSummary>? trips}) : trips = trips ?? const [];

  final List<TripSummary> trips;

  /// Trip ids whose wishlist already has the place (API answers 200).
  final alreadyIn = <int>{};
  final added = <({int tripsId, int placesId})>[];

  @override
  Future<List<TripCategory>> fetchCategories() async => const [kulinerSeafood, pantai];

  @override
  Future<List<TripSummary>> fetchMyTrips() async => trips;

  @override
  Future<bool> addPlaceToTripWishlist(int tripsId, int placesId) async {
    added.add((tripsId: tripsId, placesId: placesId));
    return !alreadyIn.contains(tripsId);
  }

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
  FakeTripRepository? trips,
}) {
  return [
    catalogRepositoryProvider.overrideWithValue(catalog ?? FakeCatalogRepository()),
    tripRepositoryProvider.overrideWithValue(trips ?? FakeTripRepository()),
    userWishlistRepositoryProvider.overrideWithValue(wishlist ?? FakeUserWishlistRepository()),
  ];
}
