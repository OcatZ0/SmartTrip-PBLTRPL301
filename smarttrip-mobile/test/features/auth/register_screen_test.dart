import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/features/auth/data/auth_repository.dart';
import 'package:smarttrip_mobile/features/auth/data/google_auth_service.dart';
import 'package:smarttrip_mobile/features/auth/presentation/widgets/auth_layout.dart';

import '../../helpers/test_doubles.dart';

const _submit = 'Daftar Akun';

Future<void> _pumpApp(
  WidgetTester tester, {
  required InMemoryTokenStorage tokenStorage,
  required FakeAuthRepository repository,
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
        googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();

  // Navigate to Register screen from Login screen
  await tester.tap(find.text('Daftar sekarang'));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String name = 'Dian Pratama',
  String email = 'dian@example.com',
  String password = 'Password123!',
  String confirmPassword = 'Password123!',
  bool agreeTerms = true,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirmPassword);

  if (agreeTerms) {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadAppFont);

  late InMemoryTokenStorage tokenStorage;
  late FakeAuthRepository repository;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    repository = FakeAuthRepository();
  });

  testWidgets('renders register screen with all Figma elements', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text('Daftar untuk mulai merencanakan tripmu di Batam.'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    // Shown twice: the requirement label above the field and its hint.
    expect(find.text('Minimal 8 karakter'), findsNWidgets(2));
    expect(find.text('Kekuatan Sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text(_submit), findsOneWidget);
    expect(find.text('Sudah punya akun?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('empty submit shows required validation errors', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Anda harus menyetujui Syarat & Ketentuan'), findsOneWidget);
    expect(repository.registerCalls, isEmpty);
  });

  testWidgets('malformed email is rejected before hitting API', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(tester, email: 'bukan-email');
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(repository.registerCalls, isEmpty);
  });

  testWidgets('password shorter than 8 chars is rejected', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(
      tester,
      password: 'short',
      confirmPassword: 'short',
    );
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);
    expect(repository.registerCalls, isEmpty);
  });

  testWidgets('mismatched passwords show confirmation error', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(
      tester,
      password: 'Password123!',
      confirmPassword: 'DifferentPassword123!',
    );
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
    expect(repository.registerCalls, isEmpty);
  });

  testWidgets('unaccepted terms displays terms error', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(tester, agreeTerms: false);
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Anda harus menyetujui Syarat & Ketentuan'), findsOneWidget);
    expect(repository.registerCalls, isEmpty);
  });

  testWidgets('successful registration calls API and shows success dialog', (tester) async {
    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(tester);
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(repository.registerCalls, hasLength(1));
    expect(repository.registerCalls.first.name, 'Dian Pratama');
    expect(repository.registerCalls.first.email, 'dian@example.com');
    expect(repository.registerCalls.first.password, 'Password123!');
    expect(repository.registerCalls.first.passwordConfirmation, 'Password123!');

    // Success dialog appears
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Silakan cek email Anda untuk verifikasi akun.'), findsOneWidget);

    // Dismissing success dialog returns to login screen
    await tester.tap(find.widgetWithText(TextButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
  });

  testWidgets('server validation errors display on fields', (tester) async {
    repository.onRegister = (name, email, password, confirmation) {
      throw const ValidationFailure('Data tidak valid.', {
        'email': ['Email ini sudah terdaftar. Silakan login.'],
      });
    };

    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(tester);
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text('Email ini sudah terdaftar. Silakan login.'), findsOneWidget);
  });

  testWidgets('network failure shows snackbar', (tester) async {
    repository.onRegister = (name, email, password, confirmation) {
      throw const NetworkFailure();
    };

    await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);

    await _fillForm(tester);
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi internetmu.'),
      findsOneWidget,
    );
  });

  group('layout', () {
    const screens = {
      'small phone 320x568': Size(320, 568),
      'medium phone 412x915': Size(412, 915),
      'tablet 800x1280': Size(800, 1280),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key}: the card keeps the login card width and the footer is reachable', (tester) async {
        await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
        tester.view.physicalSize = entry.value * 2;
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Never scaled, so it matches the login card; a tall card scrolls.
        final expectedWidth = (entry.value.width - 32).clamp(0, 440).toDouble();
        expect(tester.getSize(find.byType(GlassCard)).width, expectedWidth);
        // The footer sits under the card and scrolls with it.
        await tester.ensureVisible(find.text('Sudah punya akun?'));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.text('Sudah punya akun?')).bottom, lessThanOrEqualTo(entry.value.height));
      });
    }

    testWidgets('focusing the last field lifts it above the keyboard', (tester) async {
      await _pumpApp(tester, tokenStorage: tokenStorage, repository: repository);
      final confirm = find.byType(TextFormField).at(3);
      const keyboardHeight = 330.0;

      await tester.tap(confirm);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight * 2);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.pump();

      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getRect(confirm).bottom, lessThanOrEqualTo(screenHeight - keyboardHeight));
    });
  });
}
