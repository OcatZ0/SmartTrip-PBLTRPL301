import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/app.dart';
import 'package:smarttrip_mobile/core/api/providers.dart';

import 'helpers/test_doubles.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.localeTestValue = const Locale('id');
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const SmartTripApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
  });
}
