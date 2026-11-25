import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/auth/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/error/trip_error_message.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/primary_button.dart';
import '../trip/widgets/interest_chip.dart';

/// The categories offered on Pilih Minat: the ones the admin marked for
/// onboarding, or every category when none is marked yet.
final onboardingCategoriesProvider = FutureProvider.autoDispose<List<TripCategory>>((ref) async {
  final service = ref.watch(tripServiceProvider);
  final marked = await service.fetchCategories(onboardingOnly: true);
  return marked.isNotEmpty ? marked : service.fetchCategories();
});

/// Pilih Minat (F009, UC-011 A2): shown after login until the user has
/// default interests; at least one is required. The choice becomes the
/// profile default and pre-fills every new trip; the priorities start equal
/// and can be changed later in Profil.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(onboardingCategoriesProvider);

    return categories.when(
      data: (categories) => _OnboardingForm(categories: categories),
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.sea600)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.surface,
        body: LoadErrorView(
          message: tripErrorMessage(error, AppLocalizations.of(context)),
          onRetry: () => ref.invalidate(onboardingCategoriesProvider),
        ),
      ),
    );
  }
}

class _OnboardingForm extends ConsumerStatefulWidget {
  const _OnboardingForm({required this.categories});

  final List<TripCategory> categories;

  @override
  ConsumerState<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<_OnboardingForm> {
  /// Equal priorities, which the server turns into 0.25 each.
  static const _equalRatings = [5.0, 5.0, 5.0, 5.0];

  final _selected = <int>{};
  bool _saving = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(tripServiceProvider).saveProfileDefaults(categoryIds: {..._selected}, ratings: _equalRatings);
      // The router leaves this screen once the session knows.
      ref.read(sessionControllerProvider.notifier).markInterestsSet();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = ref.watch(sessionControllerProvider).valueOrNull?.name.split(' ').first ?? '';

    return PopScope(
      // Mandatory: back does not skip it.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        bottomNavigationBar: BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selected.isEmpty ? l10n.onboardingPickHint : l10n.onboardingSelectedCount(_selected.length),
                style: appText(12, FontWeight.w600, _selected.isEmpty ? AppColors.inkMuted : AppColors.sea600),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: l10n.onboardingContinue,
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: _saving,
                onPressed: _selected.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: SvgPicture.asset('assets/images/logo.svg'),
                  ),
                  const SizedBox(width: 8),
                  Text('SmartTrip', style: appText(16, FontWeight.w700, AppColors.navy900)),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                name.isEmpty ? l10n.onboardingTitle : l10n.onboardingGreeting(name),
                style: appText(24, FontWeight.w800, AppColors.ink, height: 30, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(l10n.onboardingSubtitle, style: appText(13.5, FontWeight.w500, AppColors.inkMuted, height: 20)),
              const SizedBox(height: 22),
              InterestChipGrid(
                children: [
                  for (final category in widget.categories)
                    InterestChip(
                      label: category.localizedName(languageCode),
                      icon: categoryIcon(category.iconSymbol),
                      selected: _selected.contains(category.categoriesId),
                      onTap: _saving
                          ? () {}
                          : () => setState(() {
                                if (!_selected.remove(category.categoriesId)) _selected.add(category.categoriesId);
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(l10n.onboardingLaterHint, style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 17)),
            ],
          ),
        ),
      ),
    );
  }
}
