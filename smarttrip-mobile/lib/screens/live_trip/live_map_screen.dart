import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/live_tracking_service.dart';
import '../../services/polyline_codec.dart';
import '../../services/trip_service.dart';
import '../../services/visit_sync.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/osm_tile_layers.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../trip/widgets/source_badge.dart';

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
  static const _visitedLine = Color(0xFF9AA4B1);
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
            child: const _PinBadge(icon: Icons.hotel_rounded, background: AppColors.sun400, foreground: AppColors.navy900),
          ),
        ),
      for (final item in day.items)
        if (item.place != null)
          Marker(
            point: LatLng(item.place!.lat, item.place!.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => setState(() => _selectedItemId = item.itineraryItemsId),
              onLongPress: () => _toggleVisit(item, l10n),
              child: _PinBadge(
                label: '${item.visitOrder}',
                icon: item.isVisited ? Icons.done_all_rounded : null,
                background: item.isVisited ? AppColors.sea600 : AppColors.navy900,
                foreground: Colors.white,
                isSelected: item.itineraryItemsId == _selectedItemId,
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
          color: item.isVisited ? _visitedLine : AppColors.sea600,
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
    final tripState = ref.watch(tripDetailProvider(widget.tripsId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ScreenHeader(
        subtitle: l10n.liveMapTitle,
        trailing: _HeaderPill(label: l10n.liveMapDay(widget.dayNumber)),
      ),
      body: tripState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sea600)),
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
    final hotel = trip.hotel;
    final isTracking = _tracking.isTracking(day.itineraryDaysId);
    final nextItem = day.items.where((item) => !item.isVisited).firstOrNull;
    final selected = day.items.where((item) => item.itineraryItemsId == _selectedItemId).firstOrNull ??
        nextItem ??
        day.items.firstOrNull;
    final visited = day.items.where((item) => item.isVisited).length;

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
              Positioned(left: 12, top: 12, child: _TrackingChip(isTracking: isTracking)),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: const Color(0x330A2440),
                  child: IconButton(
                    tooltip: l10n.liveMapCenter,
                    icon: const Icon(Icons.my_location_rounded, color: AppColors.sea600, size: 20),
                    onPressed: () => _centerOnUser(day, hotel),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          // The panel slides up over the map's bottom edge.
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (isTracking)
                    _TrackingBar(visited: visited, total: day.items.length, onStop: _stopDay)
                  else
                    PrimaryButton(
                      label: l10n.liveMapStartDay,
                      trailingIcon: Icons.play_arrow_rounded,
                      isLoading: _isStarting,
                      onPressed: () => _startDay(trip, day, l10n),
                    ),
                  const SizedBox(height: 14),
                  if (selected != null) ...[
                    _SelectedStopCard(
                      item: selected,
                      hasArrived: selected.itineraryItemsId == _arrivedItemId && selected.isVisited,
                      onToggleVisit: () => _toggleVisit(selected, l10n),
                      onNavigate: selected.place == null ? null : () => _openNavigation(selected.place!),
                    ),
                    const SizedBox(height: 14),
                  ],
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 15, color: AppColors.inkMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.liveMapLongPressHint,
                          style: appText(11.5, FontWeight.w500, AppColors.inkMuted, height: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Hari 1" in the navy header, the same pill as the trip setup steps.
class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(label, style: appText(12, FontWeight.w700, Colors.white)),
    );
  }
}

class _TrackingChip extends StatelessWidget {
  const _TrackingChip({required this.isTracking});

  static const _activeColor = Color(0xFF16A34A);

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isTracking ? _activeColor : AppColors.inkMuted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isTracking ? l10n.liveMapTrackingActive : l10n.liveMapTrackingOff,
            style: appText(12, FontWeight.w700, AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// While the day is tracked: progress through the day and the stop button.
class _TrackingBar extends StatelessWidget {
  const _TrackingBar({required this.visited, required this.total, required this.onStop});

  final int visited;
  final int total;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy700, AppColors.navy900]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.near_me_rounded, size: 20, color: AppColors.sun400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.liveMapTrackingActive, style: appText(14, FontWeight.w800, Colors.white)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : visited / total,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    color: AppColors.sun400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.liveMapProgress(visited, total),
                  style: appText(11, FontWeight.w600, Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onStop,
            style: TextButton.styleFrom(foregroundColor: AppColors.sun400),
            child: Text(l10n.liveMapStop, style: appText(13, FontWeight.w700, AppColors.sun400)),
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

  static const _successFill = Color(0xFFE7F6EC);
  static const _successInk = Color(0xFF166534);

  final ItineraryItem item;
  final bool hasArrived;
  final VoidCallback onToggleVisit;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final place = item.place;
    final minutes = place?.estimatedVisitMinutes;
    final kecamatan = place?.kecamatan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasArrived) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _successFill, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, size: 16, color: _successInk),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.liveMapArrived, style: appText(12, FontWeight.w700, _successInk))),
                  Text(l10n.liveMapAutoCheckIn, style: appText(10.5, FontWeight.w700, _successInk)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlacePhoto(url: place?.photoUrl),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(999)),
                          child: Text('#${item.visitOrder}', style: appText(10.5, FontWeight.w800, Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceBadge(isFromWishlist: item.isFromWishlist),
                    const SizedBox(height: 5),
                    Text(
                      place?.name ?? l10n.itineraryUnknownPlace,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: appText(15, FontWeight.w800, AppColors.ink, height: 20),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (kecamatan != null && kecamatan.isNotEmpty)
                          _Meta(icon: Icons.place_outlined, text: kecamatan),
                        if (minutes != null) _Meta(icon: Icons.timer_outlined, text: l10n.liveMapAllocation(minutes)),
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
                child: _CardButton(
                  icon: item.isVisited ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                  label: item.isVisited ? l10n.liveMapUnmarkVisited : l10n.liveMapMarkVisited,
                  filled: !item.isVisited,
                  onPressed: onToggleVisit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardButton(
                  icon: Icons.navigation_outlined,
                  label: l10n.liveMapNavigate,
                  filled: false,
                  onPressed: onNavigate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(text, style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16)),
      ],
    );
  }
}

/// The two actions on the stop card: sea blue filled, or white with a line.
class _CardButton extends StatelessWidget {
  const _CardButton({required this.icon, required this.label, required this.filled, required this.onPressed});

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppColors.navy900;
    return Material(
      color: filled ? AppColors.sea600 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(13, FontWeight.w700, foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 18, color: AppColors.sea600),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.liveMapStopsTitle, style: appText(15, FontWeight.w800, AppColors.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  l10n.liveMapStopsCount(day.items.length),
                  style: appText(11, FontWeight.w700, AppColors.navy700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in day.items)
            _StopRow(
              item: item,
              isNext: item.itineraryItemsId == nextItemId,
              isSelected: item.itineraryItemsId == selectedItemId,
              onTap: () => onSelect(item),
              onLongPress: () => onToggleVisit(item),
            ),
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
    final minutes = item.place?.estimatedVisitMinutes;

    final status = item.isVisited
        ? l10n.liveMapStopVisited
        : isNext
            ? l10n.liveMapStopNext
            : l10n.liveMapStopPending;
    final subtitle = minutes == null ? status : '$status · ${l10n.liveMapAllocation(minutes)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.field : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.isVisited ? AppColors.sea600 : AppColors.navy900,
                    shape: BoxShape.circle,
                    border: isNext ? Border.all(color: AppColors.sun400, width: 2.5) : null,
                  ),
                  child: item.isVisited
                      ? const Icon(Icons.done_all_rounded, size: 14, color: Colors.white)
                      : Text('${item.visitOrder}', style: appText(12, FontWeight.w800, Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.place?.name ?? l10n.itineraryUnknownPlace,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(
                          14,
                          FontWeight.w700,
                          item.isVisited ? AppColors.inkMuted : AppColors.ink,
                        ).copyWith(decoration: item.isVisited ? TextDecoration.lineThrough : null),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(11.5, FontWeight.w500, AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.sun400, borderRadius: BorderRadius.circular(999)),
                    child: Text(l10n.liveMapNextBadge, style: appText(10.5, FontWeight.w800, AppColors.navy900)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A map pin: a number or an icon on a coloured disc with a white ring; the
/// selected stop gets a sun ring and grows a little.
class _PinBadge extends StatelessWidget {
  const _PinBadge({
    this.label,
    this.icon,
    required this.background,
    required this.foreground,
    this.isSelected = false,
  });

  final String? label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 40.0 : 32.0;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? AppColors.sun400 : Colors.white, width: isSelected ? 3 : 2),
          boxShadow: const [BoxShadow(color: Color(0x400A2440), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: icon != null
            ? Icon(icon, size: isSelected ? 18 : 15, color: foreground)
            : Text(label ?? '', style: appText(isSelected ? 14 : 12.5, FontWeight.w800, foreground)),
      ),
    );
  }
}
