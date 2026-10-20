import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geofence_service/geofence_service.dart' hide LocationPermission;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/local_notification_service.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import 'trip_service.dart';
import 'visit_sync.dart';

/// A geofence entry that marked a stop as visited.
class VisitArrival {
  const VisitArrival({required this.tripsId, required this.itineraryItemsId, this.visitedAt});

  final int tripsId;
  final int itineraryItemsId;
  final DateTime? visitedAt;
}

enum TrackingStartResult { started, permissionDenied, locationServiceOff }

/// Automatic visit detection for the active day (F013) and the arrival
/// notification (F012), design spec Section 8.
///
/// Only the stops of the day started with "Mulai Hari Ini" are geofenced, so
/// passing a later day's stop does not count. The active day is persisted, so
/// opening that day's map again resumes tracking.
///
/// `geofence_service` checks the device position while the app process is
/// alive (foreground or background); it does not register OS-level fences,
/// so a fully killed app stops detecting until the map is opened again.
class LiveTrackingService {
  LiveTrackingService({
    required VisitSync visitSync,
    required TripService repository,
    required LocalNotificationService notifications,
  })  : _visitSync = visitSync,
        _repository = repository,
        _notifications = notifications;

  static const _activeDayKey = 'live_tracking_active_day';
  static const _geofenceRadiusMeters = 100.0;
  static const _minRetryDelay = Duration(seconds: 30);
  static const _maxRetryDelay = Duration(minutes: 5);

  final VisitSync _visitSync;
  final TripService _repository;
  final LocalNotificationService _notifications;
  final _arrivals = StreamController<VisitArrival>.broadcast();
  final _syncedVisits = StreamController<Map<int, DateTime?>>.broadcast();

  /// Stops the user unmarked by hand while tracking. They are not fenced
  /// again, otherwise standing at the spot would re-mark them immediately.
  final _manuallyUnmarked = <int>{};

  GeofenceService? _service;
  AppLocalizations? _l10n;
  int? _tripsId;
  int? _itineraryDaysId;
  Timer? _retryTimer;
  Duration _retryDelay = _minRetryDelay;

  Stream<VisitArrival> get arrivals => _arrivals.stream;

  /// Visit marks the background retry managed to send, keyed by item id.
  Stream<Map<int, DateTime?>> get syncedVisits => _syncedVisits.stream;

  bool isTracking(int itineraryDaysId) =>
      _service != null && _itineraryDaysId == itineraryDaysId;

  /// The day that was started and not stopped, as `(tripsId, itineraryDaysId)`.
  Future<(int, int)?> savedActiveDay() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_activeDayKey)?.split(':');
    if (saved == null || saved.length != 2) return null;

    final tripsId = int.tryParse(saved[0]);
    final itineraryDaysId = int.tryParse(saved[1]);
    if (tripsId == null || itineraryDaysId == null) return null;
    return (tripsId, itineraryDaysId);
  }

  Future<TrackingStartResult> startDay(Trip trip, ItineraryDay day, AppLocalizations l10n) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return TrackingStartResult.locationServiceOff;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return TrackingStartResult.permissionDenied;
    }

    await _notifications.requestPermission();
    await stop();

    _l10n = l10n;
    _tripsId = trip.tripsId;
    _itineraryDaysId = day.itineraryDaysId;
    _manuallyUnmarked.clear();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeDayKey, '${trip.tripsId}:${day.itineraryDaysId}');

    final service = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: false,
      allowMockLocations: false,
    );
    service.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    service.addStreamErrorListener(_onError);
    _service = service;

    try {
      await service.start(_geofencesFor(day));
    } catch (error) {
      _onError(error);
    }

    _scheduleRetry();
    developer.log('Live tracking started for trip ${trip.tripsId} day ${day.dayNumber}', name: 'LiveTracking');
    return TrackingStartResult.started;
  }

  Future<void> stop({bool forgetActiveDay = false}) async {
    _retryTimer?.cancel();
    _retryTimer = null;

    final service = _service;
    _service = null;
    if (service != null) {
      service.removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      service.removeStreamErrorListener(_onError);
      service.clearGeofenceList();
      await service.stop();
    }

    if (forgetActiveDay) {
      _tripsId = null;
      _itineraryDaysId = null;
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_activeDayKey);
    }
  }

  /// Re-fences the active day after its stops changed (manual toggle, swap).
  void refreshStops(ItineraryDay day, {int? unmarkedItemId}) {
    final service = _service;
    if (service == null || day.itineraryDaysId != _itineraryDaysId) return;

    if (unmarkedItemId != null) _manuallyUnmarked.add(unmarkedItemId);
    service.clearGeofenceList();
    service.addGeofenceList(_geofencesFor(day));
  }

  List<Geofence> _geofencesFor(ItineraryDay day) {
    return [
      for (final item in day.items)
        if (!item.isVisited && item.place != null && !_manuallyUnmarked.contains(item.itineraryItemsId))
          Geofence(
            id: 'item_${item.itineraryItemsId}',
            data: item,
            latitude: item.place!.lat,
            longitude: item.place!.lng,
            radius: [GeofenceRadius(id: 'arrival', length: _geofenceRadiusMeters)],
          ),
    ];
  }

  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius radius,
    GeofenceStatus status,
    Location location,
  ) async {
    final item = geofence.data;
    final tripsId = _tripsId;
    if (status != GeofenceStatus.ENTER || item is! ItineraryItem || tripsId == null) return;

    _service?.removeGeofenceById(geofence.id);
    developer.log('Arrived at item ${item.itineraryItemsId}', name: 'LiveTracking');

    final l10n = _l10n;
    final placeName = item.place?.name ?? '';
    if (l10n != null) {
      await _notifications.showArrival(
        id: item.itineraryItemsId,
        title: l10n.notificationArrivedTitle(placeName),
        body: l10n.notificationArrivedBody,
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
      );
    }

    final change = await _visitSync.setVisited(item, visited: true);
    _arrivals.add(VisitArrival(
      tripsId: tripsId,
      itineraryItemsId: item.itineraryItemsId,
      visitedAt: change is VisitSynced ? change.visitedAt : DateTime.now(),
    ));
    if (change is VisitQueued) _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, _retryQueuedVisits);
  }

  Future<void> _retryQueuedVisits() async {
    final tripsId = _tripsId;
    if (_service == null || tripsId == null) return;

    if (!await _visitSync.hasPending()) {
      _retryDelay = _minRetryDelay;
      _scheduleRetry();
      return;
    }

    try {
      final changes = await _visitSync.flush(await _repository.fetchTrip(tripsId));
      if (changes.isNotEmpty) _syncedVisits.add(changes);
      _retryDelay = _minRetryDelay;
    } catch (error) {
      final doubled = _retryDelay * 2;
      _retryDelay = doubled > _maxRetryDelay ? _maxRetryDelay : doubled;
      developer.log('Visit retry failed, next in ${_retryDelay.inSeconds}s: $error', name: 'LiveTracking');
    }
    _scheduleRetry();
  }

  void _onError(Object? error) {
    developer.log('Geofence error: $error', name: 'LiveTracking', level: 1000);
  }

  Future<void> dispose() async {
    await stop();
    await _arrivals.close();
    await _syncedVisits.close();
  }
}

final liveTrackingServiceProvider = Provider<LiveTrackingService>((ref) {
  final service = LiveTrackingService(
    visitSync: ref.watch(visitSyncProvider),
    repository: ref.watch(tripServiceProvider),
    notifications: ref.watch(localNotificationServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
