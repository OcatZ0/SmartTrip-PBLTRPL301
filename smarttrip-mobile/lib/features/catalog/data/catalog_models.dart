import '../../../core/config/app_config.dart';
import '../../trip/data/trip_models.dart';

/// One card of the B1 catalog grid, from `GET /api/places` (PlaceResource).
class CatalogPlace {
  const CatalogPlace({
    required this.placesId,
    required this.name,
    required this.type,
    this.kecamatan,
    this.photoUrl,
    this.rating,
    this.reviewCount = 0,
    this.estimatedCostIdr,
    this.categories = const [],
  });

  factory CatalogPlace.fromJson(Map<String, dynamic> json) {
    return CatalogPlace(
      placesId: json['places_id'] as int,
      name: json['name'] as String,
      type: json['type'] as String? ?? '',
      kecamatan: json['kecamatan'] as String?,
      photoUrl: AppConfig.resolveMediaUrl(json['photo_url'] as String?),
      rating: (json['rating'] as num?)?.toDouble(),
      // Same count the rating blend is built from: source reviews plus
      // reviews written in the app.
      reviewCount: ((json['review_count_google'] as num?) ?? 0).toInt() +
          ((json['review_count_in_app'] as num?) ?? 0).toInt(),
      estimatedCostIdr: (json['estimated_cost_idr'] as num?)?.toInt(),
      categories: (json['categories'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TripCategory.fromJson)
          .toList(),
    );
  }

  final int placesId;
  final String name;
  final String type;
  final String? kecamatan;
  final String? photoUrl;

  /// Blended rating, null when the place has no rating and no reviews yet.
  final double? rating;
  final int reviewCount;

  /// Admin-entered cost per person; 0 means free entry, null means unknown.
  final int? estimatedCostIdr;
  final List<TripCategory> categories;

  bool get isLodging => type == 'lodging';
}

/// One page of `GET /api/places` (Laravel paginator).
class CatalogPage {
  const CatalogPage({required this.places, required this.currentPage, required this.lastPage});

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return CatalogPage(
      places: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(CatalogPlace.fromJson)
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  final List<CatalogPlace> places;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}
