import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

const _greeting = 'Halo, mau ke mana hari ini?';

Future<void> _pumpCatalog(
  WidgetTester tester, {
  AuthUser? user = testUser,
  FakePlaceService? catalog,
  FakeWishlistService? wishlist,
  Size size = const Size(412, 917),
  Locale locale = const Locale('id'),
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sessionControllerProvider.overrideWith(() => FakeSessionController(user)),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        ...catalogOverrides(catalog: catalog, wishlist: wishlist),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();

  // A guest lands on login first and browses through "Lewati".
  if (user == null) {
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
  }
}

/// Taps the filter chip labelled [label], scrolling the chip bar to it first.
Future<void> _tapChip(WidgetTester tester, String label) async {
  // The chip bar is the horizontal list that holds the "Semua" chip.
  final chipBar = find.ancestor(of: find.text('Semua'), matching: find.byType(ListView)).first;
  final chip = find.descendant(of: chipBar, matching: find.text(label));
  // Drags only the chip bar: scrollUntilVisible and dragUntilVisible end with
  // ensureVisible, which would also scroll the page under the pinned header.
  final position = tester.state<ScrollableState>(find.descendant(of: chipBar, matching: find.byType(Scrollable))).position;
  var step = const Offset(-80, 0);
  for (var tries = 0; tries < 40 && chip.hitTestable().evaluate().isEmpty; tries++) {
    final before = position.pixels;
    await tester.drag(chipBar, step);
    await tester.pump();
    // At the end of the bar without finding it: the chip is the other way.
    if (position.pixels == before) step = -step;
  }
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('shows the greeting, chips from the API and the first page of places', (tester) async {
    final catalog = FakePlaceService();
    await _pumpCatalog(tester, catalog: catalog);

    expect(find.text(_greeting), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Kuliner Seafood'), findsOneWidget);
    expect(find.text('Destinasi di Batam'), findsOneWidget);
    expect(find.text('Tempat 1'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('Belum ada ulasan'), findsOneWidget);
    expect(find.text('Belum ada info'), findsOneWidget);
    expect(catalog.calls.first, (page: 1, search: '', categorySlug: null, type: null, kecamatan: null));
  });

  testWidgets('the heart saves a place and the badge counts it', (tester) async {
    final wishlist = FakeWishlistService();
    await _pumpCatalog(tester, wishlist: wishlist);
    expect(find.textContaining('Favorit'), findsNothing);

    await tester.tap(find.byTooltip('Simpan ke wishlist').first);
    await tester.pumpAndSettle();

    expect(wishlist.added, [1]);
    expect(find.text('1 Favorit'), findsOneWidget);
    expect(find.byTooltip('Hapus dari wishlist'), findsOneWidget);
  });

  testWidgets('places saved earlier show a filled heart', (tester) async {
    await _pumpCatalog(tester, wishlist: FakeWishlistService(saved: {2}));

    expect(find.text('1 Favorit'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('a failed save puts the heart back and says so', (tester) async {
    final wishlist = FakeWishlistService()..failNext = true;
    await _pumpCatalog(tester, wishlist: wishlist);

    await tester.tap(find.byTooltip('Simpan ke wishlist').first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.text('Wishlist gagal diperbarui. Coba lagi.'), findsOneWidget);
  });

  testWidgets('a guest who taps the heart is sent to login', (tester) async {
    final wishlist = FakeWishlistService();
    await _pumpCatalog(tester, user: null, wishlist: wishlist);
    expect(find.text(_greeting), findsOneWidget);

    await tester.tap(find.byTooltip('Simpan ke wishlist').first);
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(wishlist.added, isEmpty);
  });

  testWidgets('signing in from the heart returns to the catalog', (tester) async {
    await _pumpCatalog(tester, user: null);

    await tester.tap(find.byTooltip('Simpan ke wishlist').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'budi@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();

    expect(find.text(_greeting), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsNothing);
  });

  testWidgets('scrolling to the end loads the next page', (tester) async {
    final catalog = FakePlaceService(total: 30);
    await _pumpCatalog(tester, catalog: catalog);

    await tester.scrollUntilVisible(find.text('Tempat 30'), 500, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(catalog.calls.map((call) => call.page), [1, 2]);
    expect(find.text('Tempat 30'), findsOneWidget);
  });

  testWidgets('scrolling down keeps the search field and chips pinned and fades the greeting', (tester) async {
    await _pumpCatalog(tester, catalog: FakePlaceService(total: 30));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(find.text('Semua').hitTestable(), findsOneWidget);
    final greeting = tester.widget<Opacity>(find.ancestor(of: find.text(_greeting), matching: find.byType(Opacity)).first);
    expect(greeting.opacity, 0);
  });

  testWidgets('a category chip and the hotel chip filter the grid', (tester) async {
    final catalog = FakePlaceService();
    await _pumpCatalog(tester, catalog: catalog);

    await _tapChip(tester, 'Pantai');
    expect(catalog.calls.last, (page: 1, search: '', categorySlug: 'pantai', type: null, kecamatan: null));

    await _tapChip(tester, 'Hotel');
    expect(catalog.calls.last, (page: 1, search: '', categorySlug: null, type: 'lodging', kecamatan: null));
  });

  testWidgets('the kecamatan sheet filters the grid and keeps the category chip', (tester) async {
    final catalog = FakePlaceService();
    await _pumpCatalog(tester, catalog: catalog);

    await _tapChip(tester, 'Pantai');
    await _tapChip(tester, 'Semua kecamatan');

    expect(find.text('Pilih kecamatan'), findsOneWidget);
    expect(find.text('10 tempat'), findsOneWidget);

    await tester.tap(find.text('Nongsa'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih kecamatan'), findsNothing);
    expect(catalog.calls.last, (page: 1, search: '', categorySlug: 'pantai', type: null, kecamatan: 'Nongsa'));
    expect(find.text('Pantai di Nongsa'), findsOneWidget);

    await _tapChip(tester, 'Semua');
    expect(catalog.calls.last.kecamatan, 'Nongsa');
    expect(find.text('Destinasi di Nongsa'), findsOneWidget);

    await _tapChip(tester, 'Nongsa');
    await tester.tap(find.text('Semua kecamatan').last);
    await tester.pumpAndSettle();
    expect(catalog.calls.last.kecamatan, isNull);
    expect(find.text('Destinasi di Batam'), findsOneWidget);
  });

  testWidgets('the bottom bar opens trip setup and says the other tabs are coming', (tester) async {
    await _pumpCatalog(tester);

    expect(find.text('Trip Saya'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Segera hadir'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Buat Trip'));
    await tester.pumpAndSettle();
    expect(find.text(_greeting), findsNothing);
  });

  testWidgets('a failed kecamatan list offers a retry', (tester) async {
    final catalog = FakePlaceService()..kecamatanFailWith = Exception('offline');
    await _pumpCatalog(tester, catalog: catalog);

    await tester.tap(find.text('Semua kecamatan'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar kecamatan gagal dimuat.'), findsOneWidget);

    catalog.kecamatanFailWith = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Batam Kota'), findsOneWidget);
  });

  testWidgets('search waits for the user to stop typing', (tester) async {
    final catalog = FakePlaceService();
    await _pumpCatalog(tester, catalog: catalog);

    await tester.enterText(find.byType(TextField), 'oca');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'ocarina');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(catalog.calls.where((call) => call.search.isNotEmpty).toList(), [
      (page: 1, search: 'ocarina', categorySlug: null, type: null, kecamatan: null),
    ]);
    expect(find.text('Hasil untuk "ocarina"'), findsOneWidget);
  });

  testWidgets('an empty catalog and a search without results explain themselves', (tester) async {
    final catalog = FakePlaceService(total: 0);
    await _pumpCatalog(tester, catalog: catalog);
    expect(find.text('Belum ada tempat di katalog.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada tempat yang cocok. Coba kata kunci atau kategori lain.'), findsOneWidget);
  });

  testWidgets('a failed first load offers a retry', (tester) async {
    final catalog = FakePlaceService()..failWith = Exception('down');
    await _pumpCatalog(tester, catalog: catalog);
    expect(find.text('Tempat 1'), findsNothing);

    catalog.failWith = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Tempat 1'), findsOneWidget);
  });

  group('cards fit without overflow', () {
    const screens = {'small phone': Size(320, 568), 'phone': Size(412, 917), 'tablet': Size(800, 1280)};

    for (final MapEntry(key: name, value: size) in screens.entries) {
      testWidgets('on a $name', (tester) async {
        await _pumpCatalog(tester, size: size, wishlist: FakeWishlistService(saved: {1}));

        expect(tester.takeException(), isNull);
        expect(find.text('Tempat 1'), findsOneWidget);
      });
    }

    testWidgets('in English with a large font', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpCatalog(tester, size: const Size(320, 568), locale: const Locale('en'));

      expect(tester.takeException(), isNull);
      expect(find.text('Hi, where to today?'), findsOneWidget);
    });
  });
}
