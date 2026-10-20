import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_progress.dart';
import 'widgets/setup_card.dart';

/// C3. Pilih Minat + Atur Prioritas - Figma Mockup, node 85:2996 (US1, US8).
class TripPreferencesScreen extends ConsumerWidget {
  const TripPreferencesScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(tripPreferencesDataProvider);

    return data.when(
      data: (data) => _TripPreferencesForm(tripsId: tripsId, data: data),
      loading: () => Scaffold(
        appBar: ScreenHeader(subtitle: l10n.tripPreferencesHeader),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: ScreenHeader(subtitle: l10n.tripPreferencesHeader),
        body: LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(tripPreferencesDataProvider),
        ),
      ),
    );
  }
}

class _TripPreferencesForm extends ConsumerStatefulWidget {
  const _TripPreferencesForm({required this.tripsId, required this.data});

  final int tripsId;
  final TripPreferencesData data;

  @override
  ConsumerState<_TripPreferencesForm> createState() => _TripPreferencesFormState();
}

class _TripPreferencesFormState extends ConsumerState<_TripPreferencesForm> {
  late final Set<int> _selectedCategoryIds;
  late final List<double> _ratings;
  bool _saveAsDefault = false;
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    final defaults = widget.data.defaults;
    final availableIds = widget.data.categories.map((c) => c.categoriesId).toSet();
    _selectedCategoryIds = defaults.categoryIds.intersection(availableIds);
    _ratings = _ratingsFromWeights(defaults.weights);
  }

  /// Profile weights are normalized (sum 1); scale them back to the 0-10
  /// sliders with the strongest criterion at 10.
  static List<double> _ratingsFromWeights(List<double>? weights) {
    if (weights == null) return [5, 5, 5, 5];

    final strongest = weights.reduce(math.max);
    if (strongest <= 0) return [5, 5, 5, 5];

    return [for (final weight in weights) (weight / strongest * 10).roundToDouble()];
  }

  void _submit() {
    if (_selectedCategoryIds.isEmpty) {
      setState(() => _showCategoryError = true);
      return;
    }

    ref.read(tripPreferencesControllerProvider.notifier).submit(
          widget.tripsId,
          categoryIds: _selectedCategoryIds,
          ratings: _ratings,
          saveAsDefault: _saveAsDefault,
        );
  }

  String _levelLabel(double value, AppLocalizations l10n) {
    if (value >= 9) return l10n.tripPriorityLevelVeryHigh;
    if (value >= 7) return l10n.tripPriorityLevelHigh;
    if (value >= 4) return l10n.tripPriorityLevelMedium;
    return l10n.tripPriorityLevelLow;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final submitState = ref.watch(tripPreferencesControllerProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    ref.listen(tripPreferencesControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;

      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(tripErrorMessage(next.error!, l10n))));
        return;
      }

      if (next.valueOrNull == true) context.push(AppRoutes.tripHotel(widget.tripsId));
    });

    final criteria = [
      (Icons.radio_button_checked, l10n.tripPriorityInterest, l10n.tripPriorityInterestMin, l10n.tripPriorityInterestMax),
      (Icons.near_me_outlined, l10n.tripPriorityDistance, l10n.tripPriorityDistanceMin, l10n.tripPriorityDistanceMax),
      (Icons.account_balance_wallet_outlined, l10n.tripPriorityBudget, l10n.tripPriorityBudgetMin, l10n.tripPriorityBudgetMax),
      (Icons.stars_outlined, l10n.tripPriorityRating, l10n.tripPriorityRatingMin, l10n.tripPriorityRatingMax),
    ];

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      appBar: ScreenHeader(subtitle: l10n.tripPreferencesHeader),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: l10n.tripPreferencesNext,
          trailingIcon: Icons.arrow_forward,
          isLoading: submitState.isLoading,
          onPressed: _submit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          StepProgress(
            step: 3,
            totalSteps: 4,
            label: l10n.tripStepLabel(3, 4, l10n.tripPreferencesStepName),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tripPreferencesTitle, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  l10n.tripPreferencesSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l10n.tripInterestTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(width: 6),
                    Icon(Icons.auto_awesome, size: 15, color: tokens.link),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tripInterestHint,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in widget.data.categories)
                      _InterestChip(
                        label: category.localizedName(languageCode),
                        icon: categoryIcon(category.iconSymbol),
                        isSelected: _selectedCategoryIds.contains(category.categoriesId),
                        onTap: () => setState(() {
                          if (!_selectedCategoryIds.remove(category.categoriesId)) {
                            _selectedCategoryIds.add(category.categoriesId);
                          }
                          _showCategoryError = false;
                        }),
                      ),
                  ],
                ),
                if (_showCategoryError) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.validationInterestRequired,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tripPriorityTitle, style: theme.textTheme.titleSmall),
                Text(
                  l10n.tripPriorityHint,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: 8),
                SetupCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      for (var i = 0; i < criteria.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        _PrioritySlider(
                          icon: criteria[i].$1,
                          label: criteria[i].$2,
                          minLabel: criteria[i].$3,
                          maxLabel: criteria[i].$4,
                          value: _ratings[i],
                          valueLabel: l10n.tripPriorityValue(
                            _ratings[i].round(),
                            _levelLabel(_ratings[i], l10n),
                          ),
                          onChanged: (value) => setState(() => _ratings[i] = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SetupCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: tokens.chipFill,
                    child: Icon(Icons.tune, size: 18, color: tokens.link),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.tripSaveDefaultTitle, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tripSaveDefaultHint,
                          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _saveAsDefault,
                    activeTrackColor: tokens.link,
                    onChanged: (value) => setState(() => _saveAsDefault = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label, required this.isSelected, required this.onTap, this.icon});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// The category's own icon, shown while not selected (falls back to +).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final foreground = isSelected ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: isSelected ? tokens.accent : tokens.chipFill,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? Icons.check : (icon ?? Icons.add), size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySlider extends StatelessWidget {
  const _PrioritySlider({
    required this.icon,
    required this.label,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String minLabel;
  final String maxLabel;
  final double value;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final captionStyle = theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: tokens.link),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.badgeFill,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                valueLabel,
                style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF001D34)),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            activeTrackColor: tokens.accent,
            inactiveTrackColor: tokens.accentSoft,
            thumbColor: tokens.link,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            max: 10,
            divisions: 10,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(minLabel, style: captionStyle)),
            const SizedBox(width: 12),
            Flexible(child: Text(maxLabel, style: captionStyle, textAlign: TextAlign.end)),
          ],
        ),
      ],
    );
  }
}

