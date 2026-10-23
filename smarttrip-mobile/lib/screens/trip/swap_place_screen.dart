import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/polyline_codec.dart';
import '../../services/trip_service.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rupiah_input_formatter.dart';
import '../../widgets/screen_header.dart';
import '../catalog/widgets/catalog_filter_chip.dart';

final _swapCandidatesProvider = FutureProvider.autoDispose.family<List<TripPlace>, int>((ref, itineraryItemsId) {
  return ref.read(tripServiceProvider).fetchSwapCandidates(itineraryItemsId);
});

final _swapSearchProvider = FutureProvider.autoDispose.family<List<TripPlace>, String>((ref, query) {
  return ref.read(tripServiceProvider).searchPlaces(query);
});

enum _SwapFilter { near, rating, cheap, indoor }

/// D2. Ganti Tempat (F010), a page of its own: the stop being replaced on
/// top, then the ranked recommendations (filterable) or a search over the
/// whole catalog. A card is picked first and "Terapkan Penggantian" pops
/// with it; null on cancel or back. [preferIndoor] (rain on that day, F025)
/// lists indoor places first.
class SwapPlaceScreen extends ConsumerStatefulWidget {
  const SwapPlaceScreen({
    super.key,
    required this.item,
    this.preferIndoor = false,
    this.dayNumber,
    this.previous,
    this.next,
  });

  final ItineraryItem item;
  final bool preferIndoor;

  /// Shown in the header as "Jadwal Hari N" when known.
  final int? dayNumber;

  /// The stops before and after it that day (the hotel stands in at the
  /// ends), for how a replacement changes the route.
  final TripPlace? previous;
  final TripPlace? next;

  static Future<TripPlace?> show(
    BuildContext context,
    ItineraryItem item, {
    bool preferIndoor = false,
    int? dayNumber,
    TripPlace? previous,
    TripPlace? next,
  }) {
    return Navigator.of(context).push<TripPlace>(
      MaterialPageRoute(
        builder: (_) => SwapPlaceScreen(
          item: item,
          preferIndoor: preferIndoor,
          dayNumber: dayNumber,
          previous: previous,
          next: next,
        ),
      ),
    );
  }

  @override
  ConsumerState<SwapPlaceScreen> createState() => _SwapPlaceScreenState();
}

class _SwapPlaceScreenState extends ConsumerState<SwapPlaceScreen> {
  static const _nearKm = 3.0;
  static const _goodRating = 4.5;
  static const _cheapIdr = 50000;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _isSearchTab = false;
  late final Set<_SwapFilter> _filters = {if (widget.preferIndoor) _SwapFilter.indoor};
  TripPlace? _picked;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _toggleFilter(_SwapFilter filter) {
    setState(() {
      if (!_filters.remove(filter)) _filters.add(filter);
    });
  }

  /// Km from the stop being replaced, null when either has no spot.
  double? _distanceKm(TripPlace place) {
    final current = widget.item.place;
    if (!_hasSpot(current)) return null;
    return haversineKm(current!.lat, current.lng, place.lat, place.lng);
  }

  /// Straight-line km the day's route gains (positive) or saves (negative)
  /// when [place] takes the stop's slot between its neighbours. Null without
  /// a neighbour or a spot to compare with.
  double? _routeDeltaKm(TripPlace place) {
    final current = widget.item.place;
    final neighbours = [widget.previous, widget.next].where(_hasSpot).cast<TripPlace>().toList();
    if (!_hasSpot(current) || neighbours.isEmpty) return null;

    double via(TripPlace stop) =>
        neighbours.fold(0.0, (sum, neighbour) => sum + haversineKm(neighbour.lat, neighbour.lng, stop.lat, stop.lng));
    return via(place) - via(current!);
  }

  static bool _hasSpot(TripPlace? place) => place != null && !(place.lat == 0 && place.lng == 0);

