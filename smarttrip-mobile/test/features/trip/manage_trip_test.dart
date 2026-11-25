import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/saved_trip.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/core/notifications/local_notification_service.dart';
import 'package:smarttrip_mobile/screens/saved_trip/widgets/trip_card.dart';
import 'package:smarttrip_mobile/screens/trip/itinerary_screen.dart';
import 'package:smarttrip_mobile/screens/trip/trip_setup_screen.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';
import 'package:smarttrip_mobile/services/weather_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';
import 'trip_models_test.dart' show tripJson;

class _ManageTripService extends FakeTripService {
  final updates = <({String? title, int numDays, int budget})>[];
  final deleted = <int>[];

  @override
  Future<void> updateTrip(
    int tripsId, {
    String? title,
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    updates.add((title: title, numDays: numDays, budget: budgetTotal));
  }

  @override
  Future<void> deleteTrip(int tripsId) async => deleted.add(tripsId);
}

/// tripJson(): 2 days, 1.500.000, stops on day 1 (so it has an itinerary).
class _QuietNotifications extends LocalNotificationService {
  @override
  Future<void> scheduleDayReminders({
    required int tripsId,
    required List<({DateTime at, String title, String body})> days,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> scheduleWeatherReminder({
    required int tripsId,
    required DateTime startDate,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}
}

class _FixedTrip extends TripDetailController {
  @override
  Future<Trip> build(int tripsId) async => Trip.fromJson(tripJson());
}

Future<_ManageTripService> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(412, 2000) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final trips = _ManageTripService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripServiceProvider.overrideWithValue(trips),
        tripDetailProvider.overrideWith(_FixedTrip.new),
        tripForecastProvider.overrideWith((ref, tripsId) async => null),
        localNotificationServiceProvider.overrideWithValue(_QuietNotifications()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('awal'), routes: [
            GoRoute(path: 'form', builder: (_, __) => home),
          ]),
          GoRoute(path: '/trips/:id/edit', builder: (_, __) => const Text('form ubah')),
          GoRoute(path: '/trips/:id/wishlist', builder: (_, state) => Text('wishlist ${state.pathParameters['id']}')),
        ], initialLocation: '/form'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('edit mode is prefilled and a title change saves without a warning', (tester) async {
    final trips = await _pump(tester, const TripSetupScreen(editTripsId: 5));

    expect(find.text('Ubah Trip'), findsOneWidget);
    final title = find.widgetWithText(TextField, 'Trip Batam');
    expect(title, findsOneWidget);

    await tester.enterText(title, 'Trip Keluarga');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Itinerary akan dibuat ulang'), findsNothing);
    expect(trips.updates.single, (title: 'Trip Keluarga', numDays: 2, budget: 1500000));
    expect(find.text('awal'), findsOneWidget); // back where it came from
  });

  testWidgets('changing the budget of a trip with an itinerary asks first', (tester) async {
    final trips = await _pump(tester, const TripSetupScreen(editTripsId: 5));

    await tester.enterText(find.widgetWithText(TextField, '1.500.000'), '2.000.000');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Itinerary akan dibuat ulang'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(trips.updates, isEmpty);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(trips.updates.single.budget, 2000000);
  });

  testWidgets('the trip card deletes a trip after confirmation', (tester) async {
    final trips = await _pump(
      tester,
      const Scaffold(
        body: TripCard(trip: TripModel(id: 9, title: 'Trip Lama', status: TripStatus.draft, numDays: 2)),
      ),
    );

    await tester.tap(find.byTooltip('Kelola trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus trip?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(trips.deleted, [9]);
    expect(find.text('Trip "Trip Lama" dihapus'), findsOneWidget);
  });

  testWidgets('Buat Ulang Itinerary asks first, then opens the wishlist step', (tester) async {
    await _pump(tester, const ItineraryScreen(tripsId: 5));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Ulang Itinerary'));
    await tester.pumpAndSettle();
    expect(find.text('Buat ulang itinerary?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('wishlist 5'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Ulang Itinerary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('wishlist 5'), findsOneWidget);
  });
}
