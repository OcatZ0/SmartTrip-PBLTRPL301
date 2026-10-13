import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/features/trip/data/trip_models.dart';

Map<String, dynamic> tripJson({Map<String, dynamic>? hotelPlace}) => {
      'trips_id': 5,
      'title': 'Trip Batam',
      'num_days': 2,
      'budget_total': 1500000,
      'start_date': '2026-10-20T00:00:00.000000Z',
      'daily_start_time': '09:00:00',
      'daily_end_time': '19:00:00',
      'hotel_custom_name': 'Rumah Saudara',
      'hotel_lat': '1.1300000',
      'hotel_lng': '104.0300000',
      'hotel_place': hotelPlace,
      'days': [
        {
          'itinerary_days_id': 11,
          'day_number': 2,
          'items': [],
        },
        {
          'itinerary_days_id': 10,
          'day_number': 1,
          'items': [
            {
              'itinerary_items_id': 101,
              'visit_order': 2,
              'source': 'recommended',
              'visited_at': null,
              'place': {
                'places_id': 3,
                'name': 'Pantai Melur',
                'type': 'attraction',
                'lat': '1.0500000',
                'lng': '104.1000000',
                'estimated_visit_minutes': 90,
                'is_outdoor': true,
              },
            },
            {
              'itinerary_items_id': 100,
              'visit_order': 1,
              'source': 'wishlist',
              'visited_at': '2026-10-20T03:00:00.000000Z',
              'polyline_to_here': 'abc',
              'place': null,
              'custom_name': 'Rumah Saudara',
              'custom_lat': '1.1302000',
              'custom_lng': '104.0302000',
              'custom_visit_minutes': 45,
            },
          ],
        },
      ],
    };

void main() {
  test('parses decimal strings, sorts days and stops, and reads the custom hotel pin', () {
    final trip = Trip.fromJson(tripJson());

    expect(trip.startDate, DateTime(2026, 10, 20));
    expect(trip.hotel?.name, 'Rumah Saudara');
    expect(trip.hotel?.lat, 1.13);
    expect(trip.days.map((day) => day.dayNumber), [1, 2]);

    final items = trip.days.first.items;
    expect(items.map((item) => item.visitOrder), [1, 2]);
    expect(items[0].isFromWishlist, isTrue);
    expect(items[0].isVisited, isTrue);
    expect(items[0].place?.placesId, isNull);
    expect(items[0].place?.name, 'Rumah Saudara');
    expect(items[0].place?.lat, 1.1302);
    expect(items[0].place?.estimatedVisitMinutes, 45);
    expect(items[1].place?.lat, 1.05);
    expect(items[1].place?.isOutdoor, isTrue);
    expect(trip.dateOfDay(2), DateTime(2026, 10, 21));
  });

  test('a catalog hotel takes precedence over the custom pin fields', () {
    final trip = Trip.fromJson(tripJson(hotelPlace: {
      'places_id': 9,
      'name': 'Harbour Bay Hotel',
      'type': 'lodging',
      'lat': '1.1600000',
      'lng': '104.0000000',
    }));

    expect(trip.hotel?.name, 'Harbour Bay Hotel');
    expect(trip.hotel?.lat, 1.16);
  });

  test('profile defaults without weights leave the sliders to their own default', () {
    final defaults = PreferenceDefaults.fromJson({
      'categories': [
        {'categories_id': 1},
        {'categories_id': 4},
      ],
      'default_weight_kategori': null,
      'default_weight_jarak': null,
      'default_weight_anggaran': null,
      'default_weight_rating': null,
    });

    expect(defaults.categoryIds, {1, 4});
    expect(defaults.weights, isNull);
  });
}
