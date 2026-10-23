import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/saved_trip.dart' show TripModel;
import '../../models/trip.dart';
import '../../models/weather.dart';
import '../../services/polyline_codec.dart';
import '../../services/trip_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/busy_overlay.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import 'swap_place_screen.dart';
import 'widgets/setup_card.dart';
import 'widgets/day_point_sheet.dart';
import 'widgets/source_badge.dart';
import 'widgets/stop_detail_sheet.dart';

enum MemberRole { editor, viewer }

class TripMember {
  final String name;
  final String email;
  final MemberRole role;

  const TripMember({required this.name, required this.email, required this.role});
}

/// Rain colours shared by the weather card, the rain badge and the notices.
const _rainFill = Color(0xFFFFF4E5);
const _rainText = Color(0xFF8A4B00);

/// D1. Hasil Itinerary (US4): a navy summary card of the trip, the day
/// picker, that day's weather and notices, and the stops on a timeline that
/// starts at the hotel. The bottom bar opens the live map of the day.
class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _selectedDayNumber = 1;
  final List<TripMember> _members = [];
  bool _reminderScheduled = false;

  @override
  void initState() {
    super.initState();
    // Once per screen: a changed start date is picked up the next time.
    ref.listenManual(tripDetailProvider(widget.tripsId), (_, next) {
      final trip = next.valueOrNull;
      if (trip == null || !trip.hasStops || _reminderScheduled) return;
      _reminderScheduled = true;
      _scheduleReminders(trip);
    }, fireImmediately: true);
  }

  /// Half an hour before each day starts, so there is time to get going.
  static const _dayReminderLead = Duration(minutes: 30);

  Future<void> _scheduleReminders(Trip trip) async {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.read(localNotificationServiceProvider);
    final start = trip.dailyStartTime.split(':');
    final hour = int.tryParse(start.first) ?? 9;
    final minute = start.length > 1 ? int.tryParse(start[1]) ?? 0 : 0;
    final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    try {
      await notifications.scheduleDayReminders(
        tripsId: trip.tripsId,
        days: [
          for (final day in trip.days)
            if (day.items.isNotEmpty)
              (
                at: trip
                    .dateOfDay(day.dayNumber)
                    .add(Duration(hours: hour, minutes: minute))
                    .subtract(_dayReminderLead),
                title: l10n.dayReminderTitle(trip.title, day.dayNumber),
                body: l10n.dayReminderBody(
                  day.items.length,
                  day.items.first.place?.name ?? l10n.itineraryUnknownPlace,
                  time,
                ),
              ),
        ],
        channelName: l10n.dayReminderChannel,
        channelDescription: l10n.dayReminderChannelDescription,
      );
      await notifications.scheduleWeatherReminder(
        tripsId: trip.tripsId,
        startDate: trip.startDate,
        title: l10n.weatherReminderTitle(trip.title),
        body: l10n.weatherReminderBody,
        channelName: l10n.weatherReminderChannel,
        channelDescription: l10n.weatherReminderChannelDescription,
      );
    } catch (_) {
      // A reminder that cannot be scheduled must not break the itinerary.
    }
  }

  /// The stop's ⋮ menu; its "Ganti Lokasi Wisata" opens the swap page.
  Future<void> _openStop(ItineraryDay day, ItineraryItem item, {required bool rainy}) async {
    final index = day.items.indexOf(item);
    final wantsSwap = await StopDetailSheet.show(
      context,
      item: item,
      previous: index > 0 ? day.items[index - 1].place : null,
    );
    if (wantsSwap != true || !mounted) return;
    await _swapPlace(item, dayNumber: day.dayNumber, preferIndoor: rainy);
  }

  Future<void> _swapPlace(ItineraryItem item, {required int dayNumber, bool preferIndoor = false}) async {
    // The stops around it (the hotel at either end) tell the swap page how
    // each replacement changes the day's route.
    final trip = ref.read(tripDetailProvider(widget.tripsId)).valueOrNull;
    final items = [
      for (final day in trip?.days ?? const <ItineraryDay>[])
        if (day.dayNumber == dayNumber) ...day.items,
    ];
    final index = items.indexOf(item);
    final day = trip?.days.where((day) => day.dayNumber == dayNumber).firstOrNull;
    TripPlace? stopAt(TripHotel? point) =>
        point == null ? null : TripPlace(placesId: null, name: point.name, type: 'lodging', lat: point.lat, lng: point.lng);

    final place = await SwapPlaceScreen.show(
      context,
      item,
      preferIndoor: preferIndoor,
      dayNumber: dayNumber,
      previous: index > 0 ? items[index - 1].place : stopAt(day?.start),
      next: index >= 0 && index < items.length - 1 ? items[index + 1].place : stopAt(day?.end),
    );
    final placesId = place?.placesId;
    if (place == null || placesId == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BusyOverlay.run(
        context,
        title: l10n.swapBusyTitle,
        message: l10n.swapBusyMessage(place.name, dayNumber),
        task: () async {
          await ref.read(tripServiceProvider).swapItineraryItem(item.itineraryItemsId, placesId);
          await ref.read(tripDetailProvider(widget.tripsId).notifier).refresh();
        },
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.swapDone(place.name))));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    }
  }

  /// Where [day] starts ([isStart]) or ends. The server recomputes the
  /// day's route; its places stay.
  Future<void> _changeDayPoint(ItineraryDay day, {required bool isStart}) async {
    final l10n = AppLocalizations.of(context);
    final trip = ref.read(tripDetailProvider(widget.tripsId)).valueOrNull;
    final mainHotel = trip?.hotel;
    final pick = await DayPointSheet.show(
      context,
      title: isStart ? l10n.dayPointStartTitle(day.dayNumber) : l10n.dayPointEndTitle(day.dayNumber),
      defaultLabel: isStart ? l10n.dayPointMainHotel : l10n.dayPointSameAsStart,
      defaultCaption: isStart ? l10n.dayPointMainHotelCaption(mainHotel?.name ?? '-') : l10n.dayPointSameAsStartCaption,
      isDefault: isStart ? day.start?.placesId == mainHotel?.placesId && day.start?.name == mainHotel?.name : !day.hasOwnEnd,
    );
    if (pick == null || !mounted) return;

    final Map<String, dynamic>? point = switch (pick) {
      DefaultDayPoint() => isStart ? mainHotel?.toPointJson() : null,
      ChosenDayPoint(:final choice) => choice.asPoint.toPointJson(),
    };
    if (isStart && point == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // The server recomputes the day's route; that takes a moment, so the
      // whole screen waits with a clear message instead of looking idle.
      await BusyOverlay.run(
        context,
        title: l10n.dayPointBusyTitle,
        message: isStart ? l10n.dayPointBusyStart(day.dayNumber) : l10n.dayPointBusyEnd(day.dayNumber),
        task: () async {
          await ref.read(tripServiceProvider).setDayPoints(
                widget.tripsId,
                day.dayNumber,
                start: isStart ? point : null,
                end: isStart ? null : point,
                resetEnd: !isStart && point == null,
              );
          await ref.read(tripDetailProvider(widget.tripsId).notifier).refresh();
        },
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.dayPointSaved(day.dayNumber))));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    }
  }

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
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ShareItinerarySheet(link: link),
    );
  }

  void _showInviteSheet() {
    final emailCtrl = TextEditingController();
    MemberRole role = MemberRole.viewer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // supaya naik saat keyboard muncul
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Undang ke Itinerary', style: appText(18, FontWeight.w800, AppColors.ink, height: 24)),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: appText(14, FontWeight.w600, AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Email teman',
                  hintStyle: appText(14, FontWeight.w500, AppColors.inkMuted),
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.inkMuted),
                  filled: true,
                  fillColor: AppColors.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<MemberRole>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.sea600,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                ),
                segments: const [
                  ButtonSegment(value: MemberRole.viewer, label: Text('Viewer')),
                  ButtonSegment(value: MemberRole.editor, label: Text('Editor')),
                ],
                selected: {role},
                onSelectionChanged: (s) => setSheetState(() => role = s.first),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Kirim Undangan',
                onPressed: () {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty || !email.contains('@')) return;
                  setState(() {
                    _members.add(TripMember(name: email.split('@').first, email: email, role: role));
                  });
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Undangan dikirim ke $email')));
                },
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
    final tripState = ref.watch(tripDetailProvider(widget.tripsId));
    final trip = tripState.valueOrNull;
    final day = trip == null || trip.days.isEmpty ? null : _selectedDay(trip);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ScreenHeader(
        subtitle: l10n.itineraryHeader,
        onBack: _leave,
        trailing: trip == null
            ? null
            : _TripMenu(onShare: () => _showShareSheet(trip.tripsId), onInvite: _showInviteSheet),
      ),
      bottomNavigationBar: trip == null || day == null
          ? null
          : BottomActionBar(
              child: PrimaryButton(
                label: l10n.itineraryOpenMap,
                trailingIcon: Icons.map_outlined,
                onPressed: day.items.isEmpty
                    ? null
                    : () => context.push(AppRoutes.liveMap(trip.tripsId, day.dayNumber)),
              ),
            ),
      body: tripState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sea600)),
        error: (error, _) => LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(tripDetailProvider(widget.tripsId)),
        ),
        data: (trip) => _buildTrip(trip, l10n),
      ),
    );
  }

  ItineraryDay _selectedDay(Trip trip) {
    return trip.days.firstWhere((day) => day.dayNumber == _selectedDayNumber, orElse: () => trip.days.first);
  }

  Widget _buildTrip(Trip trip, AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final flags = ref.watch(generatedFlagsProvider(widget.tripsId));

    // The day rows exist from the start; no stops yet means no itinerary.
    if (!trip.hasStops) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.field, shape: BoxShape.circle),
                child: const Icon(Icons.route_outlined, size: 34, color: AppColors.sea600),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.itineraryEmpty,
                textAlign: TextAlign.center,
                style: appText(14, FontWeight.w600, AppColors.inkMuted, height: 20),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: l10n.itineraryGenerateNow,
                trailingIcon: Icons.auto_awesome_rounded,
                onPressed: () => context.push(AppRoutes.tripGenerate(trip.tripsId)),
              ),
            ],
          ),
        ),
      );
    }

    final day = _selectedDay(trip);
    final dayFlags = flags?.dayFlags[day.dayNumber];
    final forecast = ref
        .watch(tripForecastProvider(widget.tripsId))
        .valueOrNull?[DateUtils.dateOnly(trip.dateOfDay(day.dayNumber))];
    final rainy = forecast?.isRainy ?? false;
    final outdoorStops = [
      for (final item in day.items)
        if (item.place?.isOutdoor == true && !item.isVisited) item,
    ];
    final notices = [
      if (flags != null && flags.droppedWishlistCount > 0) l10n.itineraryDroppedWishlist(flags.droppedWishlistCount),
      if (flags != null && flags.closedWishlistCount > 0) l10n.itineraryClosedWishlist(flags.closedWishlistCount),
      if (dayFlags?.isOverpacked == true) l10n.itineraryOverpacked,
      if (dayFlags?.isShortOfPlaces == true) l10n.itineraryShortOfPlaces,
    ];
    final dayMinutes = day.items.fold<int>(0, (sum, item) => sum + (item.place?.estimatedVisitMinutes ?? 0));

    return RefreshIndicator(
      color: AppColors.sea600,
      onRefresh: () => ref.read(tripDetailProvider(widget.tripsId).notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _TripSummaryCard(trip: trip, languageCode: languageCode),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trip.days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tabDay = trip.days[index];
                return _DayTab(
                  label: l10n.itineraryDayShort(tabDay.dayNumber),
                  date: DateFormat('EEE, d MMM', languageCode).format(trip.dateOfDay(tabDay.dayNumber)),
                  semanticsLabel: l10n.itineraryDayTab(
                    tabDay.dayNumber,
                    DateFormat('d MMM', languageCode).format(trip.dateOfDay(tabDay.dayNumber)),
                  ),
                  selected: tabDay.dayNumber == day.dayNumber,
                  onTap: () => setState(() => _selectedDayNumber = tabDay.dayNumber),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM', languageCode).format(trip.dateOfDay(day.dayNumber)),
                    style: appText(17, FontWeight.w800, AppColors.ink, height: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  [
                    l10n.itineraryStopsCount(day.items.length),
                    if (dayMinutes > 0) l10n.tripWishlistHours(_hours(dayMinutes)),
                  ].join(' · '),
                  style: appText(12, FontWeight.w600, AppColors.inkMuted, height: 18),
                ),
              ],
            ),
          ),
          if (forecast != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _WeatherCard(forecast: forecast, outdoorStops: rainy ? outdoorStops.length : 0),
            ),
          for (final notice in notices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _NoticeBanner(text: notice),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: day.items.isEmpty
                ? SetupCard(
                    child: Text(
                      l10n.itineraryDayEmpty,
                      textAlign: TextAlign.center,
                      style: appText(13, FontWeight.w600, AppColors.inkMuted, height: 18),
                    ),
                  )
                : _Timeline(
                    day: day,
                    onChangeStart: () => _changeDayPoint(day, isStart: true),
                    onChangeEnd: () => _changeDayPoint(day, isStart: false),
                    onOpenStop: (item) => _openStop(day, item, rainy: rainy),
                    onSwapForRain: rainy
                        ? (item) => _swapPlace(item, dayNumber: day.dayNumber, preferIndoor: true)
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  /// "4", "4,5" (one decimal only when needed, Indonesian comma).
  static String _hours(int minutes) {
    final rounded = (minutes / 60 * 2).round() / 2;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1).replaceAll('.', ',');
  }
}