  bool _passes(TripPlace place) {
    for (final filter in _filters) {
      final ok = switch (filter) {
        _SwapFilter.near => (_distanceKm(place) ?? double.infinity) < _nearKm,
        _SwapFilter.rating => (place.rating ?? 0) >= _goodRating,
        _SwapFilter.cheap => place.estimatedCostIdr != null && place.estimatedCostIdr! <= _cheapIdr,
        _SwapFilter.indoor => !place.isOutdoor,
      };
      if (!ok) return false;
    }
    return true;
  }

  /// A stable sort keeps the server's ranking inside each group.
  List<TripPlace> _indoorFirst(List<TripPlace> places) {
    if (!widget.preferIndoor) return places;
    return [...places.where((place) => !place.isOutdoor), ...places.where((place) => place.isOutdoor)];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates = ref.watch(_swapCandidatesProvider(widget.item.itineraryItemsId));
    // What the list shows: the filters apply to the count as well.
    final candidateCount = candidates.valueOrNull?.where(_passes).length;
    final picked = _picked;
    final pickedDelta = picked == null ? null : _routeDeltaKm(picked);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ScreenHeader(
        subtitle: l10n.swapTitle,
        trailing: widget.dayNumber == null
            ? null
            : Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.swapDaySubtitle(widget.dayNumber!),
                  style: appText(11.5, FontWeight.w700, Colors.white, height: 16),
                ),
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      _CurrentStopCard(item: widget.item),
                      const SizedBox(height: 14),
                      _TabSwitch(
                        isSearch: _isSearchTab,
                        recommendedLabel: l10n.swapTabRecommended,
                        searchLabel: l10n.swapTabSearch,
                        count: candidateCount,
                        onChanged: (isSearch) => setState(() => _isSearchTab = isSearch),
                      ),
                      const SizedBox(height: 12),
                      if (_isSearchTab)
                        _SearchField(
                          controller: _searchController,
                          hint: l10n.swapSearchHint,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                    ],
                  ),
                ),
                if (!_isSearchTab) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final (filter, label, icon) in [
                            (_SwapFilter.near, l10n.swapFilterNear, Icons.near_me_outlined),
                            (_SwapFilter.rating, l10n.swapFilterRating, Icons.star_rounded),
                            (_SwapFilter.cheap, l10n.swapFilterCheap, Icons.payments_outlined),
                            (_SwapFilter.indoor, l10n.swapIndoor, Icons.roofing_rounded),
                          ]) ...[
                            if (filter != _SwapFilter.near) const SizedBox(width: 8),
                            CatalogFilterChip(
                              label: label,
                              leading: icon,
                              selected: _filters.contains(filter),
                              onTap: () => _toggleFilter(filter),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _EngineNote(
                        title: l10n.swapEngineTitle,
                        body: widget.preferIndoor
                            ? l10n.swapRainSubtitle(widget.item.place?.name ?? l10n.itineraryUnknownPlace)
                            : l10n.swapEngineBody,
                        rainy: widget.preferIndoor,
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _isSearchTab ? l10n.swapSearchResults : l10n.swapBestTitle,
                            style: appText(16, FontWeight.w800, AppColors.ink, height: 22),
                          ),
                        ),
                        if (!_isSearchTab)
                          Text(l10n.swapSortedBy, style: appText(11.5, FontWeight.w700, AppColors.sea600, height: 16)),
                      ],
                    ),
                  ),
                ),
                _isSearchTab
                    ? _candidateSliver(ref.watch(_swapSearchProvider(_query)), l10n, ranked: false)
                    : _candidateSliver(candidates, l10n, ranked: true),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.field)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, size: 17, color: AppColors.sea600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: picked == null
                                ? Text(
                                    l10n.swapPickHint,
                                    style: appText(12, FontWeight.w600, AppColors.inkMuted, height: 16),
                                  )
                                : Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '${l10n.swapSummaryLabel} '),
                                        TextSpan(
                                          text: widget.item.place?.name ?? l10n.itineraryUnknownPlace,
                                          style: appText(12, FontWeight.w800, AppColors.ink, height: 16),
                                        ),
                                        const TextSpan(text: '  →  '),
                                        TextSpan(
                                          text: picked.name,
                                          style: appText(12, FontWeight.w800, AppColors.sea600, height: 16),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: appText(12, FontWeight.w600, AppColors.inkMuted, height: 16),
                                  ),
                          ),
                          if (pickedDelta != null) ...[const SizedBox(width: 8), _RouteDeltaChip(deltaKm: pickedDelta)],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.field,
                                foregroundColor: AppColors.ink,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(l10n.actionCancel, style: appText(14, FontWeight.w800, AppColors.ink)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: PrimaryButton(
                            label: l10n.swapApply,
                            trailingIcon: Icons.check_circle_outline_rounded,
                            onPressed: picked == null ? null : () => Navigator.of(context).pop(picked),
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
      ),
    );
  }

  Widget _candidateSliver(AsyncValue<List<TripPlace>> state, AppLocalizations l10n, {required bool ranked}) {
    Widget message(Widget child) => SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: child),
    );

    return state.when(
      loading: () => message(const Center(child: CircularProgressIndicator(color: AppColors.sea600))),
      error: (error, _) => message(
        LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () {
            ref.invalidate(_swapCandidatesProvider);
            ref.invalidate(_swapSearchProvider);
          },
        ),
      ),
      data: (found) {
        final ordered = _indoorFirst(found);
        final places = ranked ? ordered.where(_passes).toList() : ordered;
        if (places.isEmpty) {
          return message(
            Text(
              found.isNotEmpty && ranked ? l10n.swapNoFilterResults : l10n.swapEmpty,
              textAlign: TextAlign.center,
              style: appText(13, FontWeight.w600, AppColors.inkMuted, height: 18),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = places[index];
              return _CandidateCard(
                place: place,
                distanceKm: _distanceKm(place),
                routeDeltaKm: _routeDeltaKm(place),
                isTopPick: ranked && identical(place, ordered.first),
                showArea: widget.preferIndoor,
                selected: _picked?.placesId == place.placesId,
                onTap: () => setState(() => _picked = place),
              );
            },
          ),
        );
      },
    );
  }
}

