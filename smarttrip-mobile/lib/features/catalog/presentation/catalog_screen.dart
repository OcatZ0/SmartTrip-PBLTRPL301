import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../trip/data/trip_models.dart';
import '../../trip/presentation/trip_error_message.dart';
import '../../trip/presentation/widgets/load_error_view.dart';
import '../../wishlist/presentation/user_wishlist_controller.dart';
import 'catalog_controller.dart';
import 'widgets/place_card.dart';

/// B1. Home: katalog tempat wisata (F005, PRD Section 8 - browse tanpa
/// login). Search, category chips and an infinite-scroll grid; the heart on
/// a card saves the place to the user's own wishlist.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _searchDebounce = Duration(milliseconds: 400);

  // Start the next page while this many pixels of grid are still below.
  static const _loadMoreThreshold = 600.0;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () => ref.read(catalogControllerProvider.notifier).search(value));
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(catalogControllerProvider.notifier).search('');
  }

  // go, not push: the router only sends a freshly logged-in user back to the
  // catalog when login is the current location, and a pushed login page
  // would stay on top after a successful sign-in.
  void _goToLogin() => context.go(AppRoutes.login);

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical && notification.metrics.extentAfter < _loadMoreThreshold) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
    return false;
  }

  Future<void> _toggleSaved(int placesId) async {
    if (ref.read(sessionControllerProvider).valueOrNull == null) {
      _goToLogin();
      return;
    }

    try {
      await ref.read(userWishlistControllerProvider.notifier).toggle(placesId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).catalogWishlistFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = ref.watch(catalogControllerProvider);
    final isLoggedIn = ref.watch(sessionControllerProvider).valueOrNull != null;
    final savedIds = ref.watch(userWishlistControllerProvider).valueOrNull ?? const <int>{};

    return Scaffold(
      appBar: ScreenHeader(
        subtitle: l10n.catalogHeaderSubtitle,
        trailing: isLoggedIn
            ? null
            : TextButton(
                onPressed: _goToLogin,
                child: Text(l10n.catalogLogin),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(catalogControllerProvider.notifier).refresh(),
            ref.refresh(userWishlistControllerProvider.future).catchError((_) => const <int>{}),
          ]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(child: _Greeting()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _ChipBar(filter: state.filter)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    filter: state.filter,
                    savedCount: isLoggedIn ? savedIds.length : 0,
                  ),
                ),
              ),
              ..._content(context, state, savedIds),
              SliverPadding(
                padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // "Buat Trip" (B1): the router sends a logged-out user to login first.
        onPressed: () => context.push(AppRoutes.newTrip),
        backgroundColor: const Color(0xFFFFB956),
        foregroundColor: tokens.onAmber,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.edit_calendar_outlined, size: 20),
        label: Text(
          l10n.catalogCreateTrip,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tokens.onAmber,
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation.weight(700)],
              ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, CatalogState state, Set<int> savedIds) {
    final l10n = AppLocalizations.of(context);

    if (state.places.isEmpty) {
      if (state.isLoading) {
        return const [
          SliverPadding(
            padding: EdgeInsets.only(top: 48),
            sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          ),
        ];
      }

      final error = state.error;
      if (error != null) {
        return [
          SliverToBoxAdapter(
            child: LoadErrorView(
              message: tripErrorMessage(error, l10n),
              onRetry: () => ref.read(catalogControllerProvider.notifier).retry(),
            ),
          ),
        ];
      }

      return [
        SliverToBoxAdapter(
          child: _EmptyState(message: state.filter.isUnfiltered ? l10n.catalogEmpty : l10n.catalogNoResults),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final cardWidth = (constraints.crossAxisExtent - spacing) / 2;
            final textScaler = MediaQuery.textScalerOf(context);
            final cardHeight = cardWidth / PlaceCard.photoAspectRatio +
                PlaceCard.infoHeight -
                PlaceCard.infoTextHeight +
                textScaler.scale(PlaceCard.infoTextHeight);

            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: spacing,
                mainAxisSpacing: 24,
                mainAxisExtent: cardHeight,
              ),
              itemCount: state.places.length,
              itemBuilder: (context, index) {
                final place = state.places[index];
                return PlaceCard(
                  key: ValueKey(place.placesId),
                  place: place,
                  isSaved: savedIds.contains(place.placesId),
                  onToggleSaved: () => _toggleSaved(place.placesId),
                );
              },
            );
          },
        ),
      ),
      if (state.isLoading)
        const SliverPadding(
          padding: EdgeInsets.only(top: 24),
          sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        )
      else if (state.error != null)
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  Text(tripErrorMessage(state.error!, l10n), textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: () => ref.read(catalogControllerProvider.notifier).retry(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.actionRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  static const _guideBrown = Color(0xFF744A00);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.explore, size: 15, color: _guideBrown),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.catalogEyebrow,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _guideBrown,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.catalogGreeting,
          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, height: 28 / 22, letterSpacing: -0.55),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.catalogTagline,
          style: theme.textTheme.bodyMedium?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: tokens.chipFill,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 1)],
      ),
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: tokens.link),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l10n.catalogSearchHint,
                hintMaxLines: 1,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.textHint.withValues(alpha: 0.7)),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: l10n.catalogClearSearch,
              onPressed: onClear,
              icon: Icon(Icons.close, size: 18, color: tokens.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// Horizontal chips: "Semua", every interest category, then "Hotel"
/// (lodging has no interest categories, so it filters by type instead).
class _ChipBar extends ConsumerWidget {
  const _ChipBar({required this.filter});

  final CatalogFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <TripCategory>[];
    final controller = ref.read(catalogControllerProvider.notifier);

    final chips = <Widget>[
      _FilterChip(
        label: l10n.catalogFilterAll,
        icon: Icons.stars_outlined,
        selected: filter.categorySlug == null && filter.type == null,
        onTap: () => controller.selectCategory(null),
      ),
      for (final category in categories)
        _FilterChip(
          label: category.localizedName(languageCode),
          icon: _categoryIcon(category.slug),
          selected: filter.categorySlug == category.slug,
          onTap: () => controller.selectCategory(category.slug),
        ),
      _FilterChip(
        label: l10n.catalogFilterLodging,
        icon: Icons.hotel_outlined,
        selected: filter.type == 'lodging',
        onTap: () => controller.selectType('lodging'),
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  static IconData _categoryIcon(String slug) {
    return switch (slug) {
      'pantai' => Icons.waves,
      'alam' => Icons.park_outlined,
      'sejarah' => Icons.account_balance_outlined,
      'religi' => Icons.mosque_outlined,
      'landmark' => Icons.location_city,
      'spot-foto' => Icons.photo_camera_outlined,
      'rekreasi' => Icons.attractions_outlined,
      'belanja' => Icons.shopping_bag_outlined,
      'kuliner-seafood' => Icons.set_meal_outlined,
      'kuliner-lokal' => Icons.restaurant,
      _ => Icons.label_outline,
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final foreground = selected ? Colors.white : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tokens.accent : tokens.accentSoft,
        shape: const StadiumBorder(),
        elevation: selected ? 1 : 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  const _SectionHeader({required this.filter, required this.savedCount});

  static const _badgeText = Color(0xFF42607E);

  final CatalogFilter filter;
  final int savedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            _title(ref, l10n, Localizations.localeOf(context).languageCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
        ),
        if (savedCount > 0)
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.tokens.badgeFill, borderRadius: BorderRadius.circular(9999)),
            child: Text(
              l10n.catalogFavoriteCount(savedCount),
              style: theme.textTheme.labelSmall?.copyWith(color: _badgeText),
            ),
          ),
      ],
    );
  }

  String _title(WidgetRef ref, AppLocalizations l10n, String languageCode) {
    if (filter.search.isNotEmpty) return l10n.catalogSectionSearch(filter.search);
    if (filter.type == 'lodging') return l10n.catalogFilterLodging;

    final slug = filter.categorySlug;
    if (slug != null) {
      final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <TripCategory>[];
      for (final category in categories) {
        if (category.slug == slug) return category.localizedName(languageCode);
      }
    }

    return l10n.catalogSectionAll;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Icon(Icons.travel_explore, size: 48, color: context.tokens.textHint),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
