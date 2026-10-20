import 'dart:async';

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
import '../../widgets/step_progress.dart';
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

  final _budgetController =
      TextEditingController(text: RupiahInputFormatter.format(1500000));
  final _titleController = TextEditingController();

  /// The name follows the dates until the user types their own.
  bool _titleEdited = false;

  int _numDays = 3;
  DateTime _startDate = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));
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

  void _setNumDays(int days) {
    setState(() => _numDays = days);
    _syncTitle();
  }

  /// The calendar picks both ends; the number of days follows.
  Future<void> _pickDateRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = _startDate.isBefore(today) ? today : _startDate;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: start.add(Duration(days: _numDays - 1))),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateUtils.dateOnly(picked.start);
      _numDays = DateUtils.dateOnly(picked.end).difference(_startDate).inDays + 1;
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
    final languageCode = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('d MMM y', languageCode);

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
        ),
        bottomNavigationBar: BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SetupSummary(
                items: [
                  (Icons.calendar_today_rounded, l10n.tripDays(_numDays)),
                  if (_budget case final budget? when budget > 0)
                    (Icons.payments_outlined, 'Rp${RupiahInputFormatter.format(budget)}'),
                  (Icons.schedule_rounded, '${_formatTime(_dailyStart)}–${_formatTime(_dailyEnd)}'),
                ],
              ),
              const SizedBox(height: 10),
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
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            StepProgress(
              step: 1,
              totalSteps: 4,
              label: l10n.tripStepLabel(1, 4, l10n.tripSetupHeader),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripSetupTitle,
                          style: appText(24, FontWeight.w800, AppColors.ink, height: 30, letterSpacing: -0.48),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.tripSetupSubtitle,
                          style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 19),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navy900,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.explore_outlined, size: 22, color: AppColors.sun400),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTitleCard(l10n),
                  const SizedBox(height: 14),
                  _buildScheduleCard(l10n, dateFormat),
                  const SizedBox(height: 14),
                  _buildHoursCard(l10n),
                  const SizedBox(height: 14),
                  _buildBudgetCard(l10n),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4DF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, size: 20, color: Color(0xFF7A4B00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l10n.tripTipTitle,
                                  style: appText(12, FontWeight.w800, const Color(0xFF7A4B00)),
                                ),
                                TextSpan(
                                  text: l10n.tripTipBody,
                                  style: appText(12, FontWeight.w500, const Color(0xFF7A4B00)),
                                ),
                              ],
                            ),
                            style: const TextStyle(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  /// Dates and duration together: the range opens the calendar, the stepper
  /// moves the last day.
  Widget _buildScheduleCard(AppLocalizations l10n, DateFormat dateFormat) {
    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupCardHeading(
            icon: Icons.date_range_outlined,
            title: l10n.tripScheduleLabel,
            caption: l10n.tripScheduleHint,
          ),
          const SizedBox(height: 12),
          _FilledTile(
            onTap: _pickDateRange,
            child: Row(
              children: [
                Expanded(child: _DateEnd(label: l10n.tripStartDateShort, date: dateFormat.format(_startDate))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.inkMuted),
                ),
                Expanded(child: _DateEnd(label: l10n.tripEndDateShort, date: dateFormat.format(_endDate))),
                const SizedBox(width: 8),
                const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.sea600),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  tooltip: l10n.tripDurationDecrease,
                  onPressed: _numDays > 1 ? () => _setNumDays(_numDays - 1) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(l10n.tripDays(_numDays), style: appText(17, FontWeight.w800, AppColors.ink, height: 22)),
                      Text(
                        l10n.tripNights(_numDays - 1),
                        style: appText(11, FontWeight.w600, AppColors.inkMuted, height: 14),
                      ),
                    ],
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  tooltip: l10n.tripDurationIncrease,
                  onPressed: () => _setNumDays(_numDays + 1),
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

  /// Start and end of each day in one card, with how many hours that gives.
  Widget _buildHoursCard(AppLocalizations l10n) {
    final minutes = _minutes(_dailyEnd) - _minutes(_dailyStart);
    final isShort = minutes > 0 && minutes < 4 * 60;

    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupCardHeading(
            icon: Icons.schedule_rounded,
            title: l10n.tripDailyHoursLabel,
            caption: l10n.tripDailyHoursHint,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.tripStartTimeLabel,
                  time: _formatTime(_dailyStart),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.inkMuted),
              ),
              Expanded(
                child: _TimeTile(
                  icon: Icons.dark_mode_outlined,
                  label: l10n.tripEndTimeLabel,
                  time: _formatTime(_dailyEnd),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_timeError != null)
            Text(_timeError!, style: appText(12, FontWeight.w600, const Color(0xFFB42318)))
          else
            Row(
              children: [
                Icon(
                  isShort ? Icons.warning_amber_rounded : Icons.timelapse_rounded,
                  size: 16,
                  color: isShort ? const Color(0xFF7A4B00) : AppColors.sea600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isShort
                        ? l10n.tripShortDayWarning
                        : '${l10n.tripHoursPerDay(minutes ~/ 60)} · ${l10n.tripTimeZone}',
                    style: appText(12, FontWeight.w700, isShort ? const Color(0xFF7A4B00) : AppColors.inkMuted),
                  ),
                ),
              ],
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

/// "3 Hari · Rp1.500.000 · 09:00–19:00" above the button, so the choices
/// can be checked before moving on.
class _SetupSummary extends StatelessWidget {
  const _SetupSummary({required this.items});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Text('·', style: appText(12, FontWeight.w800, AppColors.line)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(items[i].$1, size: 14, color: AppColors.sea600),
              const SizedBox(width: 4),
              Text(items[i].$2, style: appText(12, FontWeight.w700, AppColors.ink)),
            ],
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        icon: Icon(icon, size: 20, color: onPressed == null ? AppColors.line : AppColors.navy900),
      ),
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

class _FilledTile extends StatelessWidget {
  const _FilledTile({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.field,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: child,
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.icon, required this.label, required this.time, required this.onTap});

  final IconData icon;
  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FilledTile(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.sea600),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(11, FontWeight.w700, AppColors.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(time, style: appText(18, FontWeight.w800, AppColors.ink, height: 22)),
        ],
      ),
    );
  }
}

class _DateEnd extends StatelessWidget {
  const _DateEnd({required this.label, required this.date});

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: appText(11, FontWeight.w700, AppColors.inkMuted)),
        const SizedBox(height: 2),
        Text(date, maxLines: 1, overflow: TextOverflow.ellipsis, style: appText(14, FontWeight.w800, AppColors.ink)),
      ],
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
