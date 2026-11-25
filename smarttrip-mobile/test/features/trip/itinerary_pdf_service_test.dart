import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/models/weather.dart';
import 'package:smarttrip_mobile/services/itinerary_pdf_assets.dart';
import 'package:smarttrip_mobile/services/itinerary_pdf_plan.dart';
import 'package:smarttrip_mobile/services/itinerary_pdf_service.dart';
import 'package:smarttrip_mobile/services/pdf_map.dart';
import 'package:smarttrip_mobile/services/polyline_codec.dart';

/// Google's polyline sample: (38.5, -120.2) -> (40.7, -120.95) -> (43.252, -126.453).
const _samplePolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

Trip _trip({
  required String title,
  required List<Map<String, dynamic>> items,
  String dailyEnd = '20:00:00',
  String? polylineToEnd,
}) {
  return Trip.fromJson({
    'trips_id': 7,
    'title': title,
    'num_days': 2,
    'budget_total': 1500000,
    'start_date': '2026-12-01',
    'daily_start_time': '08:00:00',
    'daily_end_time': dailyEnd,
    'days': [
      {
        'itinerary_days_id': 1,
        'day_number': 1,
        'start': {'name': 'Hotel Harmoni', 'lat': 1.13, 'lng': 104.03, 'places_id': 3},
        'polyline_to_end': polylineToEnd,
        'items': items,
      },
      // A day without stops must still render.
      {'itinerary_days_id': 2, 'day_number': 2, 'items': <Map<String, dynamic>>[]},
    ],
  });
}

