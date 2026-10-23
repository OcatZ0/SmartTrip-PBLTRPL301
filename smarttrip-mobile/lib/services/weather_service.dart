import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather.dart';
import 'trip_service.dart';

/// Daily forecast from Open-Meteo, called straight from the app: it needs no
/// API key, so there is nothing to keep on the server (design spec, F025).
class WeatherService {
  WeatherService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.open-meteo.com/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// The forecast only shows once the trip is this close; further out it is
  /// not reliable enough to plan around.
  static const window = Duration(days: 7);

  /// Open-Meteo forecasts at most this many days ahead.
  static const _forecastDays = 16;

  final Dio _dio;

  /// Whether a trip from [start] to [end] has a day inside the window today.
  static bool inWindow(DateTime start, DateTime end, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return !DateUtils.dateOnly(end).isBefore(today) && !DateUtils.dateOnly(start).isAfter(today.add(window));
  }

  Future<Map<DateTime, DayForecast>> fetch({
    required double lat,
    required double lng,
    required DateTime start,
    required DateTime end,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final from = DateUtils.dateOnly(start).isBefore(today) ? today : DateUtils.dateOnly(start);
    final last = today.add(const Duration(days: _forecastDays - 1));
    final to = DateUtils.dateOnly(end).isAfter(last) ? last : DateUtils.dateOnly(end);
    if (to.isBefore(from)) return const {};

    String day(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.get<Map<String, dynamic>>('/forecast', queryParameters: {
      'latitude': lat,
      'longitude': lng,
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'Asia/Jakarta',
      'start_date': day(from),
      'end_date': day(to),
    });

    final daily = response.data?['daily'] as Map<String, dynamic>? ?? const {};
    final dates = (daily['time'] as List? ?? const []).cast<String>();
    final codes = daily['weather_code'] as List? ?? const [];
    final maxima = daily['temperature_2m_max'] as List? ?? const [];
    final minima = daily['temperature_2m_min'] as List? ?? const [];
    final chances = daily['precipitation_probability_max'] as List? ?? const [];

    return {
      for (var i = 0; i < dates.length; i++)
        DateTime.parse(dates[i]): DayForecast(
          date: DateTime.parse(dates[i]),
          weatherCode: (codes.elementAtOrNull(i) as num?)?.toInt() ?? 0,
          maxTemperature: (maxima.elementAtOrNull(i) as num?)?.toDouble() ?? 0,
          minTemperature: (minima.elementAtOrNull(i) as num?)?.toDouble() ?? 0,
          rainChance: (chances.elementAtOrNull(i) as num?)?.toInt() ?? 0,
        ),
    };
  }
}

final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

/// Batam city centre, for a trip without a hotel pin yet.
const _batamCentre = (lat: 1.1301, lng: 104.0529);

/// The trip's forecast by date, or null when the trip is not within
/// [WeatherService.window] yet or the forecast cannot be loaded: a missing
/// forecast never blocks the itinerary.
final tripForecastProvider = FutureProvider.autoDispose.family<Map<DateTime, DayForecast>?, int>((ref, tripsId) async {
  final place = await ref.watch(
    tripDetailProvider(tripsId).selectAsync(
      (trip) => (
        start: trip.startDate,
        end: trip.dateOfDay(trip.numDays),
        lat: trip.hotel?.lat ?? _batamCentre.lat,
        lng: trip.hotel?.lng ?? _batamCentre.lng,
      ),
    ),
  );
  if (!WeatherService.inWindow(place.start, place.end)) return null;

  try {
    return await ref.watch(weatherServiceProvider).fetch(lat: place.lat, lng: place.lng, start: place.start, end: place.end);
  } catch (_) {
    return null;
  }
});
