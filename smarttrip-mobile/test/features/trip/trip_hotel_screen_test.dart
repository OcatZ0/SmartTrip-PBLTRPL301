import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/screens/trip/trip_hotel_screen.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';
import 'trip_models_test.dart' show tripJson;

class _FixedTrip extends TripDetailController {
  @override
  Future<Trip> build(int tripsId) async => Trip.fromJson(tripJson());
}

class _HotelTripService extends FakeTripService {
  final hotels = <int>[];
  final dayPoints = <(int, Map<String, dynamic>?, Map<String, dynamic>?)>[];

  @override
  Future<void> setCatalogHotel(int tripsId, int placesId) async => hotels.add(placesId);

  @override
  Future<void> setDayPoints(
    int tripsId,
    int dayNumber, {
    Map<String, dynamic>? start,
    Map<String, dynamic>? end,
    bool resetEnd = false,
  }) async {
    dayPoints.add((dayNumber, start, end));
  }
}

const _hotel = TripPlace(placesId: 7, name: 'Hotel Harmoni', type: 'lodging', lat: 1.13, lng: 104.03);

Future<_HotelTripService> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 2400) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final trips = _HotelTripService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripServiceProvider.overrideWithValue(trips),
        tripDetailProvider.overrideWith(_FixedTrip.new),
        hotelOptionsProvider.overrideWith((ref, tripsId) async => const [HotelOption(place: _hotel, rank: 1)]),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const TripHotelScreen(tripsId: 5)),
            GoRoute(path: '/trips/:tripsId/generate', builder: (_, __) => const Text('generate')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('simple mode sets one hotel for every day', (tester) async {
    final trips = await _open(tester);

    expect(find.text('Titik mulai & selesai per hari'), findsNothing);
    await tester.tap(find.text('Hotel Harmoni'));
    await tester.pump();
    await tester.tap(find.text('Buat Itinerary Cerdas Sekarang'));
    await tester.pumpAndSettle();

    expect(trips.hotels, [7]);
    expect(trips.dayPoints, isEmpty);
    expect(find.text('generate'), findsOneWidget);
  });

  testWidgets('detail mode lists every day with the main hotel and the same end by default', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotel Harmoni'));
    await tester.pump();

    expect(find.text('Titik mulai & selesai per hari'), findsOneWidget);
    expect(find.textContaining('Hari 1 · '), findsOneWidget);
    expect(find.textContaining('Hari 2 · '), findsOneWidget);
    // The hotel card, the picked-hotel bar and both days' start: every day
    // starts at the main hotel and ends where it starts until changed.
    expect(find.text('Hotel Harmoni'), findsNWidgets(4));
    expect(find.text('Sama dengan titik awal'), findsNWidgets(2));
    expect(find.text('Ganti'), findsNWidgets(4));
  });
}
