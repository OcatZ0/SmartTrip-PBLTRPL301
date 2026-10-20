import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/auth_user.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/router/app_router.dart';
import 'package:smarttrip_mobile/core/router/app_routes.dart';
import 'package:smarttrip_mobile/features/auth/data/auth_repository.dart';
import 'package:smarttrip_mobile/features/catalog/data/catalog_models.dart';
import 'package:smarttrip_mobile/features/trip/data/trip_models.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

const _detailTitle = 'Detail Destinasi';

final _trips = [
  TripSummary(tripsId: 11, title: 'Liburan Batam', numDays: 3, startDate: DateTime(2026, 10, 20)),
  TripSummary(tripsId: 12, title: 'Trip Kantor', numDays: 2, startDate: DateTime(2026, 11, 2), hasItinerary: true),
];

/// Opens the catalog, then the detail of "Tempat 2" (no rating, so it is
/// in the plain list rather than the featured row), by tapping its card or
/// through the router.
Future<void> _openDetail(
  WidgetTester tester, {
  AuthUser? user = testUser,
  FakeCatalogRepository? catalog,
  FakeUserWishlistRepository? wishlist,
  FakeTripRepository? trips,
  Size size = const Size(412, 917),
  Locale locale = const Locale('id'),
  bool fromCatalogCard = false,
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
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ...catalogOverrides(catalog: catalog, wishlist: wishlist, trips: trips),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();

  if (user == null) {
    await tester.tap(find.text(locale.languageCode == 'en' ? 'Skip' : 'Lewati'));
    await tester.pumpAndSettle();
  }

  if (fromCatalogCard) {
    await tester.tap(find.text('Tempat 2').first);
  } else {
    // Straight to the route: on short screens the card can sit under the
    // floating "Buat Trip" button, which is the catalog's business.
    ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    ).read(routerProvider).push(AppRoutes.place(2));
  }
  await tester.pumpAndSettle();
}

Finder _inDetail(Finder finder) => find.descendant(of: find.byType(Scaffold).last, matching: finder);

