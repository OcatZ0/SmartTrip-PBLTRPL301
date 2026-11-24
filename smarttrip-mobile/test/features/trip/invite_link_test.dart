import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/core/router/app_router.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/screens/saved_trip/join_invite_screen.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';
import 'package:smarttrip_mobile/services/google_auth_service.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';
import 'package:smarttrip_mobile/services/weather_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';
import 'trip_models_test.dart' show tripJson;

class _InviteTripService extends FakeTripService {
  final joined = <String>[];

  @override
  Future<int> joinAsViewer(String linkOrToken) async {
    joined.add(linkOrToken);
    if (linkOrToken == 'tok123') return 8;
    throw const ServerFailure(404);
  }
}

class _FixedTrip extends TripDetailController {
  @override
  Future<Trip> build(int tripsId) async => Trip.fromJson(tripJson());
}

Widget _screenApp(TripService trips, String token) {
  return ProviderScope(
    overrides: [tripServiceProvider.overrideWithValue(trips)],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(initialLocation: '/undangan/$token', routes: [
        GoRoute(path: '/undangan/:token', builder: (_, state) => JoinInviteScreen(token: state.pathParameters['token']!)),
        GoRoute(path: '/shared-trip/:id', builder: (_, state) => Text('dibuka ${state.pathParameters['id']}')),
        GoRoute(path: '/trips', builder: (_, __) => const Text('trip tersimpan')),
      ]),
    ),
  );
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('an invite link joins the trip and opens it read-only', (tester) async {
    final trips = _InviteTripService();
    await tester.pumpWidget(_screenApp(trips, 'tok123'));
    await tester.pumpAndSettle();

    expect(trips.joined, ['tok123']);
    expect(find.text('dibuka 8'), findsOneWidget);
  });

  testWidgets('a disabled invite link says so', (tester) async {
    await tester.pumpWidget(_screenApp(_InviteTripService(), 'mati'));
    await tester.pumpAndSettle();

    expect(find.text('Tautan undangan tidak valid atau sudah dimatikan pemilik trip.'), findsOneWidget);
    await tester.tap(find.text('Ke Trip Tersimpan'));
    await tester.pumpAndSettle();
    expect(find.text('trip tersimpan'), findsOneWidget);
  });

  testWidgets('a logged-out user keeps the invite link through login', (tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final trips = _InviteTripService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
        tripDetailProvider.overrideWith(_FixedTrip.new),
        tripForecastProvider.overrideWith((ref, tripsId) async => null),
        ...catalogOverrides(trips: trips),
      ],
      child: const SmartTripApp(),
    ));
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(routerProvider);
    router.go('/undangan/tok123');
    await tester.pumpAndSettle();

    expect(trips.joined, isEmpty);
    expect(router.state.uri.toString(), '/login?from=%2Fundangan%2Ftok123');

    await tester.enterText(find.byType(TextFormField).at(0), 'budi@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(trips.joined, ['tok123']);
    expect(router.state.uri.path, '/shared-trip/8');
  });
}