/// The stop being replaced: its badge, visit length, photo and meta.
class _CurrentStopCard extends StatelessWidget {
  const _CurrentStopCard({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final place = item.place;
    final minutes = place?.estimatedVisitMinutes;
    final rating = place?.rating;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
                decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF8A4B00)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.swapCurrentBadge.toUpperCase(),
                      style: appText(10.5, FontWeight.w800, const Color(0xFF8A4B00), height: 15, letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (minutes != null) ...[
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Text(_duration(minutes, l10n), style: appText(12, FontWeight.w700, AppColors.inkMuted, height: 16)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Thumb(url: place?.photoUrl, rating: rating, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place?.name ?? l10n.itineraryUnknownPlace,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: appText(16, FontWeight.w800, AppColors.ink, height: 21),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _meta(place, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
                      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.format_list_numbered_rounded, size: 12, color: AppColors.sea600),
                          const SizedBox(width: 4),
                          Text(
                            l10n.swapSlot(item.visitOrder),
                            style: appText(11, FontWeight.w800, AppColors.sea600, height: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Rekomendasi (12)" / "Cari Manual" as a segmented switch.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({
    required this.isSearch,
    required this.recommendedLabel,
    required this.searchLabel,
    required this.count,
    required this.onChanged,
  });

  final bool isSearch;
  final String recommendedLabel;
  final String searchLabel;
  final int? count;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment({
      required bool selected,
      required IconData icon,
      required String label,
      int? badge,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: selected ? AppColors.cardShadow : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: selected ? AppColors.sea600 : AppColors.inkMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(13, FontWeight.w800, selected ? AppColors.ink : AppColors.inkMuted),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(999)),
                      child: Text('$badge', style: appText(10.5, FontWeight.w800, Colors.white, height: 15)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          segment(
            selected: !isSearch,
            icon: Icons.auto_awesome_rounded,
            label: recommendedLabel,
            badge: count,
            onTap: () => onChanged(false),
          ),
          segment(
            selected: isSearch,
            icon: Icons.manage_search_rounded,
            label: searchLabel,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: appText(14, FontWeight.w600, AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: appText(14, FontWeight.w500, AppColors.inkMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inkMuted),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkMuted),
                  onPressed: onClear,
                ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sea600, width: 1.5),
        ),
      ),
    );
  }
}

/// What the ranking is based on (or, on a rainy day, why indoor places lead).
class _EngineNote extends StatelessWidget {
  const _EngineNote({required this.title, required this.body, required this.rainy});

  final String title;
  final String body;
  final bool rainy;

  @override
  Widget build(BuildContext context) {
    final accent = rainy ? const Color(0xFF8A4B00) : AppColors.sea600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rainy ? const Color(0xFFFFF4E5) : const Color(0xFFE6EFF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rainy ? Icons.umbrella_rounded : Icons.tips_and_updates_outlined, size: 19, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: appText(13, FontWeight.w800, AppColors.ink, height: 18)),
                const SizedBox(height: 2),
                Text(body, style: appText(12, FontWeight.w500, AppColors.inkSoft, height: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One replacement: match and top-pick badges, a radio, photo with rating,
/// meta, distance and drive time from the stop being replaced, the price,
/// and how the day's route changes. A sea bar marks the picked one.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.place,
    required this.distanceKm,
    required this.routeDeltaKm,
    required this.isTopPick,
    required this.showArea,
    required this.selected,
    required this.onTap,
  });

  final TripPlace place;
  final double? distanceKm;

  /// See [_SwapPlaceScreenState._routeDeltaKm].
  final double? routeDeltaKm;
  final bool isTopPick;

  /// Rainy day: say whether it is indoors or outdoors.
  final bool showArea;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final score = place.topsisScore;
    final cost = place.estimatedCostIdr;
    final distance = distanceKm;
    final delta = routeDeltaKm;

    final badges = <Widget>[
      if (score != null)
        _Badge(
          icon: Icons.verified_outlined,
          label: l10n.swapMatch((score * 100).round().clamp(0, 100)),
          background: AppColors.navy900,
          foreground: Colors.white,
        ),
      if (isTopPick)
        _Badge(
          icon: Icons.workspace_premium_outlined,
          label: l10n.swapTopPick,
          background: AppColors.sun400,
          foreground: AppColors.navy900,
        ),
      if (showArea)
        _Badge(
          icon: place.isOutdoor ? Icons.park_outlined : Icons.roofing_rounded,
          label: place.isOutdoor ? l10n.swapOutdoor : l10n.swapIndoor,
          background: AppColors.field,
          foreground: AppColors.sea600,
        ),
    ];

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? AppColors.sea600 : AppColors.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(selected ? 16 : 12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: badges)),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.sea600 : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: selected ? AppColors.sea600 : AppColors.line, width: 2),
                          ),
                          child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                        ),
                      ],
                    ),
                    if (badges.isNotEmpty) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Thumb(url: place.photoUrl, rating: place.rating, size: 84),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: appText(15, FontWeight.w800, AppColors.ink, height: 20),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _meta(place, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                              ),
                              if (distance != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.near_me_rounded, size: 13, color: AppColors.sea600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_km(distance, languageCode)} km',
                                      style: appText(12, FontWeight.w800, AppColors.sea600, height: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: AppColors.inkMuted,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        l10n.swapDriveMinutes(_driveMinutes(distance)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: appText(12, FontWeight.w600, AppColors.inkSoft, height: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (cost != null) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.payments_outlined, size: 13, color: _priceColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      cost == 0 ? l10n.catalogPriceFree : 'Rp ${RupiahInputFormatter.format(cost)}',
                                      style: appText(12.5, FontWeight.w800, _priceColor, height: 17),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (delta != null) ...[const SizedBox(height: 10), _RouteNote(deltaKm: delta)],
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(width: 5, child: ColoredBox(color: AppColors.sea600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _priceColor = Color(0xFF8A4B00);

/// Below 0.3 km either way the route counts as the same.
const _sameRouteKm = 0.3;

/// How the day's route changes with this replacement: green when it gets
/// shorter, amber when longer, blue when about the same.
class _RouteNote extends StatelessWidget {
  const _RouteNote({required this.deltaKm});

  final double deltaKm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final km = _km(deltaKm.abs(), languageCode);
    final minutes = _driveMinutes(deltaKm.abs());

    final (icon, text, background, foreground) = switch (deltaKm) {
      <= -_sameRouteKm => (
        Icons.route_rounded,
        l10n.swapRouteShorter(km, minutes),
        const Color(0xFFE7F6EE),
        const Color(0xFF17803D),
      ),
      >= _sameRouteKm => (
        Icons.timelapse_rounded,
        l10n.swapRouteLonger(km, minutes),
        const Color(0xFFFFF4E5),
        _priceColor,
      ),
      _ => (Icons.check_circle_outline_rounded, l10n.swapRouteSame, const Color(0xFFE6EFF8), AppColors.sea600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: appText(12, FontWeight.w700, foreground, height: 17))),
        ],
      ),
    );
  }
}

/// The route change of the picked place in the bottom bar: "Hemat 1,2 km",
/// "+0,8 km" or "≈ sama".
class _RouteDeltaChip extends StatelessWidget {
  const _RouteDeltaChip({required this.deltaKm});

  final double deltaKm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final km = _km(deltaKm.abs(), Localizations.localeOf(context).languageCode);

    final (text, background, foreground) = switch (deltaKm) {
      <= -_sameRouteKm => (l10n.swapDeltaSave(km), const Color(0xFFE7F6EE), const Color(0xFF17803D)),
      >= _sameRouteKm => (l10n.swapDeltaExtra(km), const Color(0xFFFFF4E5), _priceColor),
      _ => (l10n.swapDeltaSame, const Color(0xFFE6EFF8), AppColors.sea600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: appText(11, FontWeight.w800, foreground, height: 15)),
    );
  }
}

