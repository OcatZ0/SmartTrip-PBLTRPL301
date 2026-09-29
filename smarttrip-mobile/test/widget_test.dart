import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarttrip_mobile/app.dart';

void main() {
  testWidgets('App boots to the catalog screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartTripApp()));
    await tester.pumpAndSettle();

    expect(find.text('SmartTrip Batam'), findsOneWidget);
  });
}
