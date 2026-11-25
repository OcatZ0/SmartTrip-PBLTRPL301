import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import 'polyline_codec.dart';

/// The server's city speed and detour factor (ItineraryGenerator), so the
/// times in the PDF agree with the time budget the generator planned with.
const _averageSpeedKmh = 27.5;
const _detourFactor = 1.35;

/// Visit length for a stop without one, the server's default too.
const _defaultVisitMinutes = 60;

/// One leg of a day: the road from the previous point to the next one.
class PlannedLeg {
  const PlannedLeg({required this.path, required this.km, required this.minutes, required this.isRoad});

  /// The road from OpenRouteService, or a straight line when it has none.
  final List<LatLng> path;
  final double km;
  final int minutes;

  /// False when [path] is a straight line because the leg has no route.
  final bool isRoad;

  static PlannedLeg between(LatLng from, LatLng to, String? polyline) {
    final road = polyline == null || polyline.isEmpty ? const <LatLng>[] : decodePolyline(polyline);
    if (road.length >= 2) {
      var km = 0.0;
      for (var i = 1; i < road.length; i++) {
        km += haversineKm(road[i - 1].latitude, road[i - 1].longitude, road[i].latitude, road[i].longitude);
      }
      return PlannedLeg(path: road, km: km, minutes: _minutesFor(km), isRoad: true);
    }

    final km = haversineKm(from.latitude, from.longitude, to.latitude, to.longitude) * _detourFactor;
    return PlannedLeg(path: [from, to], km: km, minutes: _minutesFor(km), isRoad: false);
  }

  static int _minutesFor(double km) => (km / _averageSpeedKmh * 60).round();
}

class PlannedStop {
  const PlannedStop({
    required this.number,
    required this.item,
    required this.leg,
    required this.arriveMinute,
    required this.departMinute,
  });

  /// 1-based order within the day, the number on the map pin.
  final int number;
  final ItineraryItem item;

  /// The way here from the previous point; null for a first stop on a day
  /// without a start point.
  final PlannedLeg? leg;

  /// Minutes after midnight.
  final int arriveMinute;
  final int departMinute;

  TripPlace? get place => item.place;
  LatLng get point => LatLng(place?.lat ?? 0, place?.lng ?? 0);
  int get visitMinutes => place?.estimatedVisitMinutes ?? _defaultVisitMinutes;
  int get costIdr => place?.estimatedCostIdr ?? 0;
}

class PlannedDay {
  const PlannedDay({
    required this.day,
    required this.date,
    required this.stops,
    required this.startMinute,
    required this.legToEnd,
    required this.endMinute,
    required this.dayEndMinute,
  });

  final ItineraryDay day;
  final DateTime date;
  final List<PlannedStop> stops;

  /// When the day starts (the trip's daily start time).
  final int startMinute;

  /// From the last stop back to where the day ends; null without stops or
  /// without an end point.
  final PlannedLeg? legToEnd;

  /// Back at the end point (or leaving the last stop without one).
  final int endMinute;

  /// The trip's daily end time.
  final int dayEndMinute;

  TripHotel? get start => day.start;
  TripHotel? get end => day.end ?? day.start;

  Iterable<PlannedLeg> get legs => [...stops.map((stop) => stop.leg).whereType<PlannedLeg>(), ?legToEnd];
  double get km => legs.fold(0, (sum, leg) => sum + leg.km);
  int get travelMinutes => legs.fold(0, (sum, leg) => sum + leg.minutes);
  int get visitMinutes => stops.fold(0, (sum, stop) => sum + stop.visitMinutes);
  int get costIdr => stops.fold(0, (sum, stop) => sum + stop.costIdr);
  int get outdoorCount => stops.where((stop) => stop.place?.isOutdoor ?? false).length;

  /// The schedule runs past the trip's daily end time.
  bool get overruns => stops.isNotEmpty && endMinute > dayEndMinute;
}

/// The itinerary as a timed schedule: where each leg goes, how long it takes
/// and when each stop is reached, all computed on the device from the trip
/// the screen already loaded.
class ItineraryPdfPlan {
  ItineraryPdfPlan._(this.trip, this.days);

  factory ItineraryPdfPlan.of(Trip trip) {
    final startMinute = minutesOf(trip.dailyStartTime);
    final dayEndMinute = minutesOf(trip.dailyEndTime);

    final days = [
      for (final day in trip.days) _planDay(trip, day, startMinute, dayEndMinute),
    ];
    return ItineraryPdfPlan._(trip, days);
  }

  final Trip trip;
  final List<PlannedDay> days;

  Iterable<PlannedStop> get stops => days.expand((day) => day.stops);
  double get km => days.fold(0, (sum, day) => sum + day.km);
  int get travelMinutes => days.fold(0, (sum, day) => sum + day.travelMinutes);
  int get costIdr => days.fold(0, (sum, day) => sum + day.costIdr);

  int countWhere(bool Function(PlannedStop stop) test) => stops.where(test).length;

  /// "08:00" or "08:00:00" to minutes after midnight.
  static int minutesOf(String time) {
    final parts = time.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  static String clock(int minutes) {
    final wrapped = minutes % (24 * 60);
    return '${(wrapped ~/ 60).toString().padLeft(2, '0')}:${(wrapped % 60).toString().padLeft(2, '0')}';
  }

  static PlannedDay _planDay(Trip trip, ItineraryDay day, int startMinute, int dayEndMinute) {
    final stops = <PlannedStop>[];
    var clock = startMinute;
    LatLng? previous = day.start == null ? null : LatLng(day.start!.lat, day.start!.lng);

    for (final (index, item) in day.items.indexed) {
      final here = LatLng(item.place?.lat ?? 0, item.place?.lng ?? 0);
      final leg = previous == null ? null : PlannedLeg.between(previous, here, item.polylineToHere);
      final arrive = clock + (leg?.minutes ?? 0);
      final depart = arrive + (item.place?.estimatedVisitMinutes ?? _defaultVisitMinutes);
      stops.add(PlannedStop(number: index + 1, item: item, leg: leg, arriveMinute: arrive, departMinute: depart));
      clock = depart;
      previous = here;
    }

    final end = day.end ?? day.start;
    final legToEnd = stops.isEmpty || end == null || previous == null
        ? null
        : PlannedLeg.between(previous, LatLng(end.lat, end.lng), day.polylineToEnd);

    return PlannedDay(
      day: day,
      date: trip.dateOfDay(day.dayNumber),
      stops: stops,
      startMinute: startMinute,
      legToEnd: legToEnd,
      endMinute: clock + (legToEnd?.minutes ?? 0),
      dayEndMinute: dayEndMinute,
    );
  }
}
