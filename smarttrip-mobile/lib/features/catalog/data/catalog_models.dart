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
      reviewCount:
          ((json['review_count_google'] as num?) ?? 0).toInt() + ((json['review_count_in_app'] as num?) ?? 0).toInt(),
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
      places: (json['data'] as List? ?? const []).cast<Map<String, dynamic>>().map(CatalogPlace.fromJson).toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  final List<CatalogPlace> places;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}

/// One option of the catalog's kecamatan filter, only kecamatan that have places.
class KecamatanOption {
  const KecamatanOption({required this.name, required this.placesCount});

  factory KecamatanOption.fromJson(Map<String, dynamic> json) {
    return KecamatanOption(name: json['name'] as String, placesCount: json['places_count'] as int? ?? 0);
  }

  final String name;
  final int placesCount;
}

/// A review on the B2 detail screen, newest first from the API.
class PlaceReview {
  const PlaceReview({
    required this.placeReviewsId,
    required this.userName,
    required this.rating,
    this.usersId,
    this.comment,
    this.createdAt,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      placeReviewsId: json['place_reviews_id'] as int,
      usersId: json['users_id'] as int?,
      userName: json['user_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    );
  }

  final int placeReviewsId;
  final int? usersId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
}

/// A photo on the B2 detail screen.
class PlacePhoto {
  const PlacePhoto({required this.url});

  factory PlacePhoto.fromJson(Object? json) {
    // Older API responses listed bare URLs.
    if (json is! Map<String, dynamic>) return PlacePhoto(url: AppConfig.resolveMediaUrl(json?.toString()) ?? '');

    return PlacePhoto(url: AppConfig.resolveMediaUrl(json['url'] as String?) ?? '');
  }

  final String url;
}

/// B2 Detail Tempat, from `GET /api/places/{id}` (PlaceDetailResource).
class PlaceDetail {
  const PlaceDetail({
    required this.summary,
    required this.lat,
    required this.lng,
    this.address,
    this.mapsUrl,
    this.photos = const [],
    this.descriptionId,
    this.descriptionEn,
    this.openingHours,
    this.businessStatus = 'operational',
    this.estimatedVisitMinutes,
    this.reviews = const [],
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    return PlaceDetail(
      summary: CatalogPlace.fromJson(json),
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String?,
      mapsUrl: json['maps_url'] as String?,
      photos: (json['photos'] as List? ?? const [])
          .map(PlacePhoto.fromJson)
          .where((photo) => photo.url.isNotEmpty)
          .toList(),
      descriptionId: json['description_id'] as String?,
      descriptionEn: json['description_en'] as String?,
      openingHours: _openingHours(json['opening_hours']),
      businessStatus: json['business_status'] as String? ?? 'operational',
      estimatedVisitMinutes: (json['estimated_visit_minutes'] as num?)?.toInt(),
      reviews: (json['reviews'] as List? ?? const []).cast<Map<String, dynamic>>().map(PlaceReview.fromJson).toList(),
    );
  }

  /// Card fields (name, rating, price, categories) shared with the catalog.
  final CatalogPlace summary;
  final double lat;
  final double lng;
  final String? address;
  final String? mapsUrl;
  final List<PlacePhoto> photos;
  final String? descriptionId;
  final String? descriptionEn;

  /// Human-readable hours, e.g. the OSM "Mo-Su 08:00-21:00" from Geoapify.
  final String? openingHours;
  final String businessStatus;
  final int? estimatedVisitMinutes;
  final List<PlaceReview> reviews;

  String? description(String languageCode) {
    final preferred = languageCode == 'en' ? descriptionEn : descriptionId;
    final fallback = languageCode == 'en' ? descriptionId : descriptionEn;
    return _nonEmpty(preferred) ?? _nonEmpty(fallback);
  }

  /// Hero photo: the gallery's first photo, else the catalog thumbnail.
  String? get heroPhotoUrl => photos.isNotEmpty ? photos.first.url : summary.photoUrl;

  static String? _nonEmpty(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

  // Geoapify places store {'osm': 'Mo-Su 08:00-21:00'}; places imported from
  // Google kept its weekday_descriptions list.
  static String? _openingHours(Object? value) {
    if (value is String) return _nonEmpty(value);
    if (value is! Map) return null;

    final osm = value['osm'];
    if (osm is String) return _nonEmpty(osm);

    final weekdays = value['weekday_descriptions'] ?? value['weekdayDescriptions'];
    if (weekdays is List && weekdays.isNotEmpty) return weekdays.join('\n');

    return null;
  }
}
