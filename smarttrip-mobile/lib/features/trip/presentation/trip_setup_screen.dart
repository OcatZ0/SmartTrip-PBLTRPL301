import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../l10n/app_localizations.dart';
import 'trip_error_message.dart';
import 'trip_setup_controller.dart';
import 'widgets/rupiah_input_formatter.dart';
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

  final _budgetController =
      TextEditingController(text: RupiahInputFormatter.format(1500000));

  int _numDays = 3;
  DateTime _startDate = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));
  TimeOfDay _dailyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _dailyEnd = const TimeOfDay(hour: 19, minute: 0);
  String? _budgetError;
  String? _timeError;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  int? get _budget => RupiahInputFormatter.parse(_budgetController.text);

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

  void _submit(AppLocalizations l10n) {
    final budget = _budget;
    final hasValidBudget = budget != null && budget > 0;
    final hasValidTimes = _minutes(_dailyEnd) > _minutes(_dailyStart);

    setState(() {
      _budgetError = hasValidBudget ? null : l10n.validationBudgetRequired;
      _timeError = hasValidTimes ? null : l10n.validationEndTimeAfterStart;
    });
    if (!hasValidBudget || !hasValidTimes) return;

    ref.read(tripSetupControllerProvider.notifier).submit(
          numDays: _numDays,
          budgetTotal: budget,
          startDate: _startDate,
          dailyStartTime: _formatTime(_dailyStart),
          dailyEndTime: _formatTime(_dailyEnd),
        );
  }

  Future<void> _pickStartDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _startDate = picked);
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
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final setupState = ref.watch(tripSetupControllerProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('d MMM y', languageCode);
    final endDate = _startDate.add(Duration(days: _numDays - 1));

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
        backgroundColor: tokens.screenBackground,
        appBar: ScreenHeader(
          subtitle: l10n.tripSetupHeader,
          onBack: () => _confirmLeave(l10n),
        ),
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: l10n.tripSetupNext,
            trailingIcon: Icons.arrow_forward,
            isLoading: setupState.isLoading,
            onPressed: () => _submit(l10n),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripSetupTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tripSetupSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    child: Icon(Icons.explore_outlined, size: 22, color: tokens.link),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildDurationCard(l10n, theme, tokens),
                  const SizedBox(height: 16),
                  _buildBudgetCard(l10n, theme, tokens),
                  const SizedBox(height: 16),
                  SetupCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SetupCardHeading(
                          icon: Icons.date_range_outlined,
                          title: l10n.tripDateLabel,
                          caption: l10n.tripDateHint,
                        ),
                        const SizedBox(height: 12),
                        _FilledTile(
                          onTap: _pickStartDate,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, size: 18, color: tokens.link),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${dateFormat.format(_startDate)} - ${dateFormat.format(endDate)}',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                              Icon(Icons.edit_calendar_outlined, size: 18, color: tokens.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeCard(
                          icon: Icons.wb_sunny_outlined,
                          label: l10n.tripStartTimeLabel,
                          time: _formatTime(_dailyStart),
                          timeZone: l10n.tripTimeZone,
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeCard(
                          icon: Icons.dark_mode_outlined,
                          label: l10n.tripEndTimeLabel,
                          time: _formatTime(_dailyEnd),
                          timeZone: l10n.tripTimeZone,
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  if (_timeError != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _timeError!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.badgeFill.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: tokens.badgeFill,
                          child: Icon(Icons.tips_and_updates_outlined, size: 17, color: tokens.link),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l10n.tripTipTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: l10n.tripTipBody,
                                  style: TextStyle(color: tokens.textSecondary),
                                ),
                              ],
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
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

  Widget _buildDurationCard(AppLocalizations l10n, ThemeData theme, AppTokens tokens) {
    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupCardHeading(
            icon: Icons.calendar_today_outlined,
            title: l10n.tripDurationLabel,
            caption: l10n.tripDurationHint,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.fieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  tooltip: l10n.tripDurationDecrease,
                  onPressed: _numDays > 1 ? () => setState(() => _numDays--) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.tripDays(_numDays),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                      Text(
                        l10n.tripNights(_numDays - 1),
                        style: theme.textTheme.labelSmall?.copyWith(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  tooltip: l10n.tripDurationIncrease,
                  onPressed: () => setState(() => _numDays++),
                ),
              ],
            ),
          ),
          if (_numDays > _softMaxDays) ...[
            const SizedBox(height: 8),
            Text(
              l10n.tripDurationLongWarning,
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF744A00)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(AppLocalizations l10n, ThemeData theme, AppTokens tokens) {
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: tokens.fieldFill,
              errorText: _budgetError,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Text(
                  'Rp',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.link,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final entry in tiers.entries) ...[
                if (entry.key != _BudgetTier.economy) const SizedBox(width: 8),
                Expanded(
                  child: _BudgetChip(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 20, color: context.tokens.link),
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.title,
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String range;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Material(
      color: isSelected ? tokens.accent : tokens.chipFill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Column(
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                range,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFFE3EEFF) : tokens.textSecondary,
                ),
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
      color: context.tokens.fieldFill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.timeZone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String time;
  final String timeZone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return SetupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tokens.link),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          _FilledTile(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(child: Text(time, style: theme.textTheme.labelLarge)),
                Text(
                  timeZone,
                  style: theme.textTheme.labelSmall?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
