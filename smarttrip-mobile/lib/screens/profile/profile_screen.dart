import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/config/locale_controller.dart';
import '../../core/error/api_failure.dart';
import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../trip/trip_preferences_screen.dart' show TripPreferencesData, tripPreferencesDataProvider;
import '../trip/widgets/interest_chip.dart';
import '../trip/widgets/weight_slider.dart';

/// Profil (F008/F009): panorama header, default interests and route
/// priorities edited in place, and the account rows.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _selectTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go(AppRoutes.catalog);
      case AppTab.trips:
        context.push(AppRoutes.trips);
      case AppTab.wishlist:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).comingSoon)));
      case AppTab.profile:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionControllerProvider).valueOrNull;
    final data = ref.watch(tripPreferencesDataProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        extendBody: true,
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileHeaderDelegate(
                name: user?.name ?? '',
                email: user?.email ?? '',
                eyebrow: l10n.profileEyebrow,
                headline: l10n.profileHeadline,
                topInset: MediaQuery.paddingOf(context).top,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                AppBottomBar.barHeight + AppBottomBar.fabRise + 24 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    data.when(
                      data: (value) => _PreferencesForm(data: value),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator(color: AppColors.sea600)),
                      ),
                      error: (error, _) => _Card(
                        child: LoadErrorView(
                          message: '${l10n.profileLoadFailed} ${tripErrorMessage(error, l10n)}',
                          onRetry: () => ref.invalidate(tripPreferencesDataProvider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _AccountSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomBar(
          current: AppTab.profile,
          onSelect: _selectTab,
          onCreateTrip: () => context.push(AppRoutes.newTrip),
          labels: {
            AppTab.home: l10n.navHome,
            AppTab.wishlist: l10n.navWishlist,
            AppTab.trips: l10n.navTrips,
            AppTab.profile: l10n.navProfile,
          },
          createLabel: l10n.catalogCreateTrip,
        ),
      ),
    );
  }
}

