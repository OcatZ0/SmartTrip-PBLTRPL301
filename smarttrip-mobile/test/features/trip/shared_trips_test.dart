import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/screens/saved_trip/widgets/shared_trips_view.dart';
import 'package:smarttrip_mobile/screens/trip/itinerary_screen.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';
import 'package:smarttrip_mobile/services/weather_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';
import 'trip_models_test.dart' show tripJson;

class _SharedTripService extends FakeTripService {
  final joined = <String>[];

  @override
  Future<List<SharedTripSummary>> fetchSharedTrips() async => [
        SharedTripSummary.fromJson({
          'trips_id': 8,
          'title': 'Trip Bareng',
          'num_days': 3,
          'start_date': '2026-12-01',
          'days_count': 3,
          'owner': {'users_id': 1, 'name': 'Budi'},
        }),
      ];

  @override
  Future<int> joinAsViewer(String linkOrToken) async {
    joined.add(linkOrToken);
    if (TripService.inviteTokenFrom(linkOrToken) == 'tok123') return 8;
    throw const ServerFailure(404);
  }
}

class _FixedTrip extends TripDetailController {
  @override
  Future<Trip> build(int tripsId) async => Trip.fromJson(tripJson());
}

Widget _app(List<Override> overrides, GoRouter router) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUpAll(loadAppFont);

  group('TripService.inviteTokenFrom', () {
    test('takes the token from a full invite link', () {
      expect(TripService.inviteTokenFrom(' https://smarttrips.my.id/undangan/tok123 '), 'tok123');
    });

    test('keeps a bare token as is', () {
      expect(TripService.inviteTokenFrom('tok123'), 'tok123');
    });
  });

  testWidgets('lists shared trips with their owner and joins through a pasted link', (tester) async {
    tester.view.physicalSize = const Size(412, 1600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final trips = _SharedTripService();
    await tester.pumpWidget(_app(
      [tripServiceProvider.overrideWithValue(trips)],
      GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: SingleChildScrollView(child: SharedTripsView()))),
        GoRoute(path: '/shared-trip/:id', builder: (_, state) => Text('dibuka ${state.pathParameters['id']}')),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trip Bareng'), findsOneWidget);
    expect(find.text('Dari Budi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'https://smarttrips.my.id/undangan/salah');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    expect(find.text('Tautan undangan tidak valid atau sudah dimatikan pemilik trip.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'https://smarttrips.my.id/undangan/tok123');
    await tester.tap(find.text('Gabung'));
    await tester.pumpAndSettle();
    expect(find.text('dibuka 8'), findsOneWidget);
  });

  testWidgets('a read-only itinerary hides everything that changes the trip', (tester) async {
    tester.view.physicalSize = const Size(412, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
      [
        tripDetailProvider.overrideWith(_FixedTrip.new),
        tripForecastProvider.overrideWith((ref, tripsId) async => null),
      ],
      GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const ItineraryScreen(tripsId: 5, readOnly: true))]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trip ini dibagikan kepadamu. Kamu hanya dapat melihatnya.'), findsOneWidget);
    expect(find.text('Pantai Melur'), findsOneWidget);
    expect(find.text('Ganti'), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Ekspor PDF'), findsOneWidget);
    expect(find.text('Undang ke Itinerary'), findsNothing);
  });
}
