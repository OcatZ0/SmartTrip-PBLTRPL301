import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/polyline_codec.dart';
import '../../services/trip_service.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';

enum MemberRole { editor, viewer }

class TripMember {
  final String name;
  final String email;
  final MemberRole role;

  const TripMember({
    required this.name,
    required this.email,
    required this.role,
  });
}

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
  final List<TripMember> _members = [];

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  void _showShareSheet(int tripsId) {
    final link = 'https://smarttrip.app/share/$tripsId';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareItinerarySheet(link: link),
    );
  }

  void _showInviteSheet() {
    final emailCtrl = TextEditingController();
    final tokens = context.tokens;
    MemberRole role = MemberRole.viewer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // supaya naik saat keyboard muncul
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Undang ke Itinerary',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email teman',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<MemberRole>(
                segments: const [
                  ButtonSegment(
                    value: MemberRole.viewer,
                    label: Text('Viewer'),
                  ),
                  ButtonSegment(
                    value: MemberRole.editor,
                    label: Text('Editor'),
                  ),
                ],
                selected: {role},
                onSelectionChanged: (s) => setSheetState(() => role = s.first),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: tokens.accent),
                  onPressed: () {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty || !email.contains('@')) return;
                    setState(() {
                      _members.add(
                        TripMember(
                          name: email.split('@').first,
                          email: email,
                          role: role,
                        ),
                      );
                    });
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Undangan dikirim ke $email')),
                    );
                  },
                  child: const Text('Kirim Undangan'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(emailCtrl.dispose);
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
              Text(
                l10n.itineraryEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.itineraryGenerateNow,
                onPressed: () =>
                    context.push(AppRoutes.tripGenerate(trip.tripsId)),
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
          onRefresh: () =>
              ref.read(tripDetailProvider(widget.tripsId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 22,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: tokens.textSecondary,
                          ),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'share') _showShareSheet(trip.tripsId);
                            if (value == 'invite') _showInviteSheet();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    size: 18,
                                    color: tokens.accent,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Bagikan Itinerary'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'invite',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_add_alt_outlined,
                                    size: 18,
                                    color: tokens.accent,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Undang ke Itinerary'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${longDate.format(trip.startDate)} - ${longDate.format(endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  itemCount: trip.days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final tabDay = trip.days[index];
                    final isSelected = tabDay.dayNumber == day.dayNumber;
                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: isSelected
                          ? const Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                      label: Text(
                        l10n.itineraryDayTab(
                          tabDay.dayNumber,
                          shortDate.format(trip.dateOfDay(tabDay.dayNumber)),
                        ),
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? Colors.white : null,
                      ),
                      selectedColor: tokens.accent,
                      backgroundColor: tokens.accentSoft,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) =>
                          setState(() => _selectedDayNumber = tabDay.dayNumber),
                    );
                  },
                ),
              ),
              if (flags != null && flags.droppedWishlistCount > 0)
                _NoticeBanner(
                  text: l10n.itineraryDroppedWishlist(
                    flags.droppedWishlistCount,
                  ),
                ),
              if (flags != null && flags.closedWishlistCount > 0)
                _NoticeBanner(
                  text: l10n.itineraryClosedWishlist(flags.closedWishlistCount),
                ),
              if (dayFlags?.isOverpacked == true)
                _NoticeBanner(text: l10n.itineraryOverpacked),
              if (dayFlags?.isShortOfPlaces == true)
                _NoticeBanner(text: l10n.itineraryShortOfPlaces),
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: day.items.isEmpty
                    ? Text(
                        l10n.itineraryDayEmpty,
                        style: theme.textTheme.bodyMedium,
                      )
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
                  BoxShadow(
                    color: Color(0x4D1C6FB0),
                    blurRadius: 14,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: day.items.isEmpty
                    ? null
                    : () => context.push(
                        AppRoutes.liveMap(trip.tripsId, day.dayNumber),
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: tokens.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                  ),
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
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tokens.onAmber),
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
        final km = haversineKm(
          previous.lat,
          previous.lng,
          place.lat,
          place.lng,
        );
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 14,
                  color: tokens.textSecondary,
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.chipFill,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    l10n.itineraryDistance(km.toStringAsFixed(1)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StopRow(item: item),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
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
            color: item.isVisited
                ? tokens.successFill
                : const Color(0xFF0B1C30),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: tokens.screenBackground, spreadRadius: 4),
            ],
          ),
          child: item.isVisited
              ? Icon(Icons.done_all, size: 16, color: tokens.onSuccess)
              : Text(
                  '${item.visitOrder}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: PlacePhoto(url: place?.photoUrl),
                  ),
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
                                Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: tokens.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.itineraryVisitMinutes(minutes),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
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
    final foreground = isFromWishlist
        ? tokens.onAmber
        : const Color(0xFF42607E);

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
            isFromWishlist
                ? l10n.itineraryFromWishlist
                : l10n.itineraryRecommended,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _ShareItinerarySheet extends StatelessWidget {
  const _ShareItinerarySheet({required this.link});

  final String link;

  Future<void> _copyLink(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(ClipboardData(text: link));

    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Link disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bagikan Itinerary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Siapa pun dengan link ini bisa melihat (read-only).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.chipFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () => _copyLink(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Share.share('Lihat itinerary saya: $link'),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Bagikan ke aplikasi lain'),
              style: FilledButton.styleFrom(backgroundColor: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}
