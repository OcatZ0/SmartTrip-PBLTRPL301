import 'dart:math' as math;

import '../core/config/app_config.dart';

// Laravel's `decimal:7` casts arrive as strings, plain numbers as num.
double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  // start_date is a calendar date; keep it free of timezone shifts.
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Interest category from `GET /api/categories`, also embedded in each
/// catalog place.
class TripCategory {
  const TripCategory({
    required this.categoriesId,
    required this.nameId,
    required this.nameEn,
    this.slug = '',
    this.iconSymbol,
  });

  factory TripCategory.fromJson(Map<String, dynamic> json) {
    return TripCategory(
      categoriesId: json['categories_id'] as int,
      nameId: json['name_id'] as String,
      nameEn: json['name_en'] as String? ?? json['name_id'] as String,
      slug: json['slug'] as String? ?? '',
      iconSymbol: json['icon_symbol'] as String?,
    );
  }

  final int categoriesId;
  final String nameId;
  final String nameEn;

  /// Admin-set icon key, drawn with [categoryIcon]. Only sent by
  /// `GET /api/categories`, not inside catalog places.
  final String? iconSymbol;

  /// The `GET /api/places?category=` filter value.
  final String slug;

  String localizedName(String languageCode) => languageCode == 'en' ? nameEn : nameId;
}

/// One row of `GET /api/trips`, for picking a trip to add a place to.
class TripSummary {
  const TripSummary({
    required this.tripsId,
    required this.title,
    required this.numDays,
    this.startDate,
    this.hasItinerary = false,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      tripsId: json['trips_id'] as int,
      title: json['title'] as String? ?? '',
      numDays: (json['num_days'] as num?)?.toInt() ?? 0,
      startDate: _toDate(json['start_date']),
      hasItinerary: ((json['days_count'] as num?) ?? 0) > 0,
    );
  }

  final int tripsId;
  final String title;
  final int numDays;
  final DateTime? startDate;

  /// A place added after generating only counts once the itinerary is
  /// generated again.
  final bool hasItinerary;
}

/// Profile defaults (`GET /api/profile/preferences`) used to pre-fill step 3.
class PreferenceDefaults {
  const PreferenceDefaults({required this.categoryIds, required this.weights});

  factory PreferenceDefaults.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map((category) => category['categories_id'] as int)
        .toSet();
    final weights = [
      _toDouble(json['default_weight_kategori']),
      _toDouble(json['default_weight_jarak']),
      _toDouble(json['default_weight_anggaran']),
      _toDouble(json['default_weight_rating']),
    ];

    return PreferenceDefaults(
      categoryIds: categories,
      weights: weights.contains(null) ? null : weights.cast<double>(),
    );
  }

  final Set<int> categoryIds;

  /// Normalized weights (sum 1) in kategori, jarak, anggaran, rating order,
  /// or null when the profile has none yet.
  final List<double>? weights;

  /// [weights] scaled back to the 0-10 sliders, the strongest criterion at 10.
  List<double> get ratings {
    final values = weights;
    if (values == null) return [5, 5, 5, 5];

    final strongest = values.reduce(math.max);
    if (strongest <= 0) return [5, 5, 5, 5];

    return [for (final weight in values) (weight / strongest * 10).roundToDouble()];
  }
}

/// The subset of a `places` row the trip screens need. [placesId] is null for
/// a custom wishlist pin, which has no `places` row.
class TripPlace {
  const TripPlace({
    required this.placesId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.address,
    this.kecamatan,
    this.photoUrl,
    this.estimatedVisitMinutes,
    this.isOutdoor = false,
    this.rating,
  });

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    return TripPlace(
      placesId: json['places_id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String? ?? '',
      lat: _toDouble(json['lat']) ?? 0,
      lng: _toDouble(json['lng']) ?? 0,
      address: json['address'] as String?,
      kecamatan: json['kecamatan'] as String?,
      photoUrl: AppConfig.resolveMediaUrl(json['photo_url'] as String?),
      estimatedVisitMinutes: json['estimated_visit_minutes'] as int?,
      isOutdoor: json['is_outdoor'] as bool? ?? false,
      rating: _toDouble(json['rating']),
    );
  }

  final int? placesId;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String? address;
  final String? kecamatan;
  final String? photoUrl;
  final int? estimatedVisitMinutes;
  final bool isOutdoor;
  final double? rating;
}

/// One of the top-3 hotels from `GET /api/trips/{id}/hotel-options`.
class HotelOption {
  const HotelOption({required this.place, required this.rank});

  final TripPlace place;
  final int rank;
}

