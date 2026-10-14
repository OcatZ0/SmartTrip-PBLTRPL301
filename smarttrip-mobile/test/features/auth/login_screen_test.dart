import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/api_client.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/features/auth/data/auth_repository.dart';
import 'package:smarttrip_mobile/features/auth/data/google_auth_service.dart';
import 'package:smarttrip_mobile/features/auth/presentation/widgets/auth_layout.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

const _submit = 'Masuk';

Future<void> _pumpApp(
  WidgetTester tester, {
  required InMemoryTokenStorage tokenStorage,
  required FakeAuthRepository repository,
  FakeGoogleAuthService? google,
}) async {
  tester.view.physicalSize = const Size(1200, 2800);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = const [Locale('id')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(repository),
        googleAuthServiceProvider
            .overrideWithValue(google ?? FakeGoogleAuthService()),
        ...catalogOverrides(),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String email = 'budi@example.com',
  String password = 'rahasia123',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text(_submit));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFont);

  late InMemoryTokenStorage tokenStorage;
  late FakeAuthRepository repository;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    repository = FakeAuthRepository();
  });

  testWidgets('logged-out launch lands on the login screen', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text(_submit), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(find.text('Lanjut dengan Google'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Belum punya akun?'), findsOneWidget);
    expect(find.text('Daftar sekarang'), findsOneWidget);
  });

  testWidgets('empty submit shows required errors and calls nothing', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(repository.loginCalls, isEmpty);
  });

  testWidgets('malformed email is rejected before hitting the API', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillAndSubmit(tester, email: 'bukan-email');

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(repository.loginCalls, isEmpty);
  });

  testWidgets('successful login leaves the login screen', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillAndSubmit(tester, email: '  budi@example.com  ');

    expect(repository.loginCalls.single.email, 'budi@example.com');
    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsNothing);
  });

  testWidgets('"Ingat saya" off keeps the token out of persistent storage', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillAndSubmit(tester);

    expect(tokenStorage.lastSavePersisted, isFalse);
    expect(tokenStorage.stored, isNull);
    expect(await tokenStorage.read(), 'token-123');
  });

  testWidgets('"Ingat saya" on persists the token', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text('Ingat saya'));
    await tester.pump();
    await _fillAndSubmit(tester);

    expect(tokenStorage.lastSavePersisted, isTrue);
    expect(tokenStorage.stored, 'token-123');
  });

  testWidgets('server validation error is shown under the email field', (tester) async {
    repository.onLogin = (_, __) => throw const ValidationFailure(
          'The given data was invalid.',
          {'email': ['Email atau kata sandi salah.']},
        );
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillAndSubmit(tester);

    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
  });

  testWidgets('editing the form clears the server error', (tester) async {
    repository.onLogin = (_, __) => throw const ValidationFailure(
          'The given data was invalid.',
          {'email': ['Email atau kata sandi salah.']},
        );
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
    await _fillAndSubmit(tester);

    await tester.enterText(find.byType(TextFormField).at(1), 'baru');
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi salah.'), findsNothing);
  });

  testWidgets('a network failure is reported in a snackbar', (tester) async {
    repository.onLogin = (_, __) => throw const NetworkFailure();
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillAndSubmit(tester);

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi internetmu.'),
      findsOneWidget,
    );
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    EditableText passwordField() => tester.widget<EditableText>(
          find.descendant(
            of: find.byType(TextFormField).at(1),
            matching: find.byType(EditableText),
          ),
        );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('Google sign-in without configuration explains why', (tester) async {
    await _pumpApp(
      tester,
      tokenStorage: tokenStorage,
      repository: repository,
      google: FakeGoogleAuthService(configured: false),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Masuk dengan Google belum dikonfigurasi pada build ini.'),
      findsOneWidget,
    );
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
  });

  testWidgets('Google sign-in exchanges the id_token and logs in', (tester) async {
    String? receivedIdToken;
    repository.onGoogleLogin = (idToken) async {
      receivedIdToken = idToken;
      return testSession;
    };
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(receivedIdToken, 'google-id-token');
    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
  });

  testWidgets('dismissing the Google picker does nothing', (tester) async {
    await _pumpApp(
      tester,
      tokenStorage: tokenStorage,
      repository: repository,
      google: FakeGoogleAuthService(idToken: null),
    );

    await tester.tap(find.text('Lanjut dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('browse-without-login opens the public catalog', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
  });

  testWidgets('register and forgot-password links open their screens', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Buat Akun Baru'), findsOneWidget);

    // The register screen has no app bar; its "Masuk" link goes back.
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();
    expect(find.text('Segera hadir'), findsOneWidget);
  });

  testWidgets('a stored token restores the session straight into the app', (tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final storage = InMemoryTokenStorage(stored: 'abc');
    final adapter = FakeHttpClientAdapter(
      (_) => jsonResponse({
        'users_id': 7,
        'name': 'Budi',
        'email': 'budi@example.com',
        'role': 'user',
      }, 200),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              tokenStorage: storage,
              dio: Dio()..httpClientAdapter = adapter,
            ),
          ),
          ...catalogOverrides(),
        ],
        child: const SmartTripApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo, mau ke mana hari ini?'), findsOneWidget);
    expect(find.text('Selamat Datang Kembali'), findsNothing);
    expect(adapter.requests.single.path, '/user');
  });

  group('layout', () {
    // Logical sizes from a small phone up to a tablet, with whether the card
    // fits without scrolling.
    const screens = {
      'small phone 320x568': (Size(320, 568), false),
      'phone 360x800': (Size(360, 800), true),
      'medium phone 412x915': (Size(412, 915), true),
      'tablet 800x1280': (Size(800, 1280), true),
    };

    for (final entry in screens.entries) {
      final (size, fits) = entry.value;
      testWidgets('${entry.key}: the card keeps its full width${fits ? ' and nothing scrolls' : ''}', (tester) async {
        await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
        tester.view.physicalSize = size * 2;
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Never scaled: the screen width minus the 16px side padding, up to
        // 440 (the same width as the register card).
        final expectedWidth = (size.width - 32).clamp(0, 440).toDouble();
        expect(tester.getSize(find.byType(GlassCard)).width, expectedWidth);
        if (fits) {
          final scrollable = tester.state<ScrollableState>(
            find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable)).first,
          );
          expect(scrollable.position.maxScrollExtent, 0);
        }
      });
    }

    testWidgets('the English copy also fits a small phone', (tester) async {
      await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      tester.view.physicalSize = const Size(320, 568) * 2;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('the keyboard slides the page up so the focused field stays visible', (tester) async {
      await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
      final titleSize = tester.getSize(find.text('Selamat Datang Kembali'));
      final password = find.byType(TextFormField).at(1);
      const keyboardHeight = 330.0;

      await tester.tap(password);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight * 2);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      // The lift is computed from the previous layout, so settle once more.
      await tester.pump();

      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getSize(find.text('Selamat Datang Kembali')), titleSize);
      expect(tester.getRect(password).bottom, lessThanOrEqualTo(screenHeight - keyboardHeight));
    });

    testWidgets('"Ingat saya" sits at the left edge and "Lupa kata sandi?" at the right edge', (tester) async {
      await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
      final field = tester.getRect(find.byType(TextFormField).at(1));

      expect(tester.getRect(find.byType(Checkbox)).left, closeTo(field.left, 4));
      expect(tester.getRect(find.text('Lupa kata sandi?')).right, closeTo(field.right, 8));
    });
  });
}
