import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/screens/trip/widgets/invite_viewer_sheet.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

const _budi = TripViewer(usersId: 2, name: 'Budi', email: 'budi@mail.com');
const _sari = TripViewer(usersId: 3, name: 'Sari', email: 'sari@mail.com');

class _ViewerTripService extends FakeTripService {
  final viewers = <TripViewer>[_budi];
  final removed = <int>[];
  bool linkDisabled = false;

  @override
  Future<List<TripViewer>> fetchViewers(int tripsId) async => List.of(viewers);

  @override
  Future<TripViewer> inviteViewer(int tripsId, String email) async {
    if (email == 'sari@mail.com') return _sari;
    throw const ValidationFailure('Tidak ada user terdaftar dengan email ini.', {
      'email': ['Tidak ada user terdaftar dengan email ini.'],
    });
  }

  @override
  Future<void> removeViewer(int tripsId, int usersId) async => removed.add(usersId);

  @override
  Future<String> createViewerInviteLink(int tripsId) async => 'tok123';

  @override
  Future<void> disableViewerInviteLink(int tripsId) async => linkDisabled = true;
}

Future<_ViewerTripService> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1600) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final trips = _ViewerTripService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tripServiceProvider.overrideWithValue(trips)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: InviteViewerSheet(tripsId: 5)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return trips;
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('lists current viewers and adds a registered user by email', (tester) async {
    await _open(tester);
    expect(find.text('Budi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sari@mail.com');
    await tester.tap(find.text('Undang sebagai Viewer'));
    await tester.pumpAndSettle();

    expect(find.text('Sari'), findsOneWidget);
    expect(find.text('Sari sekarang dapat melihat trip ini'), findsOneWidget);
  });

  testWidgets('shows the API reason when the email is not registered', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'orang@lain.com');
    await tester.tap(find.text('Undang sebagai Viewer'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada user terdaftar dengan email ini.'), findsOneWidget);
  });

  testWidgets('rejects a malformed email without calling the API', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'bukan-email');
    await tester.tap(find.text('Undang sebagai Viewer'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
  });

  testWidgets('revokes a viewer', (tester) async {
    final trips = await _open(tester);

    await tester.tap(find.byTooltip('Cabut akses'));
    await tester.pumpAndSettle();

    expect(trips.removed, [2]);
    expect(find.text('Budi'), findsNothing);
    expect(find.text('Belum ada viewer.'), findsOneWidget);
  });

  testWidgets('creates and then disables the invite link', (tester) async {
    final trips = await _open(tester);

    await tester.tap(find.text('Buat tautan undangan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('/undangan/tok123'), findsOneWidget);

    await tester.tap(find.text('Matikan tautan'));
    await tester.pumpAndSettle();
    expect(trips.linkDisabled, isTrue);
    expect(find.text('Buat tautan undangan'), findsOneWidget);
  });
}
