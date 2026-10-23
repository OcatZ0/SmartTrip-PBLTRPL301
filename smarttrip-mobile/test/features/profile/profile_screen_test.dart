import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/router/app_router.dart';
import 'package:smarttrip_mobile/core/router/app_routes.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

class _ProfileTripService extends FakeTripService {
  final saved = <({Set<int> categoryIds, List<double> ratings})>[];

  @override
  Future<PreferenceDefaults> fetchPreferenceDefaults() async {
    return const PreferenceDefaults(categoryIds: {1}, weights: [0.4, 0.3, 0.15, 0.15]);
  }

  @override
  Future<void> saveProfileDefaults({required Set<int> categoryIds, required List<double> ratings}) async {
    saved.add((categoryIds: categoryIds, ratings: ratings));
  }
}

class _SignOutSession extends FakeSessionController {
  _SignOutSession([AuthUser user = testUser]) : super(user);

  @override
  Future<void> signOut() async => state = const AsyncData<AuthUser?>(null);
}

Future<_ProfileTripService> _openProfile(WidgetTester tester, {AuthUser user = testUser}) async {
  tester.view.physicalSize = const Size(412, 1400) * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = [const Locale('id')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final trips = _ProfileTripService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sessionControllerProvider.overrideWith(() => _SignOutSession(user)),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        ...catalogOverrides(trips: trips),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(routerProvider).go(AppRoutes.profile);
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('shows the user, the saved interests and weights, and saves each change on its own', (tester) async {
    final trips = await _openProfile(tester);

    expect(find.text('Minat kamu'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Simpan preferensi'), findsNothing);
    // 0.4 / 0.3 / 0.15 / 0.15 back on 0-10 sliders, the strongest at 10.
    expect([for (final slider in tester.widgetList<Slider>(find.byType(Slider))) slider.value], [10, 7, 4, 4]);

    await tester.tap(find.text('Kuliner Seafood'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(trips.saved.single.categoryIds, {1, 2});
    expect(trips.saved.single.ratings, [10, 7, 4, 4]);
  });

  testWidgets('the last interest cannot be unpicked', (tester) async {
    final trips = await _openProfile(tester);

    await tester.tap(find.text('Pantai'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(trips.saved, isEmpty);
    expect(find.text('Pilih minimal satu minat.'), findsOneWidget);
  });

  testWidgets('a Google-only account sets a password without the current one', (tester) async {
    await _openProfile(
      tester,
      user: const AuthUser(usersId: 8, name: 'Sari Google', email: 'sari@gmail.com', role: 'user', hasPassword: false),
    );

    expect(find.text('SG'), findsOneWidget);
    await tester.ensureVisible(find.text('Ganti kata sandi'));
    await tester.tap(find.text('Ganti kata sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi saat ini'), findsNothing);
    expect(find.textContaining('dibuat lewat Google'), findsOneWidget);
    expect(find.text('Kata sandi baru'), findsOneWidget);
  });

  testWidgets('Keluar asks first, then signs out to the login screen', (tester) async {
    await _openProfile(tester);

    await tester.ensureVisible(find.text('Keluar'));
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('Minat kamu'), findsNothing);
    expect(find.text('Masuk'), findsWidgets);
  });
}