/// The ⋮ menu in the navy header: share the itinerary or invite someone.
class _TripMenu extends StatelessWidget {
  const _TripMenu({required this.onShare, required this.onInvite});

  final VoidCallback onShare;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<String> item(String value, IconData icon, String label) {
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.sea600),
            const SizedBox(width: 12),
            Text(label, style: appText(14, FontWeight.w600, AppColors.ink)),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'share') onShare();
        if (value == 'invite') onInvite();
      },
      itemBuilder: (_) => [
        item('share', Icons.share_outlined, 'Bagikan Itinerary'),
        item('invite', Icons.person_add_alt_outlined, 'Undang ke Itinerary'),
      ],
    );
  }
}

/// Navy card on top: title, dates, and the trip's days, budget, daily hours
/// and hotel.
class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.trip, required this.languageCode});

  final Trip trip;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat('d MMM y', languageCode);
    final stops = trip.days.fold<int>(0, (sum, day) => sum + day.items.length);
    // "09:00:00" from the API reads as "09:00".
    String hhmm(String time) => time.length > 5 ? time.substring(0, 5) : time;
    final hours = '${hhmm(trip.dailyStartTime)}–${hhmm(trip.dailyEndTime)}';

    Widget stat(IconData icon, String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.sun400),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(13, FontWeight.w800, Colors.white, height: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: appText(10.5, FontWeight.w600, Colors.white.withValues(alpha: 0.6), height: 14)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy700, AppColors.navy900],
        ),
        boxShadow: AppColors.floatShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appText(20, FontWeight.w800, Colors.white, height: 26, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                '${date.format(trip.startDate)} – ${date.format(trip.dateOfDay(trip.numDays))}',
                style: appText(12.5, FontWeight.w600, Colors.white.withValues(alpha: 0.75), height: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                stat(Icons.calendar_month_outlined, l10n.tripDays(trip.numDays), l10n.tripSummaryDuration),
                stat(Icons.place_outlined, '$stops', l10n.tripWishlistSummaryPlaces),
                stat(
                  Icons.account_balance_wallet_outlined,
                  TripModel.rupiahFormat(trip.budgetTotal),
                  l10n.tripSummaryBudget,
                ),
              ],
            ),
          ),
          if (trip.hotel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.hotel_rounded, size: 15, color: AppColors.sun400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.itineraryStartFrom(trip.hotel!.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(12.5, FontWeight.w600, Colors.white, height: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.schedule_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(hours, style: appText(12, FontWeight.w600, Colors.white.withValues(alpha: 0.75), height: 18)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A day in the horizontal day picker: "Hari 1" over the date, navy once picked.
class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.label,
    required this.date,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String date;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.navy900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.navy900 : AppColors.line),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 84),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: appText(13, FontWeight.w800, selected ? Colors.white : AppColors.ink, height: 18)),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: appText(11, FontWeight.w600, selected ? AppColors.sun400 : AppColors.inkMuted, height: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _rainFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sun400.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 17, color: _rainText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: appText(12, FontWeight.w600, _rainText, height: 17))),
        ],
      ),
    );
  }
}

