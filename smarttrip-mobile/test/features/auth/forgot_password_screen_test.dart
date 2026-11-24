import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/services/auth_service.dart';
import 'package:smarttrip_mobile/services/google_auth_service.dart';

import '../../helpers/test_doubles.dart';

Future<FakeAuthService> _openForgotPassword(WidgetTester tester, {FakeAuthService? auth}) async {
  tester.view.physicalSize = const Size(1200, 2800);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.localesTestValue = const [Locale('id')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final service = auth ?? FakeAuthService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        authServiceProvider.overrideWithValue(service),
        googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
      ],
      child: const SmartTripApp(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Lupa kata sandi?'));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('sends the reset link and returns to login', (tester) async {
    final auth = await _openForgotPassword(tester);
    expect(find.text('Lupa Kata Sandi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), ' dian@example.com ');
    await tester.tap(find.text('Kirim Tautan'));
    await tester.pumpAndSettle();

    expect(auth.forgotCalls, ['dian@example.com']);
    expect(find.text('Cek email kamu'), findsOneWidget);
    expect(find.textContaining('Jika email terdaftar'), findsOneWidget);

    await tester.tap(find.text('Masuk').last);
    await tester.pumpAndSettle();
    expect(find.text('Lupa Kata Sandi'), findsNothing);
    expect(find.text('Lupa kata sandi?'), findsOneWidget); // back on login
  });

  testWidgets('checks the email before calling the server', (tester) async {
    final auth = await _openForgotPassword(tester);

    await tester.enterText(find.byType(TextFormField), 'bukan-email');
    await tester.tap(find.text('Kirim Tautan'));
    await tester.pumpAndSettle();

    expect(auth.forgotCalls, isEmpty);
    expect(find.text('Lupa Kata Sandi'), findsOneWidget);
  });

  testWidgets('shows the server validation message on the email field', (tester) async {
    final auth = FakeAuthService()
      ..onForgotPassword = (_) => Future.error(const ValidationFailure('Email tidak valid.', {
            'email': ['Format email tidak valid.'],
          }));
    await _openForgotPassword(tester, auth: auth);

    await tester.enterText(find.byType(TextFormField), 'dian@example.com');
    await tester.tap(find.text('Kirim Tautan'));
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
  });
}
