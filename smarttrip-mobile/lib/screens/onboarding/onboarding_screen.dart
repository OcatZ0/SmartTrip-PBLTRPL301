import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/auth/session_controller.dart';
import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/primary_button.dart';
import '../trip/widgets/setup_card.dart';
import '../trip/widgets/weight_slider.dart';

/// The categories offered on Pilih Minat: the ones the admin marked for
/// onboarding, or every category when none is marked yet.
final onboardingCategoriesProvider = FutureProvider.autoDispose<List<TripCategory>>((ref) async {
  final service = ref.watch(tripServiceProvider);
  final marked = await service.fetchCategories(onboardingOnly: true);
  return marked.isNotEmpty ? marked : service.fetchCategories();
});

/// Pilih Minat then Atur Prioritas (F009, UC-011 A2): shown after login until
/// the user has default interests; at least one interest is required. Both
/// become the profile default and pre-fill every new trip.
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
  final _selected = <int>{};
  // Equal weights to start, which the server turns into 0.25 each.
  final _ratings = [5.0, 5.0, 5.0, 5.0];
  bool _onPriorities = false;
  bool _saving = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(tripServiceProvider).saveProfileDefaults(categoryIds: {..._selected}, ratings: [..._ratings]);
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

  void _toggle(int categoriesId) {
    setState(() {
      if (!_selected.remove(categoriesId)) _selected.add(categoriesId);
    });
  }

  void _back() {
    if (!_saving) setState(() => _onPriorities = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = ref.watch(sessionControllerProvider).valueOrNull?.name.split(' ').first ?? '';

    final Widget bottom;
    final Widget content;
    if (_onPriorities) {
      bottom = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.onboardingPriorityHint,
            textAlign: TextAlign.center,
            style: appText(12, FontWeight.w600, AppColors.inkMuted, height: 17),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _saving ? null : _back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Text(l10n.onboardingBack, style: appText(14, FontWeight.w700, AppColors.ink)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: l10n.onboardingContinue,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      );
      content = SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        sliver: SliverToBoxAdapter(
          child: SetupCard(
            padding: const EdgeInsets.all(18),
            child: PrioritySliders(
              ratings: _ratings,
              onChanged: (i, value) => setState(() => _ratings[i] = value),
            ),
          ),
        ),
      );
    } else {
      bottom = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selected.isEmpty ? l10n.onboardingPickHint : l10n.onboardingSelectedCount(_selected.length),
            textAlign: TextAlign.center,
            style: appText(12, FontWeight.w600, _selected.isEmpty ? AppColors.inkMuted : AppColors.sea600, height: 17),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: l10n.onboardingNext,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: _selected.isEmpty ? null : () => setState(() => _onPriorities = true),
          ),
        ],
      );
      content = SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 64,
          ),
          delegate: SliverChildListDelegate([
            for (final category in widget.categories)
              _InterestTile(
                label: category.localizedName(languageCode),
                icon: categoryIcon(category.iconSymbol),
                tone: categoryTone(category.iconTone),
                selected: _selected.contains(category.categoriesId),
                onTap: () => _toggle(category.categoriesId),
              ),
          ]),
        ),
      );
    }

    return PopScope(
      // Mandatory: back only returns from Atur Prioritas to Pilih Minat.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _onPriorities) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        bottomNavigationBar: BottomActionBar(child: bottom),
        body: CustomScrollView(
          // A fresh scroll position per step, so step 2 starts at the top.
          key: ValueKey(_onPriorities),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                eyebrow: l10n.onboardingStep(_onPriorities ? 2 : 1),
                title: _onPriorities
                    ? l10n.onboardingPriorityTitle
                    : (name.isEmpty ? l10n.onboardingTitle : l10n.onboardingGreeting(name)),
                subtitle: _onPriorities ? l10n.onboardingPrioritySubtitle : l10n.onboardingSubtitle,
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// Barelang panorama with the greeting, like the login and Trip Saya headers.
class _Header extends StatelessWidget {
  const _Header({required this.eyebrow, required this.title, required this.subtitle});

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.navy900),
              SvgPicture.asset('assets/images/login_panorama.svg', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x660A2440), Color(0xE60A2440)],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: SvgPicture.asset('assets/images/logo.svg'),
                  ),
                  const SizedBox(width: 8),
                  Text('SmartTrip', style: appText(15, FontWeight.w700, Colors.white)),
                ],
              ),
              const SizedBox(height: 56),
              Text(eyebrow, style: appText(11, FontWeight.w700, AppColors.sun400, height: 16, letterSpacing: 0.88)),
              const SizedBox(height: 6),
              Text(title, style: appText(26, FontWeight.w800, Colors.white, height: 32, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(subtitle, style: appText(13.5, FontWeight.w500, Colors.white.withValues(alpha: 0.85), height: 20)),
            ],
          ),
        ),
      ],
    );
  }
}

/// One category as a card: its admin-chosen icon in the category's colour,
/// a name that may wrap to two lines, and a tick when picked.
class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final ({Color background, Color foreground}) tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFEFF5FC) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.sea600 : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon ?? Icons.label_outline, size: 18, color: tone.foreground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: appText(13, selected ? FontWeight.w700 : FontWeight.w600, AppColors.ink, height: 17),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? const Icon(Icons.check_circle_rounded, key: ValueKey('on'), size: 20, color: AppColors.sea600)
                      : const Icon(Icons.radio_button_unchecked_rounded, key: ValueKey('off'), size: 20, color: AppColors.line),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
