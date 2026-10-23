import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rupiah_input_formatter.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_pill.dart';
import 'widgets/setup_card.dart';

/// C1. Atur Trip - Figma Mockup, node 85:2541 (US2).
class TripSetupScreen extends ConsumerStatefulWidget {
  const TripSetupScreen({super.key});

  @override
  ConsumerState<TripSetupScreen> createState() => _TripSetupScreenState();
}

enum _BudgetTier { economy, standard, premium }

class _TripSetupScreenState extends ConsumerState<TripSetupScreen> {
  /// Design spec Section 4: more than 7 days is allowed, only warned about.
  static const _softMaxDays = 7;
  static const _tierPresets = {
    _BudgetTier.economy: 750000,
    _BudgetTier.standard: 1500000,
    _BudgetTier.premium: 3000000,
  };
  static const _tierIcons = {
    _BudgetTier.economy: Icons.savings_outlined,
    _BudgetTier.standard: Icons.account_balance_wallet_outlined,
    _BudgetTier.premium: Icons.diamond_outlined,
  };

  /// The three suggested day lengths, start and end.
  static const _paces = [
    (TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 17, minute: 0)),
    (TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 19, minute: 0)),
    (TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 21, minute: 0)),
  ];

  final _budgetController =
      TextEditingController(text: RupiahInputFormatter.format(1500000));
  final _titleController = TextEditingController();

  /// The name follows the dates until the user types their own.
  bool _titleEdited = false;

  int _numDays = 3;
  DateTime _startDate = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));

  /// After the first tap on the calendar, the next tap picks the last day.
  bool _awaitingEnd = false;
  TimeOfDay _dailyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _dailyEnd = const TimeOfDay(hour: 19, minute: 0);
  String? _budgetError;
  String? _timeError;

  @override
  void dispose() {
    _budgetController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  int? get _budget => RupiahInputFormatter.parse(_budgetController.text);

  DateTime get _endDate => _startDate.add(Duration(days: _numDays - 1));

  _BudgetTier? get _selectedTier {
    final budget = _budget;
    if (budget == null || budget <= 0) return null;
    if (budget < 1000000) return _BudgetTier.economy;
    if (budget <= 2500000) return _BudgetTier.standard;
    return _BudgetTier.premium;
  }

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// "Trip Batam 12–14 Sep", "Trip Batam 30 Sep – 2 Okt" or "Trip Batam 12 Sep".
  String _defaultTitle(AppLocalizations l10n, String languageCode) {
    final dayMonth = DateFormat('d MMM', languageCode);
    final start = _startDate;
    final end = _endDate;
    final dates = start == end
        ? dayMonth.format(start)
        : start.month == end.month
            ? '${start.day}–${dayMonth.format(end)}'
            : '${dayMonth.format(start)} – ${dayMonth.format(end)}';
    return l10n.tripNameDefault(dates);
  }

  /// Keeps the suggested name in step with the dates.
  void _syncTitle() {
    if (_titleEdited || !mounted) return;
    final l10n = AppLocalizations.of(context);
    _titleController.text = _defaultTitle(l10n, Localizations.localeOf(context).languageCode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTitle();
  }

  void _submit(AppLocalizations l10n) {
    final budget = _budget;
    final hasValidBudget = budget != null && budget > 0;
    final hasValidTimes = _minutes(_dailyEnd) > _minutes(_dailyStart);

    setState(() {
      _budgetError = hasValidBudget ? null : l10n.validationBudgetRequired;
      _timeError = hasValidTimes ? null : l10n.validationEndTimeAfterStart;
    });
    if (!hasValidBudget || !hasValidTimes) return;

    final typed = _titleController.text.trim();
    ref.read(tripSetupControllerProvider.notifier).submit(
          title: typed.isEmpty ? _defaultTitle(l10n, Localizations.localeOf(context).languageCode) : typed,
          numDays: _numDays,
          budgetTotal: budget,
          startDate: _startDate,
          dailyStartTime: _formatTime(_dailyStart),
          dailyEndTime: _formatTime(_dailyEnd),
        );
  }

  /// First tap: a new start (a one-day trip until the second tap). Second
  /// tap on or after it: the last day. Earlier than the start: a new start.
  /// Dragging across the calendar: the days between where the finger went
  /// down and where it is now, in either direction.
  void _dragDays(DateTime from, DateTime to) {
    final first = from.isBefore(to) ? from : to;
    final last = from.isBefore(to) ? to : from;
    setState(() {
      _startDate = first;
      _numDays = last.difference(first).inDays + 1;
      _awaitingEnd = false;
    });
    _syncTitle();
  }

  void _pickDay(DateTime day) {
    setState(() {
      if (_awaitingEnd && !day.isBefore(_startDate)) {
        _numDays = day.difference(_startDate).inDays + 1;
        _awaitingEnd = false;
      } else {
        _startDate = day;
        _numDays = 1;
        _awaitingEnd = true;
      }
    });
    _syncTitle();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _dailyStart : _dailyEnd,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _dailyStart = picked;
      } else {
        _dailyEnd = picked;
      }
      _timeError = null;
    });
  }

  Future<void> _confirmLeave(AppLocalizations l10n) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tripCancelTitle),
        content: Text(l10n.tripCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.tripCancelStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tripCancelConfirm),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.catalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setupState = ref.watch(tripSetupControllerProvider);

    ref.listen(tripSetupControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;

      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(tripErrorMessage(next.error!, l10n))));
        return;
      }

      final tripId = next.valueOrNull;
      if (tripId != null) context.push(AppRoutes.tripWishlist(tripId));
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(l10n);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: ScreenHeader(
          subtitle: l10n.tripSetupHeader,
          onBack: () => _confirmLeave(l10n),
          trailing: StepPill(step: 1, total: 4, label: l10n.tripStepLabel(1, 4, l10n.tripSetupHeader)),
        ),
        bottomNavigationBar: BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SetupSummary(
                items: [
                  (Icons.calendar_month_outlined, l10n.tripDays(_numDays), l10n.tripSummaryDuration),
                  (
                    Icons.schedule_rounded,
                    '${_formatTime(_dailyStart)}–${_formatTime(_dailyEnd)}',
                    l10n.tripSummaryHours,
                  ),
                  (
                    Icons.account_balance_wallet_outlined,
                    switch (_budget) {
                      final budget? when budget > 0 =>
                        'Rp${NumberFormat.compact(locale: Localizations.localeOf(context).languageCode).format(budget)}',
                      _ => '–',
                    },
                    l10n.tripSummaryBudget,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.tripSetupNext,
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: setupState.isLoading,
                onPressed: () => _submit(l10n),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _buildTitleCard(l10n),
            const SizedBox(height: 14),
            _buildScheduleCard(l10n),
            const SizedBox(height: 14),
            _buildHoursCard(l10n),
            const SizedBox(height: 14),
            _buildBudgetCard(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(AppLocalizations l10n) {
    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupCardHeading(
            icon: Icons.edit_outlined,
            title: l10n.tripNameLabel,
            caption: l10n.tripNameHint,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _titleEdited = true,
            style: appText(15, FontWeight.w700, AppColors.ink),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.field,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.sea600, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dates and duration together on an inline calendar: tap the first day,
  /// then the last.
  Widget _buildScheduleCard(AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final start = DateFormat('EEE d', languageCode).format(_startDate);
    final end = DateFormat('EEE d MMM', languageCode).format(_endDate);

    return SetupCard(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupCardHeading(icon: Icons.date_range_outlined, title: l10n.tripScheduleLabel, caption: l10n.tripScheduleHint),
        const SizedBox(height: 12),
        _RangeCalendar(start: _startDate, end: _endDate, onPick: _pickDay, onDrag: _dragDays),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: _Palette.selectedFill, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: start, style: appText(13, FontWeight.w700, AppColors.ink)),
                      TextSpan(text: '  →  ', style: appText(13, FontWeight.w500, AppColors.inkMuted)),
                      TextSpan(text: end, style: appText(13, FontWeight.w700, AppColors.ink)),
                    ],
                  ),
                ),
              ),
              Text(
                l10n.tripDays(_numDays),
                style: appText(13, FontWeight.w700, AppColors.sea600),
              ),
            ],
          ),
        ),
        if (_numDays > _softMaxDays) ...[
          const SizedBox(height: 8),
          Text(l10n.tripDurationLongWarning, style: appText(12, FontWeight.w600, const Color(0xFF7A4B00))),
        ],
      ],
      ),
    );
  }

  /// A suggested day length or the user's own start and end.
  Widget _buildHoursCard(AppLocalizations l10n) {
    final minutes = _minutes(_dailyEnd) - _minutes(_dailyStart);
    final isShort = minutes > 0 && minutes < 4 * 60;
    final paceNames = [l10n.tripPaceRelaxed, l10n.tripPaceStandard, l10n.tripPacePacked];

    return SetupCard(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupCardHeading(icon: Icons.schedule_rounded, title: l10n.tripDailyHoursLabel, caption: l10n.tripDailyHoursHint),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (index, (start, end)) in _paces.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _OptionTile(
                  selected: start == _dailyStart && end == _dailyEnd,
                  onTap: () => setState(() {
                    _dailyStart = start;
                    _dailyEnd = end;
                    _timeError = null;
                  }),
                  child: Column(
                    children: [
                      Text(paceNames[index], style: appText(13, FontWeight.w700, AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(start)}–${_formatTime(end)}',
                        style: appText(11, FontWeight.w500, AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: l10n.tripStartDateShort,
                time: _formatTime(_dailyStart),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: appText(15, FontWeight.w500, AppColors.inkMuted)),
            ),
            Expanded(
              child: _TimeField(
                label: l10n.tripEndDateShort,
                time: _formatTime(_dailyEnd),
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_timeError != null)
          Text(_timeError!, style: appText(12, FontWeight.w600, const Color(0xFFB42318)))
        else
          Text(
            isShort ? l10n.tripShortDayWarning : '${l10n.tripHoursPerDay(minutes ~/ 60)} · ${l10n.tripTimeZone}',
            style: appText(12, FontWeight.w600, isShort ? const Color(0xFF7A4B00) : AppColors.inkMuted),
          ),
      ],
      ),
    );
  }

  Widget _buildBudgetCard(AppLocalizations l10n) {
    final selectedTier = _selectedTier;
    final tiers = {
      _BudgetTier.economy: (l10n.tripBudgetEconomy, l10n.tripBudgetEconomyRange),
      _BudgetTier.standard: (l10n.tripBudgetStandard, l10n.tripBudgetStandardRange),
      _BudgetTier.premium: (l10n.tripBudgetPremium, l10n.tripBudgetPremiumRange),
    };

    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupCardHeading(
            icon: Icons.payments_outlined,
            title: l10n.tripBudgetLabel,
            caption: l10n.tripBudgetHint,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
            onChanged: (_) => setState(() => _budgetError = null),
            style: appText(17, FontWeight.w800, AppColors.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.field,
              errorText: _budgetError,
              isDense: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Text('Rp', style: appText(14, FontWeight.w800, AppColors.sea600)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.sea600, width: 1.5),
              ),
            ),
          ),
          if (_budgetError == null && (_budget ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.today_rounded, size: 15, color: AppColors.sea600),
                const SizedBox(width: 6),
                Text(
                  l10n.tripBudgetPerDay(RupiahInputFormatter.format((_budget! / _numDays).round())),
                  style: appText(12, FontWeight.w700, AppColors.inkMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final entry in tiers.entries) ...[
                if (entry.key != _BudgetTier.economy) const SizedBox(width: 8),
                Expanded(
                  child: _BudgetChip(
                    icon: _tierIcons[entry.key]!,
                    title: entry.value.$1,
                    range: entry.value.$2,
                    isSelected: entry.key == selectedTier,
                    onTap: () => setState(() {
                      _budgetController.text = RupiahInputFormatter.format(_tierPresets[entry.key]!);
                      _budgetError = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Durasi, jam harian and anggaran side by side above the button, so the
/// choices can be checked before moving on.
class _SetupSummary extends StatelessWidget {
  const _SetupSummary({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (index, (icon, value, label)) in items.indexed) ...[
              if (index > 0) const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: AppColors.sea600),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(13, FontWeight.w800, AppColors.ink, height: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(label, style: appText(10.5, FontWeight.w600, AppColors.inkMuted, height: 14)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette._();

  /// The "Biru Laut" tint behind a picked option and the date summary.
  static const selectedFill = Color(0xFFEEF4FB);
  static const rangeFill = Color(0xFFDCEAF6);
  static const pastDay = Color(0xFFB4BFCC);
}

/// A bordered choice; the picked one gets the blue border and tint.
class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.selected, required this.onTap, required this.child});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? _Palette.selectedFill : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.sea600 : AppColors.line, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: child),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.time, required this.onTap});

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(label, style: appText(12, FontWeight.w500, AppColors.inkMuted)),
                const SizedBox(width: 8),
                Expanded(child: Text(time, style: appText(15, FontWeight.w700, AppColors.ink))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A month grid with the trip's days marked: both ends filled blue, the days
/// between on a light band. Days before today cannot be picked.
class _RangeCalendar extends StatefulWidget {
  const _RangeCalendar({required this.start, required this.end, required this.onPick, required this.onDrag});

  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTime> onPick;

  /// The day the drag started on and the day under the finger now.
  final void Function(DateTime from, DateTime to) onDrag;

  @override
  State<_RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<_RangeCalendar> {
  static const _cell = 38.0;

  late DateTime _month = DateTime(widget.start.year, widget.start.month);

  static const _rowGap = 4.0;

  DateTime? _dragFrom;

  void _shiftMonth(int by) => setState(() => _month = DateTime(_month.year, _month.month + by));

  /// The pickable day under [position] in the day grid, or null over a blank
  /// cell, a past day or outside the grid.
  DateTime? _dayAt(Offset position, double width, int leading, int daysInMonth) {
    if (position.dx < 0 || position.dx >= width || position.dy < 0) return null;
    final row = position.dy ~/ (_cell + _rowGap);
    final column = (position.dx / (width / 7)).floor();
    final number = row * 7 + column - leading + 1;
    if (number < 1 || number > daysInMonth) return null;
    final date = DateTime(_month.year, _month.month, number);
    return date.isBefore(DateUtils.dateOnly(DateTime.now())) ? null : date;
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final material = MaterialLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final firstMonth = DateTime(today.year, today.month);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // Monday first, as Indonesian calendars are.
    final leading = (DateTime(_month.year, _month.month).weekday + 6) % 7;
    final weekdays = [for (var day = 0; day < 7; day++) DateFormat.E(languageCode).format(DateTime(2024, 1, 1 + day))];
    final start = DateUtils.dateOnly(widget.start);
    final end = DateUtils.dateOnly(widget.end);

    Widget arrow(IconData icon, String tooltip, VoidCallback? onTap) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 20, color: onTap == null ? AppColors.line : AppColors.ink),
            ),
          ),
        ),
      );
    }

    Widget day(int number) {
      final date = DateTime(_month.year, _month.month, number);
      final isPast = date.isBefore(today);
      final isEnd = date == start || date == end;
      final inRange = !date.isBefore(start) && !date.isAfter(end);
      final single = start == end;

      // The light band runs between the two ends, half a cell into each.
      final band = !inRange || single
          ? null
          : date == start
              ? const LinearGradient(colors: [Colors.transparent, Colors.transparent, _Palette.rangeFill, _Palette.rangeFill], stops: [0, 0.5, 0.5, 1])
              : date == end
                  ? const LinearGradient(colors: [_Palette.rangeFill, _Palette.rangeFill, Colors.transparent, Colors.transparent], stops: [0, 0.5, 0.5, 1])
                  : const LinearGradient(colors: [_Palette.rangeFill, _Palette.rangeFill]);

      return DecoratedBox(
        decoration: BoxDecoration(gradient: band),
        child: Center(
          child: Material(
            color: isEnd ? AppColors.sea600 : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isPast ? null : () => widget.onPick(date),
              child: SizedBox(
                width: _cell,
                height: _cell,
                child: Center(
                  child: Text(
                    '$number',
                    style: appText(
                      13,
                      isEnd ? FontWeight.w800 : (inRange ? FontWeight.w700 : FontWeight.w500),
                      isEnd
                          ? Colors.white
                          : inRange
                              ? AppColors.navy700
                              : (isPast ? _Palette.pastDay : AppColors.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final cells = <Widget>[
      for (var blank = 0; blank < leading; blank++) const SizedBox.shrink(),
      for (var number = 1; number <= daysInMonth; number++) day(number),
    ];

    return Column(
      children: [
        Row(
          children: [
            arrow(
              Icons.chevron_left_rounded,
              material.previousMonthTooltip,
              _month.isAfter(firstMonth) ? () => _shiftMonth(-1) : null,
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(languageCode).format(_month),
                textAlign: TextAlign.center,
                style: appText(15, FontWeight.w700, AppColors.ink),
              ),
            ),
            arrow(Icons.chevron_right_rounded, material.nextMonthTooltip, () => _shiftMonth(1)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final name in weekdays)
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: appText(11, FontWeight.w700, AppColors.inkMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // A horizontal drag picks a range; a vertical one still scrolls the
        // page, and a tap still picks one end at a time.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              // The range starts on the day the finger went down, not where the drag was recognised.
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: (details) =>
                  _dragFrom = _dayAt(details.localPosition, width, leading, daysInMonth),
              onHorizontalDragUpdate: (details) {
                final from = _dragFrom;
                final to = _dayAt(details.localPosition, width, leading, daysInMonth);
                if (from != null && to != null) widget.onDrag(from, to);
              },
              onHorizontalDragEnd: (_) => _dragFrom = null,
              onHorizontalDragCancel: () => _dragFrom = null,
              child: Column(
                children: [
                  for (var row = 0; row * 7 < cells.length; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _rowGap),
                      child: SizedBox(
                        height: _cell,
                        child: Row(
                          children: [
                            for (var column = 0; column < 7; column++)
                              Expanded(
                                child: row * 7 + column < cells.length ? cells[row * 7 + column] : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.icon,
    required this.title,
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String range;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.navy900 : AppColors.field,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.sun400 : AppColors.sea600),
              const SizedBox(height: 4),
              Text(title, style: appText(12, FontWeight.w800, isSelected ? Colors.white : AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                range,
                textAlign: TextAlign.center,
                style: appText(10.5, FontWeight.w600, isSelected ? Colors.white70 : AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 1 (C1): the state is the id of the trip this setup created. Coming
/// back to step 1 and submitting again edits that trip instead of creating a
/// second one.
class TripSetupController extends AutoDisposeAsyncNotifier<int?> {
  int? _tripId;

  @override
  FutureOr<int?> build() => null;

  Future<void> submit({
    required String title,
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    final repository = ref.read(tripServiceProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final tripId = _tripId;
      if (tripId == null) {
        return _tripId = await repository.createTrip(
          title: title,
          numDays: numDays,
          budgetTotal: budgetTotal,
          startDate: startDate,
          dailyStartTime: dailyStartTime,
          dailyEndTime: dailyEndTime,
        );
      }

      await repository.updateTrip(
        tripId,
        title: title,
        numDays: numDays,
        budgetTotal: budgetTotal,
        startDate: startDate,
        dailyStartTime: dailyStartTime,
        dailyEndTime: dailyEndTime,
      );
      return tripId;
    });
  }
}

final tripSetupControllerProvider =
    AsyncNotifierProvider.autoDispose<TripSetupController, int?>(
  TripSetupController.new,
);
