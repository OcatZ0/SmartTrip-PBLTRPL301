import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/screens/trip/trip_setup_screen.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

class _SetupTripService extends FakeTripService {
  final created = <({int numDays, DateTime startDate, String start, String end, int budget})>[];

  @override
  Future<int> createTrip({
    String? title,
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    created.add((numDays: numDays, startDate: startDate, start: dailyStartTime, end: dailyEndTime, budget: budgetTotal));
    return 1;
  }
}

Future<_SetupTripService> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 2000) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final trips = _SetupTripService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tripServiceProvider.overrideWithValue(trips)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const TripSetupScreen()),
            GoRoute(path: '/trips/:tripsId/wishlist', builder: (_, __) => const Text('wishlist step')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return trips;
}

/// The calendar's day button for [day] of the shown month.
Finder _day(int day) => find.descendant(of: find.byType(InkWell), matching: find.text('$day'));

void main() {
  setUpAll(loadAppFont);

  testWidgets('the calendar picks the first and last day, a preset sets the hours, and the trip is created', (tester) async {
    final trips = await _open(tester);
    expect(find.text('1 / 4'), findsOneWidget);

    // The default start is a week ahead; go to next month so every day is pickable.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(_day(10).first);
    await tester.pump();
    // The date summary and the bottom bar both say it.
    expect(find.text('1 Hari'), findsNWidgets(2));
    await tester.tap(_day(13).first);
    await tester.pump();
    expect(find.text('4 Hari'), findsNWidgets(2));

    // Dragging from the 15th to the 17th picks those three days.
    final from = tester.getCenter(_day(15).first);
    final to = tester.getCenter(_day(17).first);
    final drag = await tester.startGesture(from);
    await drag.moveBy(const Offset(20, 0));
    await tester.pump();
    await drag.moveTo(to);
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(find.text('3 Hari'), findsNWidgets(2));

    // Tapping still works after a drag.
    await tester.tap(_day(10).first);
    await tester.pump();
    await tester.tap(_day(13).first);
    await tester.pump();
    expect(find.text('4 Hari'), findsNWidgets(2));

    await tester.tap(find.text('Padat'));
    await tester.pump();

    await tester.tap(find.text('Lanjut ke wishlist'));
    await tester.pumpAndSettle();

    // The calendar opens on the default start's month, a week from today.
    final opened = DateTime.now().add(const Duration(days: 7));
    final created = trips.created.single;
    expect(created.startDate, DateTime(opened.year, opened.month + 1, 10));
    expect(created.numDays, 4);
    expect((created.start, created.end), ('07:00', '21:00'));
    expect(created.budget, 1500000);
    expect(find.text('wishlist step'), findsOneWidget);
  });
}
