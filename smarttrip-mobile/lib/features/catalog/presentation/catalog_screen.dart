import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_bottom_bar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../trip/data/trip_models.dart';
import '../../trip/presentation/trip_error_message.dart';
import '../../trip/presentation/widgets/load_error_view.dart';
import '../../wishlist/presentation/user_wishlist_controller.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import 'catalog_controller.dart';
import 'widgets/catalog_style.dart';
import 'widgets/featured_place_card.dart';
import 'widgets/place_list_tile.dart';
import 'widgets/place_open_container.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _searchDebounce = Duration(milliseconds: 400);
  static const _loadMoreThreshold = 600.0;
  static const _featuredCount = 5;
  static const _minPlacesForFeatured = 8;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () => ref.read(catalogControllerProvider.notifier).search(value));
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(catalogControllerProvider.notifier).search('');
  }

  void _goToLogin() => context.go(AppRoutes.login);

  // Only the catalog exists so far; the other tabs get their screens later.
  void _selectTab(AppTab tab) {
    if (tab == AppTab.home) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).comingSoon)));
  }

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

  List<CatalogPlace> _featured(CatalogState state) {
    if (!state.filter.isUnfiltered) return const [];

    final firstPage = state.places.take(CatalogRepository.pageSize).toList();
    if (firstPage.length < _minPlacesForFeatured) return const [];

    final rated = [
      for (var i = 0; i < firstPage.length; i++)
        if (firstPage[i].rating != null) (index: i, place: firstPage[i]),
    ]..sort((a, b) {
        final byRating = b.place.rating!.compareTo(a.place.rating!);
        if (byRating != 0) return byRating;
        final byReviews = b.place.reviewCount.compareTo(a.place.reviewCount);
        return byReviews != 0 ? byReviews : a.index.compareTo(b.index);
      });

    return [for (final entry in rated.take(_featuredCount)) entry.place];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(catalogControllerProvider);
    final isLoggedIn = ref.watch(sessionControllerProvider).valueOrNull != null;
    final savedIds = ref.watch(userWishlistControllerProvider).valueOrNull ?? const <int>{};
    final featured = _featured(state);
    final featuredIds = {for (final place in featured) place.placesId};
    final rest = featuredIds.isEmpty
        ? state.places
        : [for (final place in state.places) if (!featuredIds.contains(place.placesId)) place];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: CatalogColors.surface,
        // The list scrolls behind the raised "Buat Trip" button.
        extendBody: true,
        body: RefreshIndicator(
          color: CatalogColors.sea600,
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
                SliverToBoxAdapter(
                  child: _CatalogHeader(
                    isLoggedIn: isLoggedIn,
                    onLogin: _goToLogin,
                    search: _SearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _ChipBar(filter: state.filter)),
                if (featured.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                    sliver: SliverToBoxAdapter(child: _SectionTitle(l10n.catalogSectionTopRated)),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: FeaturedPlaceCard.height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, index) {
                          final place = featured[index];
                          return PlaceOpenContainer(
                            key: ValueKey(place.placesId),
                            placesId: place.placesId,
                            radius: 20,
                            builder: (open) => FeaturedPlaceCard(
                              place: place,
                              isSaved: savedIds.contains(place.placesId),
                              onToggleSaved: () => _toggleSaved(place.placesId),
                              onTap: open,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, featured.isEmpty ? 20 : 24, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader(
                      filter: state.filter,
                      savedCount: isLoggedIn ? savedIds.length : 0,
                    ),
                  ),
                ),
                ..._content(context, state, rest, savedIds),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: AppBottomBar.barHeight + AppBottomBar.fabRise + 16 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomBar(
          current: AppTab.home,
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

  List<Widget> _content(BuildContext context, CatalogState state, List<CatalogPlace> places, Set<int> savedIds) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: places.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final place = places[index];
            // The shadow sits outside the container, which clips its closed
            // child to the card shape.
            return DecoratedBox(
              key: ValueKey(place.placesId),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: CatalogColors.cardShadow),
              child: PlaceOpenContainer(
                placesId: place.placesId,
                radius: 16,
                closedColor: Colors.white,
                builder: (open) => PlaceListTile(
                  place: place,
                  isSaved: savedIds.contains(place.placesId),
                  onToggleSaved: () => _toggleSaved(place.placesId),
                  onTap: open,
                ),
              ),
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

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.isLoggedIn, required this.onLogin, required this.search});

  static const _panoramaHeight = 200.0;
  static const _searchOverlap = 26.0;

  final bool isLoggedIn;
  final VoidCallback onLogin;
  final Widget search;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topInset + _panoramaHeight + _searchOverlap,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + _panoramaHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  'assets/images/login_panorama.svg',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8C0A2440), Color(0x000A2440)],
                      stops: [0, 0.7],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 18,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.catalogEyebrow,
                        style: catalogText(11, FontWeight.w700, CatalogColors.sun400, height: 16, letterSpacing: 0.88),
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          l10n.catalogGreeting,
                          style: catalogText(24, FontWeight.w800, Colors.white, height: 30, letterSpacing: -0.48),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.28))),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: onLogin,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        child: Text(l10n.catalogLogin, style: catalogText(12, FontWeight.w600, Colors.white)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 0, child: search),
        ],
      ),
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
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: CatalogColors.floatShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: CatalogColors.sea600),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: CatalogColors.sea600,
              style: catalogText(14, FontWeight.w400, CatalogColors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l10n.catalogSearchHint,
                hintMaxLines: 1,
                hintStyle: catalogText(14, FontWeight.w400, CatalogColors.inkMuted),
              ),
            ),
          ),
          // Listens to the field itself, so typing does not rebuild the
          // whole catalog just to show or hide this button.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.catalogClearSearch,
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18, color: CatalogColors.inkMuted),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChipBar extends ConsumerWidget {
  const _ChipBar({required this.filter});

  final CatalogFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <TripCategory>[];
    final controller = ref.read(catalogControllerProvider.notifier);

    final kecamatan = filter.kecamatan;
    final chips = <Widget>[
      _FilterChip(
        label: kecamatan ?? l10n.catalogKecamatanAll,
        selected: kecamatan != null,
        leading: Icons.place_outlined,
        trailing: Icons.expand_more,
        onTap: () => _pickKecamatan(context),
      ),
      Center(child: Container(width: 1, height: 24, color: CatalogColors.line)),
      _FilterChip(
        label: l10n.catalogFilterAll,
        selected: filter.categorySlug == null && filter.type == null,
        onTap: () => controller.selectCategory(null),
      ),
      for (final category in categories)
        _FilterChip(
          label: category.localizedName(languageCode),
          selected: filter.categorySlug == category.slug,
          leading: categoryIcon(category.iconSymbol),
          onTap: () => controller.selectCategory(category.slug),
        ),
      _FilterChip(
        label: l10n.catalogFilterLodging,
        selected: filter.type == 'lodging',
        onTap: () => controller.selectType('lodging'),
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  static void _pickKecamatan(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => const _KecamatanSheet(),
    );
  }
}

class _KecamatanSheet extends ConsumerWidget {
  const _KecamatanSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(catalogControllerProvider.select((state) => state.filter.kecamatan));
    final options = ref.watch(catalogKecamatanProvider);

    void choose(String? kecamatan) {
      ref.read(catalogControllerProvider.notifier).selectKecamatan(kecamatan);
      Navigator.of(context).pop();
    }

    Widget tile(String label, String? value, {String? subtitle}) {
      final isSelected = value == selected;
      return ListTile(
        title: Text(label, style: catalogText(15, isSelected ? FontWeight.w700 : FontWeight.w500, CatalogColors.ink)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: catalogText(12, FontWeight.w400, CatalogColors.inkMuted)),
        trailing: isSelected ? const Icon(Icons.check, color: CatalogColors.sea600) : null,
        selected: isSelected,
        onTap: () => choose(value),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.catalogKecamatanPick,
              style: catalogText(18, FontWeight.w700, CatalogColors.ink, height: 24),
            ),
          ),
          tile(l10n.catalogKecamatanAll, null),
          Flexible(
            child: options.when(
              data: (items) => ListView(
                shrinkWrap: true,
                children: [
                  for (final option in items)
                    tile(option.name, option.name, subtitle: l10n.catalogKecamatanCount(option.placesCount)),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => LoadErrorView(
                message: l10n.catalogKecamatanLoadFailed,
                onRetry: () => ref.invalidate(catalogKecamatanProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.leading, this.trailing});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? CatalogColors.navy900 : Colors.white,
        shape: StadiumBorder(side: selected ? BorderSide.none : const BorderSide(color: CatalogColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: EdgeInsets.only(left: leading == null ? 16 : 12, right: trailing == null ? 16 : 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: 16, color: selected ? CatalogColors.sun400 : CatalogColors.sea600),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: catalogText(
                    13,
                    selected ? FontWeight.w700 : FontWeight.w600,
                    selected ? Colors.white : CatalogColors.ink,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailing, size: 18, color: selected ? Colors.white : CatalogColors.inkMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: catalogText(18, FontWeight.w700, CatalogColors.ink, height: 24),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  const _SectionHeader({required this.filter, required this.savedCount});

  final CatalogFilter filter;
  final int savedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(child: _SectionTitle(_title(ref, l10n, Localizations.localeOf(context).languageCode))),
        if (savedCount > 0)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: CatalogColors.field, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, size: 12, color: CatalogColors.sun400),
                const SizedBox(width: 4),
                Text(l10n.catalogFavoriteCount(savedCount), style: catalogText(11, FontWeight.w700, CatalogColors.ink)),
              ],
            ),
          ),
      ],
    );
  }

  String _title(WidgetRef ref, AppLocalizations l10n, String languageCode) {
    final kecamatan = filter.kecamatan;
    final title = _filterTitle(ref, l10n, languageCode);
    if (kecamatan == null) return title ?? l10n.catalogSectionAll;
    return title == null ? l10n.catalogSectionKecamatan(kecamatan) : l10n.catalogSectionInKecamatan(title, kecamatan);
  }

  String? _filterTitle(WidgetRef ref, AppLocalizations l10n, String languageCode) {
    if (filter.search.isNotEmpty) return l10n.catalogSectionSearch(filter.search);
    if (filter.type == 'lodging') return l10n.catalogFilterLodging;

    final slug = filter.categorySlug;
    if (slug != null) {
      final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <TripCategory>[];
      for (final category in categories) {
        if (category.slug == slug) return category.localizedName(languageCode);
      }
    }

    return null;
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
          const Icon(Icons.travel_explore, size: 48, color: CatalogColors.inkMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: catalogText(14, FontWeight.w400, CatalogColors.inkMuted, height: 20),
          ),
        ],
      ),
    );
  }
}
