import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/notifications/local_notification_service.dart';
import 'package:smarttrip_mobile/core/theme/app_theme.dart';
import 'package:smarttrip_mobile/l10n/app_localizations.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/models/weather.dart';
import 'package:smarttrip_mobile/screens/trip/itinerary_screen.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';
import 'package:smarttrip_mobile/services/weather_service.dart';

import '../../helpers/test_doubles.dart';
import 'trip_models_test.dart' show tripJson;

class _FixedTrip extends TripDetailController {
  @override
  Future<Trip> build(int tripsId) async => Trip.fromJson(tripJson());
}

class _QuietNotifications extends LocalNotificationService {
  final reminders = <int>[];
  final days = <({DateTime at, String title, String body})>[];

  @override
  Future<void> scheduleDayReminders({
    required int tripsId,
    required List<({DateTime at, String title, String body})> days,
    required String channelName,
    required String channelDescription,
  }) async {
    this.days.addAll(days);
  }

  @override
  Future<void> scheduleWeatherReminder({
    required int tripsId,
    required DateTime startDate,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    reminders.add(tripsId);
  }
}

DayForecast _forecast(DateTime date, {required int code, required int rain}) {
  return DayForecast(date: date, weatherCode: code, maxTemperature: 31.4, minTemperature: 24.6, rainChance: rain);
}

Future<_QuietNotifications> _openItinerary(WidgetTester tester, DayForecast? dayOne) async {
  tester.view.physicalSize = const Size(412, 1200) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final notifications = _QuietNotifications();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripDetailProvider.overrideWith(_FixedTrip.new),
        tripForecastProvider.overrideWith(
          (ref, tripsId) async => dayOne == null ? null : {DateTime(2026, 10, 20): dayOne},
        ),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ItineraryScreen(tripsId: 5),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifications;
}

void main() {
  setUpAll(loadAppFont);

  test('reads the daily Open-Meteo forecast and calls a rainy day rainy', () async {
    final adapter = FakeHttpClientAdapter(
      (_) => jsonResponse({
        'daily': {
          'time': ['2026-10-20', '2026-10-21'],
          'weather_code': [61, 1],
          'temperature_2m_max': [30.2, 32.0],
          'temperature_2m_min': [24.1, 25.0],
          'precipitation_probability_max': [80, 10],
        },
      }, 200),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.open-meteo.com/v1'))..httpClientAdapter = adapter;

    final forecast = await WeatherService(dio: dio).fetch(
      lat: 1.13,
      lng: 104.05,
      start: DateUtils.dateOnly(DateTime.now()),
      end: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)),
    );

    expect(adapter.requests.single.queryParameters['daily'], contains('precipitation_probability_max'));
    expect(forecast[DateTime(2026, 10, 20)]?.isRainy, isTrue);
    expect(forecast[DateTime(2026, 10, 21)]?.isRainy, isFalse);
    expect(forecast[DateTime(2026, 10, 21)]?.maxTemperature, 32.0);
  });

  test('the forecast only shows from 7 days before the trip until its last day', () {
    final today = DateTime(2026, 10, 20);
    expect(WeatherService.inWindow(DateTime(2026, 10, 27), DateTime(2026, 10, 29), now: today), isTrue);
    expect(WeatherService.inWindow(DateTime(2026, 10, 28), DateTime(2026, 10, 29), now: today), isFalse);
    expect(WeatherService.inWindow(DateTime(2026, 10, 15), DateTime(2026, 10, 19), now: today), isFalse);
    expect(WeatherService.inWindow(DateTime(2026, 10, 18), DateTime(2026, 10, 20), now: today), isTrue);
  });

  testWidgets('a rainy day warns about its outdoor stop and badges it for a swap', (tester) async {
    final notifications = await _openItinerary(tester, _forecast(DateTime(2026, 10, 20), code: 63, rain: 85));

    expect(find.text('Hujan'), findsOneWidget);
    expect(find.text('25-31°C · peluang hujan 85%'), findsOneWidget);
    expect(find.textContaining('ada 1 tempat luar ruangan'), findsOneWidget);
    expect(find.text('Ganti tempat luar ruangan'), findsOneWidget);
    expect(find.text('Hujan, ganti?'), findsOneWidget);
    expect(notifications.reminders, [5]);
    // Day 1 has stops, day 2 has none; 09:00 start, reminded half an hour before.
    expect(notifications.days.single.at, DateTime(2026, 10, 20, 8, 30));
    expect(notifications.days.single.title, 'Trip Batam: hari ke-1');
    expect(notifications.days.single.body, '2 tempat menunggu hari ini, mulai dari Rumah Saudara pukul 09:00.');
  });

  testWidgets('a dry day shows the forecast without a warning', (tester) async {
    await _openItinerary(tester, _forecast(DateTime(2026, 10, 20), code: 1, rain: 10));

    expect(find.text('Berawan'), findsOneWidget);
    expect(find.text('Hujan, ganti?'), findsNothing);
    expect(find.text('Ganti tempat luar ruangan'), findsNothing);
  });

  testWidgets('no forecast yet leaves the itinerary as it was', (tester) async {
    await _openItinerary(tester, null);

    expect(find.text('Pantai Melur'), findsOneWidget);
    expect(find.textContaining('peluang hujan'), findsNothing);
  });
}
