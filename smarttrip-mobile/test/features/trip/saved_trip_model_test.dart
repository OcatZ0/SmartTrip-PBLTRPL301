import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/models/saved_trip.dart';

void main() {
  test('a trip of GET /api/trips becomes a Trip Tersimpan card', () {
    final trip = TripModel.fromJson({
      'trips_id': 7,
      'title': 'Wisata Batam',
      'num_days': 3,
      'start_date': '2026-09-12T00:00:00.000000Z',
      'budget_total': 2500000,
      'summary': {
        'status': 'berlangsung',
        'current_day': 2,
        'places_count': 6,
        'visited_count': 3,
        'wishlist_count': 0,
        'spent_estimate_idr': 1850000,
        'photo_urls': ['https://example.com/a.jpg', null, 'https://example.com/b.jpg'],
      },
    });

    expect(trip.status, TripStatus.berlangsung);
    expect(trip.currentDay, 2);
    expect(trip.numDestinations, 6);
    expect(trip.visitedCount, 3);
    expect(trip.budgetSpentLabel, 'Rp1.850.000');
    expect(trip.photoUrls, ['https://example.com/a.jpg', 'https://example.com/b.jpg']);
    expect(trip.endDate, DateTime.utc(2026, 9, 14));
  });

  test('a trip without a summary or a title is a draft with a fallback title', () {
    final trip = TripModel.fromJson({'trips_id': 1, 'title': null, 'num_days': 1});

    expect(trip.status, TripStatus.draft);
    expect(trip.title, 'Trip tanpa judul');
    expect(trip.currentDay, 1);
    expect(trip.photoUrls, isEmpty);
  });
}
