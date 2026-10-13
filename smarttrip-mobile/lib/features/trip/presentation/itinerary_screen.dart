import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../live_trip/data/polyline_codec.dart';
import '../data/trip_models.dart';
import 'trip_detail_controller.dart';
import 'trip_error_message.dart';
import 'widgets/load_error_view.dart';
import 'widgets/place_photo.dart';

/// D1. Hasil Itinerary - Figma Mockup, node 85:3569 (US4): the generated
/// day-by-day plan with a source badge per stop.
class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _selectedDayNumber = 1;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final tripState = ref.watch(tripDetailProvider(widget.tripsId));

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      appBar: ScreenHeader(subtitle: l10n.itineraryHeader, onBack: _leave),
      body: tripState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(tripDetailProvider(widget.tripsId)),
        ),
        data: (trip) => _buildTrip(trip, l10n),
      ),
    );
  }

  Widget _buildTrip(Trip trip, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final languageCode = Localizations.localeOf(context).languageCode;
    final flags = ref.watch(generatedFlagsProvider(widget.tripsId));

    if (trip.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, size: 56, color: tokens.link),
              const SizedBox(height: 12),
              Text(l10n.itineraryEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.itineraryGenerateNow,
                onPressed: () => context.push(AppRoutes.tripGenerate(trip.tripsId)),
              ),
            ],
          ),
        ),
      );
    }

    final day = trip.days.firstWhere(
      (day) => day.dayNumber == _selectedDayNumber,
      orElse: () => trip.days.first,
    );
    final dayFlags = flags?.dayFlags[day.dayNumber];
    final shortDate = DateFormat('d MMM', languageCode);
    final longDate = DateFormat('d MMM y', languageCode);
    final endDate = trip.dateOfDay(trip.numDays);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(tripDetailProvider(widget.tripsId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: tokens.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${longDate.format(trip.startDate)} - ${longDate.format(endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: trip.days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final tabDay = trip.days[index];
                    final isSelected = tabDay.dayNumber == day.dayNumber;
                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: isSelected
                          ? const Icon(Icons.calendar_month, size: 14, color: Colors.white)
                          : null,
                      label: Text(
                        l10n.itineraryDayTab(tabDay.dayNumber, shortDate.format(trip.dateOfDay(tabDay.dayNumber))),
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? Colors.white : null,
                      ),
                      selectedColor: tokens.accent,
                      backgroundColor: tokens.accentSoft,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _selectedDayNumber = tabDay.dayNumber),
                    );
                  },
                ),
              ),
              if (flags != null && flags.droppedWishlistCount > 0)
                _NoticeBanner(text: l10n.itineraryDroppedWishlist(flags.droppedWishlistCount)),
              if (dayFlags?.isOverpacked == true) _NoticeBanner(text: l10n.itineraryOverpacked),
              if (dayFlags?.isShortOfPlaces == true) _NoticeBanner(text: l10n.itineraryShortOfPlaces),
              if (trip.hotel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.hotel_outlined, size: 16, color: tokens.link),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.itineraryStartFrom(trip.hotel!.name),
                          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: day.items.isEmpty
                    ? Text(l10n.itineraryDayEmpty, style: theme.textTheme.bodyMedium)
                    : _Timeline(day: day, hotel: trip.hotel),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius),
                boxShadow: const [
                  BoxShadow(color: Color(0x4D1C6FB0), blurRadius: 14, offset: Offset(0, 10)),
                ],
              ),
              child: FilledButton.icon(
                onPressed: day.items.isEmpty
                    ? null
                    : () => context.push(AppRoutes.liveMap(trip.tripsId, day.dayNumber)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: tokens.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.itineraryOpenMap),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.amberFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: tokens.onAmber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tokens.onAmber),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.day, required this.hotel});

  final ItineraryDay day;
  final TripHotel? hotel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final children = <Widget>[];

    for (var i = 0; i < day.items.length; i++) {
      final item = day.items[i];
      final previous = i == 0 ? null : day.items[i - 1].place;
      final place = item.place;

      if (previous != null && place != null) {
        final km = haversineKm(previous.lat, previous.lng, place.lat, place.lng);
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 14, color: tokens.textSecondary),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.chipFill,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  l10n.itineraryDistance(km.toStringAsFixed(1)),
                  style: theme.textTheme.labelSmall?.copyWith(color: tokens.textSecondary),
                ),
              ),
            ],
          ),
        ));
      }

      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _StopRow(item: item),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final place = item.place;
    final minutes = place?.estimatedVisitMinutes;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.isVisited ? tokens.successFill : const Color(0xFF0B1C30),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: tokens.screenBackground, spreadRadius: 4)],
          ),
          child: item.isVisited
              ? Icon(Icons.done_all, size: 16, color: tokens.onSuccess)
              : Text(
                  '${item.visitOrder}',
                  style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 80, height: 80, child: PlacePhoto(url: place?.photoUrl)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SourceBadge(isFromWishlist: item.isFromWishlist),
                      const SizedBox(height: 4),
                      Text(
                        place?.name ?? l10n.itineraryUnknownPlace,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (minutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: tokens.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.itineraryVisitMinutes(minutes),
                                  style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          if (item.isVisited)
                            Text(
                              l10n.itineraryVisited,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.onSuccess,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isFromWishlist});

  final bool isFromWishlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final foreground = isFromWishlist ? tokens.onAmber : const Color(0xFF42607E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFromWishlist ? tokens.amberFill : tokens.badgeFill,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFromWishlist) ...[
            Icon(Icons.favorite, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            isFromWishlist ? l10n.itineraryFromWishlist : l10n.itineraryRecommended,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
