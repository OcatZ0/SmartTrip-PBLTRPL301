import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/place.dart';
import 'package:smarttrip_mobile/screens/catalog/widgets/place_bits.dart';
import 'package:smarttrip_mobile/screens/wishlist/wishlist_screen.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

CatalogPlace _place(int placesId, String name, {double? rating}) => CatalogPlace(
      placesId: placesId,
      name: name,
      type: 'attraction',
      kecamatan: 'Galang',
      rating: rating,
      reviewCount: 10,
      estimatedCostIdr: 15000,
      categories: const [pantai],
    );

Future<FakeWishlistService> _open(WidgetTester tester, {AuthUser? user = testUser}) async {
  tester.view.physicalSize = const Size(412, 1600) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final wishlist = FakeWishlistService(saved: {1, 2, 3})
    ..savedPlaces = [
      _place(1, 'Pantai Melur', rating: 4.2),
      _place(2, 'Jembatan Barelang', rating: 4.8),
      _place(3, 'Pulau Abang', rating: 4.5),
    ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
        ...catalogOverrides(wishlist: wishlist),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const WishlistScreen()),
            GoRoute(path: '/login', builder: (_, __) => const Text('login')),
            GoRoute(path: '/places/:placesId', builder: (_, state) => Text('place ${state.pathParameters['placesId']}')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return wishlist;
}

List<String> _names(WidgetTester tester) {
  const names = {'Pantai Melur', 'Jembatan Barelang', 'Pulau Abang'};
  final texts = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>();
  return texts.where(names.contains).toList();
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('lists the saved places, newest first, and searches them', (tester) async {
    await _open(tester);

    expect(find.text('3 tempat tersimpan'), findsOneWidget);
    expect(_names(tester), ['Pantai Melur', 'Jembatan Barelang', 'Pulau Abang']);

    await tester.enterText(find.byType(TextField), 'pulau');
    await tester.pumpAndSettle();
    expect(_names(tester), ['Pulau Abang']);
  });

  testWidgets('sorts by rating', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Baru disimpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rating tertinggi'));
    await tester.pumpAndSettle();

    expect(_names(tester), ['Jembatan Barelang', 'Pulau Abang', 'Pantai Melur']);
  });

  testWidgets('the heart removes a place from the wishlist', (tester) async {
    final wishlist = await _open(tester);

    await tester.tap(find.byType(CatalogHeartButton).first);
    await tester.pumpAndSettle();

    expect(wishlist.removed, [1]);
    expect(find.text('Pantai Melur dihapus dari wishlist.'), findsOneWidget);
    expect(_names(tester), ['Jembatan Barelang', 'Pulau Abang']);
  });

  testWidgets('select mode removes several places at once', (tester) async {
    final wishlist = await _open(tester);

    await tester.longPress(find.text('Pantai Melur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulau Abang'));
    await tester.pumpAndSettle();
    expect(find.text('2 dipilih'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(wishlist.removed, [1, 3]);
    expect(find.text('2 tempat dihapus dari wishlist.'), findsOneWidget);
    expect(_names(tester), ['Jembatan Barelang']);
  });

  testWidgets('a guest is asked to log in', (tester) async {
    await _open(tester, user: null);

    expect(find.text('Masuk untuk melihat wishlist'), findsOneWidget);
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
