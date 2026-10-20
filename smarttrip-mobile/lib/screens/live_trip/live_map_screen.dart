import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/live_tracking_service.dart';
import '../../services/polyline_codec.dart';
import '../../services/trip_service.dart';
import '../../services/visit_sync.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/osm_tile_layers.dart';
import '../../widgets/place_photo.dart';

/// E1. Peta Live - Figma Mockup, node 114:354 (US6, US7, F012, F013).
///
/// Every stop of the day shows as a numbered pin from the start, each leg is
/// grey once its destination is visited and blue otherwise, and the user's
/// position is live. "Mulai Hari Ini" turns on automatic visit detection;
/// long-pressing a pin (or the list row) marks or unmarks it by hand, which
/// also works when location permission was denied.
class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key, required this.tripsId, required this.dayNumber});

  final int tripsId;
  final int dayNumber;

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  static const _visitedColor = Color(0xFF9AA4B1);
  static const _pendingColor = Color(0xFF16659A);
  static const _selectedColor = Color(0xFF004C79);
  static const _userColor = Color(0xFF1A73E8);

  final _mapController = MapController();
  StreamSubscription<VisitArrival>? _arrivalSubscription;
  StreamSubscription<Map<int, DateTime?>>? _syncSubscription;
  StreamSubscription<Position>? _positionSubscription;

  LatLng? _userPosition;
  int? _selectedItemId;
  int? _arrivedItemId;
  bool _isStarting = false;
  bool _didResumeCheck = false;

  LiveTrackingService get _tracking => ref.read(liveTrackingServiceProvider);

  @override
  void initState() {
    super.initState();
    _arrivalSubscription = _tracking.arrivals.listen(_onArrival);
    _syncSubscription = _tracking.syncedVisits.listen(_onSyncedVisits);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _arrivalSubscription?.cancel();
    _syncSubscription?.cancel();
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;

    final isGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    if (isGranted) _followUserPosition();
  }

  /// The live "you are here" dot, only while this screen is open.
  void _followUserPosition() {
    if (_positionSubscription != null) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 10),
    ).listen(
      (position) {
        if (mounted) setState(() => _userPosition = LatLng(position.latitude, position.longitude));
      },
      onError: (_) {},
    );
  }

  TripDetailController get _tripController =>
      ref.read(tripDetailProvider(widget.tripsId).notifier);

  void _onArrival(VisitArrival arrival) {
    if (!mounted || arrival.tripsId != widget.tripsId) return;

    _tripController.applyVisit(arrival.itineraryItemsId, arrival.visitedAt);
    setState(() {
      _arrivedItemId = arrival.itineraryItemsId;
      _selectedItemId = arrival.itineraryItemsId;
    });
  }

  void _onSyncedVisits(Map<int, DateTime?> visits) {
    if (!mounted) return;
    visits.forEach(_tripController.applyVisit);
  }

  /// Resumes tracking when this day was started earlier and the app was
  /// closed since (the active day is persisted by the service).
  Future<void> _resumeIfActive(Trip trip, ItineraryDay day, AppLocalizations l10n) async {
    if (_didResumeCheck) return;
    _didResumeCheck = true;

    final saved = await _tracking.savedActiveDay();
    if (saved == null || saved.$2 != day.itineraryDaysId || _tracking.isTracking(day.itineraryDaysId)) return;

    await _tracking.startDay(trip, day, l10n);
    if (mounted) setState(() {});
  }

  Future<void> _startDay(Trip trip, ItineraryDay day, AppLocalizations l10n) async {
    setState(() => _isStarting = true);
    final result = await _tracking.startDay(trip, day, l10n);
    if (!mounted) return;

    setState(() => _isStarting = false);
    await _checkLocationPermission();
    if (!mounted) return;

    final message = switch (result) {
      TrackingStartResult.started => null,
      TrackingStartResult.permissionDenied => l10n.liveMapPermissionDenied,
      TrackingStartResult.locationServiceOff => l10n.liveMapLocationServiceOff,
    };
    if (message != null) _showSnackBar(message);
  }

  Future<void> _stopDay() async {
    await _tracking.stop(forgetActiveDay: true);
    if (mounted) setState(() {});
  }

  Future<void> _toggleVisit(ItineraryItem item, AppLocalizations l10n) async {
    final willVisit = !item.isVisited;
    setState(() => _selectedItemId = item.itineraryItemsId);
    final change = await _tripController.setVisited(item, visited: willVisit);
    if (!mounted) return;

    final day = _currentDay();
    if (day != null) {
      _tracking.refreshStops(day, unmarkedItemId: willVisit ? null : item.itineraryItemsId);
    }
    if (!willVisit && _arrivedItemId == item.itineraryItemsId) setState(() => _arrivedItemId = null);
    if (change is VisitQueued) _showSnackBar(l10n.liveMapVisitQueued);
  }

  ItineraryDay? _currentDay() {
    final trip = ref.read(tripDetailProvider(widget.tripsId)).valueOrNull;
    if (trip == null) return null;
    for (final day in trip.days) {
      if (day.dayNumber == widget.dayNumber) return day;
    }
    return null;
  }

  void _centerOnUser(ItineraryDay day, TripHotel? hotel) {
    final position = _userPosition;
    if (position != null) {
      _mapController.move(position, 15);
      return;
    }
    _fitDay(day, hotel);
  }

  void _fitDay(ItineraryDay day, TripHotel? hotel) {
    final points = _dayPoints(day, hotel);
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 15),
    );
  }

  List<LatLng> _dayPoints(ItineraryDay day, TripHotel? hotel) {
    return [
      if (hotel != null) LatLng(hotel.lat, hotel.lng),
      for (final item in day.items)
        if (item.place != null) LatLng(item.place!.lat, item.place!.lng),
    ];
  }

  Future<void> _openNavigation(TripPlace place) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.lat},${place.lng}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Marker> _markers(ItineraryDay day, TripHotel? hotel, AppLocalizations l10n) {
    final position = _userPosition;

    return [
      if (hotel != null)
        Marker(
          point: LatLng(hotel.lat, hotel.lng),
          width: 34,
          height: 34,
          child: Tooltip(
            message: hotel.name.isEmpty ? l10n.liveMapHotel : hotel.name,
            child: const _PinBadge(label: 'H', background: Color(0xFF0B1C30), foreground: Colors.white),
          ),
        ),
      for (final item in day.items)
        if (item.place != null)
          Marker(
            point: LatLng(item.place!.lat, item.place!.lng),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => setState(() => _selectedItemId = item.itineraryItemsId),
              onLongPress: () => _toggleVisit(item, l10n),
              child: _PinBadge(
                label: item.isVisited ? '✓' : '${item.visitOrder}',
                background: item.isVisited
                    ? _visitedColor
                    : item.itineraryItemsId == _selectedItemId
                        ? _selectedColor
                        : const Color(0xFFD3E4FE),
                foreground: item.isVisited || item.itineraryItemsId == _selectedItemId
                    ? Colors.white
                    : _selectedColor,
              ),
            ),
          ),
      if (position != null)
        Marker(
          point: position,
          width: 22,
          height: 22,
          child: Container(
            decoration: BoxDecoration(
              color: _userColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x401A73E8), blurRadius: 10, spreadRadius: 4)],
            ),
          ),
        ),
    ];
  }

  List<Polyline> _polylines(ItineraryDay day, TripHotel? hotel) {
    final polylines = <Polyline>[];
    var previous = hotel == null ? null : LatLng(hotel.lat, hotel.lng);

    for (final item in day.items) {
      final place = item.place;
      if (place == null) continue;

      final destination = LatLng(place.lat, place.lng);
      final encoded = item.polylineToHere;
      final hasRoute = encoded != null && encoded.isNotEmpty;
      final points = hasRoute ? decodePolyline(encoded) : [?previous, destination];

      if (points.length >= 2) {
        polylines.add(Polyline(
          points: points,
          strokeWidth: 5,
          color: item.isVisited ? _visitedColor : _pendingColor,
          // No road route stored: a dashed straight line marks the estimate.
          pattern: hasRoute ? const StrokePattern.solid() : StrokePattern.dashed(segments: const [16, 10]),
        ));
      }
      previous = destination;
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final tripState = ref.watch(tripDetailProvider(widget.tripsId));

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _pendingColor,
              child: const Icon(Icons.explore, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.liveMapTitle, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    l10n.liveMapSubtitle(widget.dayNumber),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: tripState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(tripDetailProvider(widget.tripsId)),
        ),
        data: (trip) {
          final day = trip.days.where((day) => day.dayNumber == widget.dayNumber).firstOrNull;
          if (day == null) return Center(child: Text(l10n.itineraryDayEmpty));
          return _buildDay(trip, day, l10n);
        },
      ),
    );
  }

  Widget _buildDay(Trip trip, ItineraryDay day, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final hotel = trip.hotel;
    final isTracking = _tracking.isTracking(day.itineraryDaysId);
    final nextItem = day.items.where((item) => !item.isVisited).firstOrNull;
    final selected = day.items.where((item) => item.itineraryItemsId == _selectedItemId).firstOrNull ??
        nextItem ??
        day.items.firstOrNull;

    unawaited(_resumeIfActive(trip, day, l10n));

    final firstPoint = _dayPoints(day, hotel).firstOrNull ?? batamCenter;

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: firstPoint,
                  initialZoom: 12,
                  onMapReady: () => _fitDay(day, hotel),
                ),
                children: [
                  osmTileLayer(),
                  PolylineLayer(polylines: _polylines(day, hotel)),
                  MarkerLayer(markers: _markers(day, hotel, l10n)),
                  osmAttribution(),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    tooltip: l10n.liveMapCenter,
                    icon: Icon(Icons.my_location, color: tokens.link, size: 20),
                    onPressed: () => _centerOnUser(day, hotel),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _TrackingChip(isTracking: isTracking),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            children: [
              if (isTracking)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _stopDay,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(l10n.liveMapStopTracking),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _isStarting ? null : () => _startDay(trip, day, l10n),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: tokens.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
                  ),
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.liveMapStartDay),
                ),
              const SizedBox(height: 12),
              if (selected != null)
                _SelectedStopCard(
                  item: selected,
                  hasArrived: selected.itineraryItemsId == _arrivedItemId && selected.isVisited,
                  onToggleVisit: () => _toggleVisit(selected, l10n),
                  onNavigate: selected.place == null ? null : () => _openNavigation(selected.place!),
                ),
              const SizedBox(height: 12),
              _StopList(
                day: day,
                nextItemId: nextItem?.itineraryItemsId,
                selectedItemId: selected?.itineraryItemsId,
                onSelect: (item) {
                  setState(() => _selectedItemId = item.itineraryItemsId);
                  final place = item.place;
                  if (place != null) {
                    _mapController.move(LatLng(place.lat, place.lng), 15);
                  }
                },
                onToggleVisit: (item) => _toggleVisit(item, l10n),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.liveMapLongPressHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: tokens.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingChip extends StatelessWidget {
  const _TrackingChip({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: const Color(0x4DC0C7D1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTracking ? Icons.near_me : Icons.near_me_disabled_outlined,
            size: 12,
            color: isTracking ? tokens.onSuccess : tokens.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            isTracking ? l10n.liveMapTrackingActive : l10n.liveMapTrackingOff,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SelectedStopCard extends StatelessWidget {
  const _SelectedStopCard({
    required this.item,
    required this.hasArrived,
    required this.onToggleVisit,
    required this.onNavigate,
  });

  final ItineraryItem item;
  final bool hasArrived;
  final VoidCallback onToggleVisit;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final place = item.place;
    final minutes = place?.estimatedVisitMinutes;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: const Color(0x4DC0C7D1)),
        boxShadow: AppTokens.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasArrived) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: tokens.successFill.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.onSuccess.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, size: 15, color: tokens.onSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.liveMapArrived,
                      style: theme.textTheme.labelSmall?.copyWith(color: tokens.onSuccess, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      l10n.liveMapAutoCheckIn,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: tokens.onSuccess),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      child: PlacePhoto(url: place?.photoUrl),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004C79),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${item.visitOrder}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (place?.kecamatan != null)
                      Text(
                        place!.kecamatan!.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: const Color(0xFF004C79),
                        ),
                      ),
                    Text(
                      place?.name ?? l10n.itineraryUnknownPlace,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (minutes != null)
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: tokens.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.liveMapAllocation(minutes),
                            style: theme.textTheme.labelSmall?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onToggleVisit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: item.isVisited ? tokens.chipFill : const Color(0xFF16659A),
                    foregroundColor: item.isVisited ? const Color(0xFF004C79) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(item.isVisited ? Icons.undo : Icons.check_circle_outline, size: 16),
                  label: Text(item.isVisited ? l10n.liveMapUnmarkVisited : l10n.liveMapMarkVisited),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: tokens.fieldFill,
                    foregroundColor: const Color(0xFF004C79),
                    side: const BorderSide(color: Color(0x66C0C7D1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: Text(l10n.liveMapNavigate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopList extends StatelessWidget {
  const _StopList({
    required this.day,
    required this.nextItemId,
    required this.selectedItemId,
    required this.onSelect,
    required this.onToggleVisit,
  });

  final ItineraryDay day;
  final int? nextItemId;
  final int? selectedItemId;
  final ValueChanged<ItineraryItem> onSelect;
  final ValueChanged<ItineraryItem> onToggleVisit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: const Color(0x4DC0C7D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: tokens.link),
              const SizedBox(width: 6),
              Expanded(child: Text(l10n.liveMapStopsTitle, style: theme.textTheme.labelLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: tokens.fieldFill, borderRadius: BorderRadius.circular(9999)),
                child: Text(
                  l10n.liveMapStopsCount(day.items.length),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: const Color(0xFF004C79)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in day.items) ...[
            _StopRow(
              item: item,
              isNext: item.itineraryItemsId == nextItemId,
              isSelected: item.itineraryItemsId == selectedItemId,
              onTap: () => onSelect(item),
              onLongPress: () => onToggleVisit(item),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.item,
    required this.isNext,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final ItineraryItem item;
  final bool isNext;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final minutes = item.place?.estimatedVisitMinutes;

    final status = item.isVisited
        ? l10n.liveMapStopVisited
        : isNext
            ? l10n.liveMapStopNext
            : l10n.liveMapStopPending;
    final subtitle = minutes == null ? status : '$status • ${l10n.liveMapAllocation(minutes)}';

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.isVisited
                ? tokens.successFill
                : isNext
                    ? const Color(0xFF16659A)
                    : const Color(0xFFD3E4FE),
          ),
          child: item.isVisited
              ? Icon(Icons.done_all, size: 14, color: tokens.onSuccess)
              : Text(
                  '${item.visitOrder}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isNext ? Colors.white : const Color(0xFF41474F),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: isSelected ? const Color(0x4DCEE5FF) : const Color(0x80EFF4FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: isSelected ? const Color(0x6616659A) : const Color(0x33C0C7D1)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.visitOrder}. ${item.place?.name ?? l10n.itineraryUnknownPlace}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected ? const Color(0xFF004C79) : null,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF41474F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: tokens.successFill, borderRadius: BorderRadius.circular(9999)),
                        child: Text(
                          l10n.liveMapNextBadge,
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: const Color(0xFF006F66)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
