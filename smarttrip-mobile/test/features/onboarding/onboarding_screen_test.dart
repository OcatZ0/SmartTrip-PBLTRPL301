import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

class _OnboardingTrips extends FakeTripService {
  final saved = <({Set<int> categoryIds, List<double> ratings})>[];
  final categoryRequests = <bool>[];

  @override
  Future<List<TripCategory>> fetchCategories({bool onboardingOnly = false}) async {
    categoryRequests.add(onboardingOnly);
    return const [kulinerSeafood, pantai];
  }

  @override
  Future<void> saveProfileDefaults({required Set<int> categoryIds, required List<double> ratings}) async {
    saved.add((categoryIds: categoryIds, ratings: ratings));
  }
}

const _newUser = AuthUser(usersId: 9, name: 'Dian Lestari', email: 'dian@example.com', role: 'user', hasInterests: false);

Future<_OnboardingTrips> _launch(WidgetTester tester, AuthUser user) async {
  tester.view.physicalSize = const Size(412, 917) * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = const [Locale('id')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final trips = _OnboardingTrips();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        ...catalogOverrides(trips: trips),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  testWidgets('a user without interests picks at least one before reaching the app', (tester) async {
    final trips = await _launch(tester, _newUser);

    expect(find.text('Hai Dian, apa yang kamu suka?'), findsOneWidget);
    expect(trips.categoryRequests.first, isTrue, reason: 'asks for the onboarding categories');

    // Nothing picked yet: the button does nothing.
    await tester.tap(find.text('Mulai Jelajahi'));
    await tester.pumpAndSettle();
    expect(trips.saved, isEmpty);

    await tester.tap(find.text('Pantai'));
    await tester.pumpAndSettle();
    expect(find.text('1 minat dipilih'), findsOneWidget);

    await tester.tap(find.text('Mulai Jelajahi'));
    await tester.pumpAndSettle();

    expect(trips.saved.single.categoryIds, {pantai.categoriesId});
    expect(trips.saved.single.ratings, [5, 5, 5, 5]);
    expect(find.text('Hai Dian, apa yang kamu suka?'), findsNothing);
    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
  });

  testWidgets('a user who already has interests goes straight to the catalog', (tester) async {
    final trips = await _launch(tester, testUser);

    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
    expect(trips.categoryRequests, isNot(contains(true)));
  });
}