class ItineraryItem {
  const ItineraryItem({
    required this.itineraryItemsId,
    required this.visitOrder,
    required this.isFromWishlist,
    this.place,
    this.polylineToHere,
    this.visitedAt,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    final place = json['place'];
    final customName = json['custom_name'] as String?;
    final visitedAt = json['visited_at'];

    TripPlace? stopPlace;
    if (place is Map<String, dynamic>) {
      stopPlace = TripPlace.fromJson(place);
    } else if (customName != null) {
      stopPlace = TripPlace(
        placesId: null,
        name: customName,
        type: '',
        lat: _toDouble(json['custom_lat']) ?? 0,
        lng: _toDouble(json['custom_lng']) ?? 0,
        estimatedVisitMinutes: json['custom_visit_minutes'] as int?,
      );
    }

    return ItineraryItem(
      itineraryItemsId: json['itinerary_items_id'] as int,
      visitOrder: json['visit_order'] as int,
      isFromWishlist: json['source'] == 'wishlist',
      place: stopPlace,
      polylineToHere: json['polyline_to_here'] as String?,
      visitedAt: visitedAt == null ? null : DateTime.tryParse(visitedAt.toString()),
    );
  }

  final int itineraryItemsId;
  final int visitOrder;
  final bool isFromWishlist;
  final TripPlace? place;
  final String? polylineToHere;
  final DateTime? visitedAt;

  bool get isVisited => visitedAt != null;

  ItineraryItem copyWith({DateTime? Function()? visitedAt}) {
    return ItineraryItem(
      itineraryItemsId: itineraryItemsId,
      visitOrder: visitOrder,
      isFromWishlist: isFromWishlist,
      place: place,
      polylineToHere: polylineToHere,
      visitedAt: visitedAt == null ? this.visitedAt : visitedAt(),
    );
  }
}

class ItineraryDay {
  const ItineraryDay({
    required this.itineraryDaysId,
    required this.dayNumber,
    required this.items,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ItineraryItem.fromJson)
        .toList()
      ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));

    return ItineraryDay(
      itineraryDaysId: json['itinerary_days_id'] as int,
      dayNumber: json['day_number'] as int,
      items: items,
    );
  }

  final int itineraryDaysId;
  final int dayNumber;
  final List<ItineraryItem> items;

  ItineraryDay withItems(List<ItineraryItem> items) {
    return ItineraryDay(itineraryDaysId: itineraryDaysId, dayNumber: dayNumber, items: items);
  }
}

/// Start/end point of every day: a catalog hotel or a custom map pin.
class TripHotel {
  const TripHotel({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;
}

/// `GET /api/trips/{id}` with its itinerary.
class Trip {
  const Trip({
    required this.tripsId,
    required this.title,
    required this.numDays,
    required this.budgetTotal,
    required this.startDate,
    required this.dailyStartTime,
    required this.dailyEndTime,
    required this.days,
    this.hotel,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final hotelPlace = json['hotel_place'];
    final customLat = _toDouble(json['hotel_lat']);
    final customLng = _toDouble(json['hotel_lng']);

    TripHotel? hotel;
    if (hotelPlace is Map<String, dynamic>) {
      final place = TripPlace.fromJson(hotelPlace);
      hotel = TripHotel(name: place.name, lat: place.lat, lng: place.lng);
    } else if (customLat != null && customLng != null) {
      hotel = TripHotel(
        name: json['hotel_custom_name'] as String? ?? '',
        lat: customLat,
        lng: customLng,
      );
    }

    final days = (json['days'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ItineraryDay.fromJson)
        .toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Trip(
      tripsId: json['trips_id'] as int,
      title: json['title'] as String? ?? '',
      numDays: json['num_days'] as int,
      budgetTotal: json['budget_total'] as int,
      startDate: _toDate(json['start_date']) ?? DateTime.now(),
      dailyStartTime: json['daily_start_time'] as String? ?? '09:00',
      dailyEndTime: json['daily_end_time'] as String? ?? '19:00',
      days: days,
      hotel: hotel,
    );
  }

  final int tripsId;
  final String title;
  final int numDays;
  final int budgetTotal;
  final DateTime startDate;
  final String dailyStartTime;
  final String dailyEndTime;
  final List<ItineraryDay> days;
  final TripHotel? hotel;

  DateTime dateOfDay(int dayNumber) => startDate.add(Duration(days: dayNumber - 1));

  Trip withDay(ItineraryDay day) {
    return Trip(
      tripsId: tripsId,
      title: title,
      numDays: numDays,
      budgetTotal: budgetTotal,
      startDate: startDate,
      dailyStartTime: dailyStartTime,
      dailyEndTime: dailyEndTime,
      hotel: hotel,
      days: [
        for (final existing in days)
          existing.itineraryDaysId == day.itineraryDaysId ? day : existing,
      ],
    );
  }
}

/// Day flags that only `POST /generate` reports (US4 edge cases).
class GeneratedDayFlags {
  const GeneratedDayFlags({required this.isOverpacked, required this.isShortOfPlaces});

  final bool isOverpacked;
  final bool isShortOfPlaces;
}

class GenerateResult {
  const GenerateResult({required this.dayFlags, required this.droppedWishlistCount, this.closedWishlistCount = 0});

  factory GenerateResult.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List? ?? const []).cast<Map<String, dynamic>>();
    return GenerateResult(
      dayFlags: {
        for (final day in days)
          day['day_number'] as int: GeneratedDayFlags(
            isOverpacked: day['padat'] == true,
            isShortOfPlaces: day['tidak_muat'] == true,
          ),
      },
      droppedWishlistCount: (json['dropped_wishlist_places'] as List? ?? const []).length,
      closedWishlistCount: (json['closed_wishlist_places'] as List? ?? const []).length,
    );
  }

  final Map<int, GeneratedDayFlags> dayFlags;
  final int droppedWishlistCount;

  /// Wishlist places closed on every day of the trip, left out.
  final int closedWishlistCount;
}