void main() {
  setUpAll(loadAppFont);

  testWidgets('a catalog card opens the detail with facts, description, location and reviews', (tester) async {
    final catalog = FakeCatalogRepository();
    await _openDetail(tester, catalog: catalog, fromCatalogCard: true);

    expect(catalog.detailCalls, [2]);
    expect(find.text(_detailTitle), findsOneWidget);
    expect(_inDetail(find.text('Tempat 2')), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('±1,5 jam'), findsOneWidget);
    // Today's hours in the facts, and the week collapsed to one row.
    expect(find.text('Jam buka hari ini'), findsOneWidget);
    expect(find.text('Tiket Masuk'), findsOneWidget);
    expect(find.text('Luar ruangan'), findsOneWidget);
    expect(find.text('Jam Operasional'), findsOneWidget);
    expect(find.text('Setiap hari'), findsOneWidget);
    expect(find.text('08.00–21.00'), findsNWidgets(2));
    expect(find.text('Pantai berpasir putih dengan bianglala di tepi laut.'), findsOneWidget);
    expect(find.text('Jl. Hang Lekiu, Batam Centre'), findsOneWidget);
    expect(find.text('Buka Maps'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Sarah Wijaya'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Ulasan'), findsOneWidget);
    expect(find.text('Dian Pratama'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);
    // Only two reviews: no "Lihat semua".
    expect(find.text('Lihat semua'), findsNothing);
  });

  testWidgets('a long description is clamped with a read-more toggle', (tester) async {
    final catalog = FakeCatalogRepository();
    catalog.details[2] = placeDetail(2, description: List.filled(40, 'Pemandangan laut yang indah.').join(' '));
    await _openDetail(tester, catalog: catalog);

    await tester.tap(find.text('Baca selengkapnya'));
    await tester.pumpAndSettle();

    expect(find.text('Tampilkan lebih sedikit'), findsOneWidget);
  });

  testWidgets('more than three reviews are folded behind "Lihat semua"', (tester) async {
    final catalog = FakeCatalogRepository();
    catalog.details[2] = placeDetail(
      2,
      reviews: [for (var i = 1; i <= 5; i++) PlaceReview(placeReviewsId: i, userName: 'Pengulas $i', rating: 5)],
    );
    await _openDetail(tester, catalog: catalog);

    await tester.scrollUntilVisible(find.text('Lihat semua'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Pengulas 4'), findsNothing);

    await tester.tap(find.text('Lihat semua'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pengulas 5'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Pengulas 5'), findsOneWidget);
  });

  testWidgets('the heart in the bottom bar saves the place', (tester) async {
    final wishlist = FakeUserWishlistRepository();
    await _openDetail(tester, wishlist: wishlist);

    await tester.tap(_inDetail(find.byTooltip('Simpan ke wishlist')));
    await tester.pumpAndSettle();

    expect(wishlist.added, [2]);
    expect(_inDetail(find.byTooltip('Hapus dari wishlist')), findsOneWidget);
  });

  testWidgets('adding to a trip lists the user trips and adds to the picked one', (tester) async {
    final trips = FakeTripRepository(trips: _trips);
    await _openDetail(tester, trips: trips);

    await tester.tap(find.text('Tambah ke Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah ke trip mana?'), findsOneWidget);
    expect(find.text('Trip Kantor'), findsOneWidget);

    await tester.tap(find.text('Liburan Batam'));
    await tester.pumpAndSettle();

    expect(trips.added, [(tripsId: 11, placesId: 2)]);
    expect(find.text('Ditambahkan ke wishlist Liburan Batam.'), findsOneWidget);
  });

  testWidgets('adding to a generated trip asks to generate again, a duplicate says so', (tester) async {
    final trips = FakeTripRepository(trips: _trips);
    await _openDetail(tester, trips: trips);

    await tester.tap(find.text('Tambah ke Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trip Kantor'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ditambahkan ke wishlist Trip Kantor. Buat ulang itinerary-nya supaya tempat ini ikut dihitung.'),
      findsOneWidget,
    );

    trips.alreadyIn.add(11);
    await tester.tap(find.text('Tambah ke Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liburan Batam'));
    await tester.pumpAndSettle();
    expect(find.text('Sudah ada di wishlist Liburan Batam.'), findsOneWidget);
  });

  testWidgets('without trips the sheet offers to create one', (tester) async {
    await _openDetail(tester, trips: FakeTripRepository());

    await tester.tap(find.text('Tambah ke Trip'));
    await tester.pumpAndSettle();

    expect(find.text('Kamu belum punya trip. Buat dulu, lalu tempat ini bisa ditambahkan.'), findsOneWidget);
    expect(find.text('Buat trip baru'), findsOneWidget);
  });

  testWidgets('a guest who taps the heart or "Tambah ke Trip" is sent to login', (tester) async {
    final wishlist = FakeUserWishlistRepository();
    await _openDetail(tester, user: null, wishlist: wishlist);
    expect(find.text(_detailTitle), findsOneWidget);

    await tester.tap(find.text('Tambah ke Trip'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(wishlist.added, isEmpty);
  });

  testWidgets('several photos are a swipeable carousel without a credit', (tester) async {
    final catalog = FakeCatalogRepository();
    final base = placeDetail(2);
    catalog.details[2] = PlaceDetail(
      summary: base.summary,
      lat: base.lat,
      lng: base.lng,
      photos: const [
        PlacePhoto(url: 'https://example.test/a.jpg'),
        PlacePhoto(url: 'https://example.test/b.jpg'),
      ],
    );
    await _openDetail(tester, catalog: catalog);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Foto:'), findsNothing);
  });

  testWidgets('a hotel has no "Tambah ke Trip", hotels are picked in step C4', (tester) async {
    final catalog = FakeCatalogRepository();
    catalog.details[2] = placeDetail(2, type: 'lodging');
    await _openDetail(tester, catalog: catalog);

    expect(find.text('Tambah ke Trip'), findsNothing);
    expect(_inDetail(find.byTooltip('Simpan ke wishlist')), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    final catalog = FakeCatalogRepository()..detailFailWith = Exception('down');
    await _openDetail(tester, catalog: catalog);
    expect(find.textContaining('Detail tempat gagal dimuat.'), findsOneWidget);

    catalog.detailFailWith = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(_inDetail(find.text('Tempat 2')), findsOneWidget);
  });

  group('fits without overflow', () {
    for (final (name, size) in [('small phone', const Size(320, 568)), ('tablet', const Size(800, 1280))]) {
      testWidgets('on a $name', (tester) async {
        await _openDetail(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text(_detailTitle), findsOneWidget);
      });
    }

    testWidgets('in English with a large font', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _openDetail(tester, size: const Size(320, 568), locale: const Locale('en'));

      expect(tester.takeException(), isNull);
      expect(find.text('Place Details'), findsOneWidget);
      expect(find.text('±1.5 h'), findsOneWidget);
    });
  });

  test('parses PlaceDetailResource, preferring the description in the UI language', () {
    final detail = PlaceDetail.fromJson({
      'places_id': 7,
      'name': 'Pantai Melur',
      'type': 'attraction',
      'lat': 1.05,
      'lng': 104.1,
      'photos': [
        {'url': 'a.jpg'},
      ],
      'description_id': 'Deskripsi',
      'description_en': ' ',
      'opening_hours': {
        'weekday_descriptions': ['Senin: 08.00–18.00', 'Minggu: Tutup'],
      },
      'estimated_visit_minutes': 45,
      'review_count_in_app': 1,
      'reviews': [
        {
          'place_reviews_id': 3,
          'users_id': 9,
          'user_name': 'Budi',
          'rating': 4,
          'comment': 'Bagus',
          'created_at': '2026-10-12T03:00:00.000000Z',
        },
      ],
    });

    expect(detail.description('id'), 'Deskripsi');
    // A blank English text falls back to Indonesian.
    expect(detail.description('en'), 'Deskripsi');
    expect([for (final day in detail.openingHours) (day.weekday, day.hours)], [(1, '08.00–18.00'), (7, 'Tutup')]);
    expect(detail.openingDay(7)?.isClosed, isTrue);
    expect(detail.openingDay(3), isNull);
    expect(detail.openingDay(1)?.isOpenAt(DateTime(2026, 10, 19, 17, 59)), isTrue);
    expect(detail.openingDay(1)?.isOpenAt(DateTime(2026, 10, 19, 18)), isFalse);
    expect(detail.heroPhotoUrl, endsWith('a.jpg'));
    expect(detail.summary.reviewCount, 1);
    expect(detail.reviews.single.userName, 'Budi');
  });
}
