import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/services/itinerary_pdf_service.dart';

Trip _trip({required String title, required List<Map<String, dynamic>> items}) {
  return Trip.fromJson({
    'trips_id': 7,
    'title': title,
    'num_days': 2,
    'budget_total': 1500000,
    'start_date': '2026-12-01',
    'daily_start_time': '08:00:00',
    'daily_end_time': '20:00:00',
    'days': [
      {
        'itinerary_days_id': 1,
        'day_number': 1,
        'start': {'name': 'Hotel Harmoni', 'lat': 1.1, 'lng': 104.0, 'places_id': 3},
        'items': items,
      },
      // A day without stops must still render.
      {'itinerary_days_id': 2, 'day_number': 2, 'items': <Map<String, dynamic>>[]},
    ],
  });
}

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  test('builds a PDF with every day, including a day without stops', () async {
    final bytes = await const ItineraryPdfService().build(_trip(title: 'Liburan Batam', items: [
      {
        'itinerary_items_id': 10,
        'visit_order': 1,
        'source': 'algorithm',
        'place': {
          'places_id': 5,
          'name': 'Jembatan Barelang',
          'type': 'wisata',
          'lat': 1.0,
          'lng': 104.0,
          'kecamatan': 'Galang',
          'estimated_visit_minutes': 60,
          'estimated_cost_idr': 0,
        },
      },
      {'itinerary_items_id': 11, 'visit_order': 2, 'source': 'wishlist', 'custom_name': 'Rumah Teman', 'custom_lat': 1.2, 'custom_lng': 104.1},
    ]));

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('text outside Latin-1 does not break the export', () async {
    final bytes = await const ItineraryPdfService().build(
      _trip(title: 'Trip “Keluarga” – Batam 🌴', items: []),
    );

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
