import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/core/router/app_router.dart';
import 'package:smarttrip_mobile/core/router/app_routes.dart';
import 'package:smarttrip_mobile/models/place.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

/// Opens place 2's detail as [testUser] (users_id 7) and scrolls to the
/// review button.
Future<void> _openDetail(WidgetTester tester, FakePlaceService catalog) async {
  tester.view.physicalSize = const Size(412, 917) * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = const [Locale('id')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      sessionControllerProvider.overrideWith(() => FakeSessionController(testUser)),
      authServiceProvider.overrideWithValue(FakeAuthService()),
      ...catalogOverrides(catalog: catalog),
    ],
    child: const SmartTripApp(),
  ));
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(routerProvider).push(AppRoutes.place(2));
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 300, scrollable: find.byType(Scrollable).last);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('writes a new review from the place detail', (tester) async {
    final catalog = FakePlaceService();
    await _openDetail(tester, catalog);
    await _tapButton(tester, 'Beri Ulasan');

    // No rating yet: nothing is sent.
    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih rating 1 sampai 5 bintang.'), findsOneWidget);
    expect(catalog.reviewCalls, isEmpty);

    await tester.tap(find.bySemanticsLabel('4 bintang'));
    await tester.enterText(find.byType(TextField), ' Pantainya bersih ');
    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();

    expect(catalog.reviewCalls, ['create 2 rating=4 comment=Pantainya bersih item=null']);
    expect(find.text('Ulasan terkirim. Terima kasih!'), findsOneWidget);
    expect(find.text('Kirim Ulasan'), findsNothing); // sheet closed
  });

  testWidgets('changes and deletes the user own review', (tester) async {
    final catalog = FakePlaceService()
      ..details[2] = placeDetail(2, reviews: [
        PlaceReview(placeReviewsId: 9, usersId: testUser.usersId, userName: 'Budi', rating: 3, comment: 'Lumayan'),
      ]);
    await _openDetail(tester, catalog);
    await _tapButton(tester, 'Ubah Ulasanmu');

    expect(find.text('Ubah Ulasan'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Lumayan'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 bintang'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(catalog.reviewCalls, ['update 9 rating=5 comment=Lumayan']);

    await _tapButton(tester, 'Ubah Ulasanmu');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(catalog.reviewCalls.last, 'delete 9');
    expect(find.text('Ulasan dihapus.'), findsOneWidget);
  });

  testWidgets('shows the server message when the place was already reviewed', (tester) async {
    final catalog = FakePlaceService()
      ..reviewFailWith = const ValidationFailure(
        'Kamu sudah pernah memberi ulasan untuk tempat ini. Ubah ulasan yang sudah ada.',
        {'place_reviews_id': ['5']},
      );
    await _openDetail(tester, catalog);
    await _tapButton(tester, 'Beri Ulasan');

    await tester.tap(find.bySemanticsLabel('5 bintang'));
    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();

    expect(find.text('Kamu sudah pernah memberi ulasan untuk tempat ini. Ubah ulasan yang sudah ada.'), findsOneWidget);
    expect(find.text('Kirim Ulasan'), findsOneWidget); // sheet stays open
  });

}