/// Categories plus the profile defaults that pre-fill step 3 (Section 13
/// step 4).
class TripPreferencesData {
  const TripPreferencesData({required this.categories, required this.defaults});

  final List<TripCategory> categories;
  final PreferenceDefaults defaults;
}

final tripPreferencesDataProvider =
    FutureProvider.autoDispose<TripPreferencesData>((ref) async {
  final repository = ref.watch(tripServiceProvider);
  final (categories, defaults) = await (
    repository.fetchCategories(),
    repository.fetchPreferenceDefaults(),
  ).wait;
  return TripPreferencesData(categories: categories, defaults: defaults);
});

/// Step 3 (C3) submission: trip interests + weights, and optionally the same
/// values as profile defaults ("simpan sebagai default", US8).
class TripPreferencesController extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(
    int tripsId, {
    required Set<int> categoryIds,
    required List<double> ratings,
    required bool saveAsDefault,
  }) async {
    final repository = ref.read(tripServiceProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.saveTripPreferences(tripsId, categoryIds: categoryIds, ratings: ratings);
      if (saveAsDefault) {
        await repository.saveProfileDefaults(categoryIds: categoryIds, ratings: ratings);
      }
      return true;
    });
  }
}

final tripPreferencesControllerProvider =
    AsyncNotifierProvider.autoDispose<TripPreferencesController, bool>(
  TripPreferencesController.new,
);