/// Panorama, avatar and name. Scrolling down shrinks it into a navy bar
/// pinned at the top, the avatar small on the left with the name beside it.
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileHeaderDelegate({
    required this.name,
    required this.email,
    required this.eyebrow,
    required this.headline,
    required this.topInset,
  });

  static const _panoramaHeight = 196.0;
  static const _barHeight = 64.0;
  static const _avatarSize = 88.0;
  static const _smallAvatar = 38.0;
  static const _nameGap = 10.0;
  static const _nameHeight = 28.0;
  static const _emailHeight = 22.0;

  final String name;
  final String email;
  final String eyebrow;
  final String headline;
  final double topInset;

  double get _panorama => topInset + _panoramaHeight;

  @override
  double get maxExtent => _panorama + _avatarSize / 2 + _nameGap + _nameHeight + _emailHeight;

  @override
  double get minExtent => topInset + _barHeight;

  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((word) => word.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final width = MediaQuery.sizeOf(context).width;
    final extent = maxExtent - shrinkOffset;
    double lerp(double a, double b) => a + (b - a) * t;

    final barCenter = topInset + _barHeight / 2;
    final avatar = lerp(_avatarSize, _smallAvatar);
    final avatarLeft = lerp((width - _avatarSize) / 2, 16);
    final avatarTop = lerp(_panorama - _avatarSize / 2, barCenter - _smallAvatar / 2);
    final nameTop = lerp(_panorama + _avatarSize / 2 + _nameGap, barCenter - 11);
    final nameLeft = lerp(16, 16 + _smallAvatar + 12);
    // The intro text is gone well before the bar closes.
    final introOpacity = (1 - t * 2.5).clamp(0.0, 1.0);

    return ClipRect(
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.surface)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: lerp(_panorama, extent).clamp(minExtent, _panorama),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.navy900),
                Opacity(
                  opacity: 1 - t * 0.85,
                  child: SvgPicture.asset(
                    'assets/images/login_panorama.svg',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8C0A2440), Color(0x000A2440), Color(0x000A2440), Color(0x730A2440)],
                      stops: [0, 0.35, 0.7, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (introOpacity > 0)
            Positioned(
              top: topInset + 18 - shrinkOffset * 0.4,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: introOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: appText(11, FontWeight.w700, AppColors.sun400, height: 16, letterSpacing: 0.88),
                    ),
                    const SizedBox(height: 4),
                    Text(headline, style: appText(24, FontWeight.w800, Colors.white, height: 30, letterSpacing: -0.48)),
                  ],
                ),
              ),
            ),
          Positioned(
            left: avatarLeft,
            top: avatarTop,
            child: Container(
              width: avatar,
              height: avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sea600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.lerp(AppColors.surface, Colors.white.withValues(alpha: 0.6), t)!,
                  width: lerp(4, 2),
                ),
              ),
              child: Text(initials(name), style: appText(lerp(28, 14), FontWeight.w800, Colors.white)),
            ),
          ),
          Positioned(
            left: nameLeft,
            right: 16,
            top: nameTop,
            child: Align(
              alignment: Alignment(lerp(0, -1), 0),
              child: Column(
                crossAxisAlignment: t < 0.5 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(
                      lerp(22, 16),
                      FontWeight.w700,
                      Color.lerp(AppColors.ink, Colors.white, t)!,
                      height: 22,
                    ),
                  ),
                  if (t < 0.4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Opacity(
                        opacity: 1 - t / 0.4,
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appText(13, FontWeight.w400, AppColors.inkMuted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ProfileHeaderDelegate old) {
    return old.name != name ||
        old.email != email ||
        old.eyebrow != eyebrow ||
        old.headline != headline ||
        old.topInset != topInset;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

/// Interests and the four route weights, saved together as the profile
/// defaults every new trip starts from.
class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({required this.data});

  final TripPreferencesData data;

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late final Set<int> _selected = {...widget.data.defaults.categoryIds};
  late final List<double> _ratings = widget.data.defaults.ratings;
  late final TripService _service;
  Timer? _pendingSave;

  @override
  void initState() {
    super.initState();
    _service = ref.read(tripServiceProvider);
  }

  @override
  void dispose() {
    // Leaving the screen right after a change still saves it.
    if (_pendingSave?.isActive ?? false) {
      _pendingSave!.cancel();
      _service.saveProfileDefaults(categoryIds: {..._selected}, ratings: [..._ratings]).ignore();
    }
    super.dispose();
  }

  /// Every change saves on its own after a short pause, so quick taps and a
  /// slider drag end up as one request.
  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 600), _save);
  }

  void _toggle(int categoriesId) {
    if (_selected.contains(categoriesId) && _selected.length == 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).profileNeedInterest)));
      return;
    }

    setState(() {
      if (!_selected.remove(categoriesId)) _selected.add(categoriesId);
    });
    _scheduleSave();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.saveProfileDefaults(categoryIds: {..._selected}, ratings: [..._ratings]);
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final weights = [
      (l10n.profileWeightInterest, l10n.profileWeightInterestHint),
      (l10n.profileWeightDistance, l10n.profileWeightDistanceHint),
      (l10n.profileWeightBudget, l10n.profileWeightBudgetHint),
      (l10n.profileWeightRating, l10n.profileWeightRatingHint),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileInterests, style: appText(17, FontWeight.w700, AppColors.ink, height: 22)),
              const SizedBox(height: 2),
              Text(l10n.profileInterestsHint, style: appText(12, FontWeight.w400, AppColors.inkMuted, height: 16)),
              const SizedBox(height: 12),
              InterestChipGrid(
                children: [
                  for (final category in widget.data.categories)
                    InterestChip(
                      label: category.localizedName(languageCode),
                      icon: categoryIcon(category.iconSymbol),
                      selected: _selected.contains(category.categoriesId),
                      onTap: () => _toggle(category.categoriesId),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.profilePriorities, style: appText(17, FontWeight.w700, AppColors.ink, height: 22)),
              for (final (index, (label, hint)) in weights.indexed) ...[
                const SizedBox(height: 16),
                WeightSlider(
                  label: label,
                  hint: hint,
                  value: _ratings[index],
                  onChanged: (value) => setState(() => _ratings[index] = value),
                  onChangeEnd: (_) => _scheduleSave(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  static const _danger = Color(0xFFB42318);

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = Localizations.localeOf(context).languageCode;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, name) in const [('id', 'Indonesia'), ('en', 'English')])
              ListTile(
                title: Text(
                  name,
                  style: appText(15, code == current ? FontWeight.w700 : FontWeight.w500, AppColors.ink),
                ),
                trailing: code == current ? const Icon(Icons.check, color: AppColors.sea600) : null,
                onTap: () => Navigator.of(sheetContext).pop(code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await ref.read(localeControllerProvider.notifier).select(picked);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutTitle),
        content: Text(l10n.profileLogoutBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.profileLogout, style: appText(14, FontWeight.w700, _danger)),
          ),
        ],
      ),
    );
    // The router leaves the profile for the login screen once the session is gone.
    if (confirmed == true) await ref.read(sessionControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    Widget row(
      String label, {
      String? value,
      Color color = AppColors.ink,
      bool last = false,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: AppColors.field)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: appText(14, FontWeight.w600, color))),
              if (value != null) Text(value, style: appText(13, FontWeight.w500, AppColors.inkMuted)),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          row(
            l10n.profileChangePassword,
            value: '›',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              showDragHandle: true,
              builder: (_) => const _ChangePasswordSheet(),
            ),
          ),
          row(l10n.profileLanguage, value: '${l10n.profileLanguageName} ›', onTap: () => _pickLanguage(context, ref)),
          row(l10n.profileLogout, color: _danger, last: true, onTap: () => _logout(context, ref)),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  String? _currentError;
  String? _passwordError;
  String? _formError;

  bool get hasPassword => ref.read(sessionControllerProvider).valueOrNull?.hasPassword ?? true;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _currentError = _passwordError = _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);
    try {
      final message = await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: hasPassword ? _current.text : null,
            password: _password.text,
            passwordConfirmation: _confirmation.text,
          );
      if (!mounted) return;
      if (!hasPassword) ref.read(sessionControllerProvider.notifier).markPasswordSet();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on ValidationFailure catch (failure) {
      setState(() {
        _currentError = failure.firstError('current_password');
        _passwordError = failure.firstError('password');
        if (_currentError == null && _passwordError == null) _formError = tripErrorMessage(failure, l10n);
      });
    } catch (error) {
      setState(() => _formError = tripErrorMessage(error, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    InputDecoration decoration(String label, {String? helper, String? error}) {
      return InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        errorText: error,
        filled: true,
        fillColor: AppColors.field,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.profileChangePassword, style: appText(18, FontWeight.w700, AppColors.ink, height: 24)),
                const SizedBox(height: 16),
                if (hasPassword) ...[
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    decoration: decoration(l10n.profilePasswordCurrent, error: _currentError),
                    validator: (value) => value == null || value.isEmpty ? l10n.validationPasswordRequired : null,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFDCEAF6), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.navy700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.profilePasswordGoogleOnly,
                            style: appText(13, FontWeight.w500, AppColors.navy700, height: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: decoration(l10n.profilePasswordNew, error: _passwordError),
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
                    if (value.length < 8) return l10n.validationPasswordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: decoration(l10n.profilePasswordConfirm),
                  validator: (value) => value == _password.text ? null : l10n.validationConfirmPasswordMismatch,
                ),
                if (_formError case final error?) ...[
                  const SizedBox(height: 12),
                  Text(error, style: appText(13, FontWeight.w500, const Color(0xFFB42318))),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sea600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(l10n.profilePasswordSubmit, style: appText(15, FontWeight.w700, Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