/// "2,8" in Indonesian, "2.8" in English.
String _km(double km, String languageCode) => NumberFormat('0.0', languageCode).format(km);

/// A rough city drive: straight-line km at an average 20 km/h (detours and
/// traffic included), at least a minute.
int _driveMinutes(double km) => math.max(1, (km / 20 * 60).round());

/// "45 menit", "1 jam", "1j 30m".
String _duration(int minutes, AppLocalizations l10n) {
  if (minutes < 60) return l10n.itineraryVisitMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? l10n.swapDurationHours(hours) : l10n.swapDurationHoursMinutes(hours, rest);
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.background, required this.foreground, this.icon});

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 9 : 7, 3, 9, 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: foreground), const SizedBox(width: 4)],
          Text(label, style: appText(10.5, FontWeight.w800, foreground, height: 15)),
        ],
      ),
    );
  }
}

/// A square photo with the rating in its corner.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.rating, required this.size});

  final String? url;
  final double? rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rating = this.rating;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlacePhoto(url: url),
            if (rating != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.navy900.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 11, color: AppColors.sun400),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: appText(10.5, FontWeight.w800, Colors.white, height: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Kuliner · Bengkong", from the type and kecamatan the trip API sends.
String _meta(TripPlace? place, AppLocalizations l10n) {
  if (place != null && place.placesId == null) return l10n.placeSheetCustomPin;
  final type = switch (place?.type) {
    'culinary' => l10n.catalogTypeCulinary,
    'lodging' => l10n.catalogTypeLodging,
    _ => l10n.catalogTypeAttraction,
  };
  final kecamatan = place?.kecamatan;
  return kecamatan == null || kecamatan.isEmpty ? type : '$type · $kecamatan';
}
