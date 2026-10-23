import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_pill.dart';
import 'widgets/interest_chip.dart';
import 'widgets/setup_card.dart';
import 'widgets/weight_slider.dart';

/// C3. Pilih Minat + Atur Prioritas (US1, US8) - step 3 of the trip setup,
/// in the cards of the profile screen: interests two per row, the four route
/// weights and "save as profile default". Starts from the profile defaults.
class TripPreferencesScreen extends ConsumerWidget {
  const TripPreferencesScreen({super.key, required this.tripsId});

  final int tripsId;

  static PreferredSizeWidget header(AppLocalizations l10n) {
    return ScreenHeader(
      subtitle: l10n.tripPreferencesHeader,
      trailing: StepPill(step: 3, total: 4, label: l10n.tripStepLabel(3, 4, l10n.tripPreferencesStepName)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(tripPreferencesDataProvider);

    return data.when(
      data: (data) => _TripPreferencesForm(tripsId: tripsId, data: data),
      loading: () => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: header(l10n),
        body: const Center(child: CircularProgressIndicator(color: AppColors.sea600)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: header(l10n),
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
    _ratings = defaults.ratings;
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
      (Icons.interests_outlined, l10n.tripPriorityInterest, l10n.tripPriorityInterestMin, l10n.tripPriorityInterestMax),
      (Icons.near_me_outlined, l10n.tripPriorityDistance, l10n.tripPriorityDistanceMin, l10n.tripPriorityDistanceMax),
      (Icons.account_balance_wallet_outlined, l10n.tripPriorityBudget, l10n.tripPriorityBudgetMin, l10n.tripPriorityBudgetMax),
      (Icons.star_outline_rounded, l10n.tripPriorityRating, l10n.tripPriorityRatingMin, l10n.tripPriorityRatingMax),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: TripPreferencesScreen.header(l10n),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: l10n.tripPreferencesNext,
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: submitState.isLoading,
          onPressed: _submit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(
            l10n.tripPreferencesTitle,
            style: appText(22, FontWeight.w800, AppColors.ink, height: 28, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(l10n.tripPreferencesSubtitle, style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 19)),
          const SizedBox(height: 18),
          SetupCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SetupCardHeading(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.tripInterestTitle,
                  caption: l10n.tripInterestHint,
                ),
                const SizedBox(height: 14),
                InterestChipGrid(
                  children: [
                    for (final category in widget.data.categories)
                      InterestChip(
                        label: category.localizedName(languageCode),
                        icon: categoryIcon(category.iconSymbol),
                        selected: _selectedCategoryIds.contains(category.categoriesId),
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
                  const SizedBox(height: 10),
                  Text(
                    l10n.validationInterestRequired,
                    style: appText(12, FontWeight.w600, Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SetupCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SetupCardHeading(
                  icon: Icons.tune_rounded,
                  title: l10n.tripPriorityTitle,
                  caption: l10n.tripPriorityHint,
                ),
                for (var i = 0; i < criteria.length; i++) ...[
                  const SizedBox(height: 18),
                  WeightSlider(
                    icon: criteria[i].$1,
                    label: criteria[i].$2,
                    minLabel: criteria[i].$3,
                    maxLabel: criteria[i].$4,
                    value: _ratings[i],
                    valueLabel: l10n.tripPriorityValue(_ratings[i].round(), _levelLabel(_ratings[i], l10n)),
                    onChanged: (value) => setState(() => _ratings[i] = value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SetupCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bookmark_add_outlined, size: 19, color: AppColors.sea600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.tripSaveDefaultTitle, style: appText(13, FontWeight.w700, AppColors.ink, height: 18)),
                      const SizedBox(height: 2),
                      Text(
                        l10n.tripSaveDefaultHint,
                        style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _saveAsDefault,
                  activeTrackColor: AppColors.sea600,
                  onChanged: (value) => setState(() => _saveAsDefault = value),
                ),
              ],
            ),
          ),
        ],
      ),
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