/// The day's stops on a vertical line: the hotel first (when there is one),
/// then each stop with the distance from the one before.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.day,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.onOpenStop,
    this.onSwapForRain,
  });

  final ItineraryDay day;
  final VoidCallback onChangeStart;
  final VoidCallback onChangeEnd;

  /// The button on a stop card: opens its detail sheet.
  final ValueChanged<ItineraryItem> onOpenStop;

  /// Set on a day with rain in the forecast: outdoor stops get a badge that
  /// opens Ganti Tempat with indoor places first (F025).
  final ValueChanged<ItineraryItem>? onSwapForRain;

  static const _railWidth = 34.0;

  /// One row of the timeline: [marker] on the rail, [child] beside it.
  Widget _entry({required Widget marker, required Widget child, bool lineAbove = true, bool lineBelow = true}) {
    Widget line(bool visible) =>
        Expanded(child: Container(width: 2, color: visible ? AppColors.line : Colors.transparent));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                SizedBox(
                  height: 14,
                  child: Center(child: Container(width: 2, color: lineAbove ? AppColors.line : Colors.transparent)),
                ),
                marker,
                line(lineBelow),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final children = <Widget>[];
    final start = day.start;
    final end = day.end;

    // The day's start and end on the rail, in sun, each with a Ganti button.
    Widget point({required IconData icon, required String text, required VoidCallback onChange, bool lineAbove = true, bool lineBelow = true}) {
      return _entry(
        lineAbove: lineAbove,
        lineBelow: lineBelow,
        marker: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.sun400, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: AppColors.navy900),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: lineBelow ? 8 : 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(13, FontWeight.w700, AppColors.ink, height: 18),
                ),
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.sea600,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.dayPointChange, style: appText(12.5, FontWeight.w700, AppColors.sea600)),
              ),
            ],
          ),
        ),
      );
    }

    if (start != null) {
      children.add(point(icon: Icons.hotel_rounded, text: l10n.itineraryStartFrom(start.name), onChange: onChangeStart, lineAbove: false));
    }

    for (var i = 0; i < day.items.length; i++) {
      final item = day.items[i];
      final previous = i == 0 ? null : day.items[i - 1].place;
      final place = item.place;
      final isFirst = children.isEmpty;
      final isLast = i == day.items.length - 1;

      String? distance;
      if (previous != null && place != null) {
        final km = haversineKm(previous.lat, previous.lng, place.lat, place.lng);
        distance = l10n.itineraryDistance(km.toStringAsFixed(1));
      }

      children.add(
        _entry(
          lineAbove: !isFirst,
          lineBelow: !isLast || end != null,
          marker: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.isVisited ? AppColors.sea600 : AppColors.navy900,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
            ),
            child: item.isVisited
                ? const Icon(Icons.done_all_rounded, size: 14, color: Colors.white)
                : Text('${item.visitOrder}', style: appText(12, FontWeight.w800, Colors.white)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast && end == null ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (distance != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car_outlined, size: 13, color: AppColors.inkMuted),
                          const SizedBox(width: 5),
                          Text(distance, style: appText(11, FontWeight.w600, AppColors.inkMuted, height: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _StopCard(
                  item: item,
                  onOpen: () => onOpenStop(item),
                  onSwapForRain: onSwapForRain != null && place?.isOutdoor == true && !item.isVisited
                      ? () => onSwapForRain!(item)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (end != null) {
      children.add(point(
        icon: day.hasOwnEnd ? Icons.flag_rounded : Icons.hotel_rounded,
        text: l10n.dayPointEndAt(end.name),
        onChange: onChangeEnd,
        lineBelow: false,
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.item, required this.onOpen, this.onSwapForRain});

  final ItineraryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onSwapForRain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final place = item.place;
    final minutes = place?.estimatedVisitMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Opacity(
                      opacity: item.isVisited ? 0.55 : 1,
                      child: PlacePhoto(url: place?.photoUrl),
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
                      Padding(
                        // Clear of the detail button in the corner.
                        padding: const EdgeInsets.only(right: 30),
                        child: Text(
                          place?.name ?? l10n.itineraryUnknownPlace,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: appText(14.5, FontWeight.w800, AppColors.ink, height: 19),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (minutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 13, color: AppColors.inkMuted),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.itineraryVisitMinutes(minutes),
                                  style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                                ),
                              ],
                            ),
                          if (item.isVisited)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.sea600),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.itineraryVisited,
                                  style: appText(12, FontWeight.w700, AppColors.sea600, height: 16),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (onSwapForRain != null) ...[const SizedBox(height: 6), _RainBadge(onTap: onSwapForRain!)],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: IconButton(
              tooltip: l10n.placeSheetTooltip,
              onPressed: onOpen,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected day's forecast. On a rainy day with outdoor stops it also
/// says so; each of those stops carries its own swap badge.
class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.forecast, required this.outdoorStops});

  final DayForecast forecast;
  final int outdoorStops;

  static IconData icon(int code) {
    if (code >= 95) return Icons.thunderstorm_outlined;
    if (DayForecast.isRainCode(code)) return Icons.water_drop_outlined;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 1 && code <= 3) return Icons.cloud_outlined;
    return Icons.wb_sunny_outlined;
  }

  static String label(int code, AppLocalizations l10n) {
    if (code >= 95) return l10n.weatherThunderstorm;
    if (DayForecast.isRainCode(code)) return l10n.weatherRain;
    if (code >= 45 && code <= 48) return l10n.weatherFog;
    if (code >= 1 && code <= 3) return l10n.weatherCloudy;
    return l10n.weatherClear;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final warn = forecast.isRainy && outdoorStops > 0;
    final accent = warn ? _rainText : AppColors.sea600;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warn ? _rainFill : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: warn ? Border.all(color: AppColors.sun400.withValues(alpha: 0.4)) : null,
        boxShadow: warn ? null : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: warn ? Colors.white.withValues(alpha: 0.7) : AppColors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon(forecast.weatherCode), size: 22, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label(forecast.weatherCode, l10n),
                      style: appText(14, FontWeight.w800, AppColors.ink, height: 19),
                    ),
                    Text(
                      l10n.weatherSummary(
                        forecast.minTemperature.round(),
                        forecast.maxTemperature.round(),
                        forecast.rainChance,
                      ),
                      style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 17),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warn) ...[
            const SizedBox(height: 10),
            Text(l10n.weatherRainWarning(outdoorStops), style: appText(12, FontWeight.w600, _rainText, height: 17)),
          ],
        ],
      ),
    );
  }
}

class _RainBadge extends StatelessWidget {
  const _RainBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: _rainFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_outlined, size: 13, color: _rainText),
              const SizedBox(width: 4),
              Text(l10n.weatherRainBadge, style: appText(11, FontWeight.w800, _rainText, height: 15)),
            ],
          ),
        ),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bagikan Itinerary', style: appText(18, FontWeight.w800, AppColors.ink, height: 24)),
            const SizedBox(height: 4),
            Text(
              'Siapa pun dengan link ini bisa melihat (read-only).',
              style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 18),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 18, color: AppColors.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(13, FontWeight.w600, AppColors.ink),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.sea600),
                    onPressed: () => _copyLink(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Bagikan ke aplikasi lain',
              trailingIcon: Icons.share_outlined,
              onPressed: () => Share.share('Lihat itinerary saya: $link'),
            ),
          ],
        ),
      ),
    );
  }
}