Map<String, dynamic> _stop(int id, String name, double lat, double lng,
        {int minutes = 60, int? cost, bool outdoor = false, String source = 'algorithm', String? polyline, String? photo}) =>
    {
      'itinerary_items_id': id,
      'visit_order': id,
      'source': source,
      'polyline_to_here': polyline,
      'place': {
        'places_id': id,
        'name': name,
        'type': 'attraction',
        'lat': lat,
        'lng': lng,
        'kecamatan': 'Nongsa',
        'estimated_visit_minutes': minutes,
        'estimated_cost_idr': cost,
        'is_outdoor': outdoor,
        'rating': 4.6,
        'photo_url': photo,
      },
    };

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  group('plan', () {
    test('times each stop from the daily start, the leg and the visit length', () {
      final plan = ItineraryPdfPlan.of(_trip(title: 'T', items: [
        _stop(1, 'Pantai Melur', 1.13, 104.13, minutes: 90, cost: 10000),
        _stop(2, 'Kedai Kopi', 1.13, 104.13, minutes: 30, cost: 25000),
      ]));
      final day = plan.days.first;

      // 0.1 degree of longitude at the equator, straight line x 1.35 detour.
      expect(day.stops[0].leg!.km, closeTo(15.0, 0.3));
      expect(day.stops[0].leg!.isRoad, isFalse);
      expect(day.stops[0].arriveMinute, 8 * 60 + day.stops[0].leg!.minutes);
      expect(day.stops[0].departMinute, day.stops[0].arriveMinute + 90);
      // The same spot: no travel before the second stop.
      expect(day.stops[1].arriveMinute, day.stops[0].departMinute);
      expect(day.costIdr, 35000);
      expect(day.endMinute, day.stops[1].departMinute + day.legToEnd!.minutes);
      expect(ItineraryPdfPlan.clock(day.stops[0].departMinute), matches(RegExp(r'^\d\d:\d\d$')));
    });

    test('a leg with a route uses the road length, not the straight line', () {
      final plan = ItineraryPdfPlan.of(_trip(title: 'T', items: [
        _stop(1, 'Jauh', 43.252, -126.453, polyline: _samplePolyline),
      ]));
      final leg = plan.days.first.stops.first.leg!;

      expect(leg.isRoad, isTrue);
      expect(leg.path, hasLength(3));
      final alongRoad = haversineKm(38.5, -120.2, 40.7, -120.95) + haversineKm(40.7, -120.95, 43.252, -126.453);
      expect(leg.km, closeTo(alongRoad, 0.5));
      expect(leg.km, greaterThan(haversineKm(38.5, -120.2, 43.252, -126.453)));
    });

    test('flags a day that runs past the daily end time', () {
      final plan = ItineraryPdfPlan.of(_trip(title: 'T', dailyEnd: '09:00:00', items: [
        _stop(1, 'A', 1.13, 104.03, minutes: 120),
      ]));

      expect(plan.days.first.overruns, isTrue);
      expect(plan.days.last.overruns, isFalse);
    });

    test('the checklist follows the stops and the forecast', () {
      final plan = ItineraryPdfPlan.of(_trip(title: 'T', items: [_stop(1, 'Pantai Nongsa', 1.2, 104.1, outdoor: true)]));
      final rainy = {
        DateTime(2026, 12, 1): DayForecast(date: DateTime(2026, 12, 1), weatherCode: 61, maxTemperature: 31, minTemperature: 25, rainChance: 80),
      };

      final items = ItineraryPdfService.checklist(plan, rainy);
      expect(items, contains('Payung atau jas hujan'));
      expect(items, contains('Tabir surya, topi, dan air minum'));
      expect(items, contains('Baju ganti dan sandal untuk pantai'));
      expect(ItineraryPdfService.checklist(plan, const {}), isNot(contains('Payung atau jas hujan')));
    });
  });

  group('map', () {
    test('fits every point and lists the tiles it needs', () {
      final points = [const LatLng(1.13, 104.03), const LatLng(1.18, 104.12)];
      final frame = PdfMapFrame.fit(points, width: 539, height: 230);

      expect(frame.zoom, inInclusiveRange(9, 16));
      expect(frame.tileKeys, isNotEmpty);
      expect(frame.tileKeys.first, startsWith('${frame.zoom}/'));
      for (final point in points) {
        final offset = frame.offsetOf(point);
        expect(offset.x, inInclusiveRange(0, 539));
        expect(offset.y, inInclusiveRange(0, 230));
      }
    });
  });

  group('build', () {
    test('builds a PDF with every day, including a day without stops', () async {
      final bytes = await const ItineraryPdfService().build(_trip(title: 'Liburan Batam', items: [
        _stop(10, 'Jembatan Barelang', 1.0, 104.0, cost: 0),
        {'itinerary_items_id': 11, 'visit_order': 2, 'source': 'wishlist', 'custom_name': 'Rumah Teman', 'custom_lat': 1.2, 'custom_lng': 104.1},
      ]));

      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('text outside Latin-1 does not break the export', () async {
      final bytes = await const ItineraryPdfService().build(_trip(title: 'Trip “Keluarga” – Batam 🌴', items: []));

      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('draws the app font, map tiles, photos and the forecast when they loaded', () async {
      final tile = img.encodePng(img.Image(width: 256, height: 256));
      final photo = img.encodeJpg(img.Image(width: 120, height: 80));
      final trip = _trip(title: 'Trip “Keluarga” 🌴', items: [
        _stop(1, 'Pantai Melur', 1.13, 104.13, cost: 10000, outdoor: true, photo: 'https://x.test/a.jpg'),
        _stop(2, 'Kedai Kopi', 1.14, 104.12, source: 'wishlist'),
      ]);
      final frames = ItineraryPdfService.mapFrames(ItineraryPdfPlan.of(trip));

      final assets = ItineraryPdfAssets(
        regular: pw.Font.ttf(File('assets/fonts/PlusJakartaSans-Regular.ttf').readAsBytesSync().buffer.asByteData()),
        bold: pw.Font.ttf(File('assets/fonts/PlusJakartaSans-Bold.ttf').readAsBytesSync().buffer.asByteData()),
        tiles: {for (final key in frames.expand((frame) => frame.tileKeys)) key: tile},
        photos: {'https://x.test/a.jpg': photo},
        forecast: {
          DateTime(2026, 12, 1): DayForecast(date: DateTime(2026, 12, 1), weatherCode: 61, maxTemperature: 31, minTemperature: 25, rainChance: 80),
        },
      );

      final bytes = await const ItineraryPdfService().build(trip, assets: assets, now: DateTime(2026, 11, 25));

      expect(frames, hasLength(2), reason: 'the overview and the one day with stops');
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(20000));
    });
  });
}
