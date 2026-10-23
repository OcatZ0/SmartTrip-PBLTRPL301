import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/panorama_header.dart';
import '../catalog/widgets/catalog_filter_chip.dart';
import '../catalog/widgets/catalog_search_field.dart';
import '../trip/widgets/trip_picker_sheet.dart';
import 'widgets/wishlist_place_card.dart';

enum WishlistSort { newest, rating, name, cost }

/// B3 Wishlist (F007): the places saved with the heart (`GET /api/wishlist`),
/// searchable and sortable, with a select mode to remove several or put them
/// into a trip.
class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categorySlug;
  WishlistSort _sort = WishlistSort.newest;

  bool _isSelecting = false;
  final Set<int> _selected = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go(AppRoutes.catalog);
      case AppTab.wishlist:
        break;
      case AppTab.trips:
        context.go(AppRoutes.trips);
      case AppTab.profile:
        context.go(AppRoutes.profile);
    }
  }

  List<CatalogPlace> _visible(List<CatalogPlace> places, String languageCode) {
    final query = _query.trim().toLowerCase();
    final list = places.where((place) {
      if (_categorySlug != null && !place.categories.any((category) => category.slug == _categorySlug)) return false;
      if (query.isEmpty) return true;
      return place.name.toLowerCase().contains(query) ||
          (place.kecamatan ?? '').toLowerCase().contains(query) ||
          place.categories.any((category) => category.localizedName(languageCode).toLowerCase().contains(query));
    }).toList();

    switch (_sort) {
      // GET /wishlist already lists the newest first.
      case WishlistSort.newest:
        break;
      case WishlistSort.rating:
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case WishlistSort.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case WishlistSort.cost:
        // An unknown cost goes last.
        list.sort((a, b) => (a.estimatedCostIdr ?? 1 << 31).compareTo(b.estimatedCostIdr ?? 1 << 31));
    }
    return list;
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, action: action));
  }

  void _toggleSelected(int placesId) {
    setState(() {
      if (!_selected.remove(placesId)) _selected.add(placesId);
    });
  }

  void _setSelecting(bool selecting) {
    setState(() {
      _isSelecting = selecting;
      _selected.clear();
    });
  }

  Future<void> _remove(CatalogPlace place) async {
    final l10n = AppLocalizations.of(context);
    final wishlist = ref.read(userWishlistControllerProvider.notifier);
    ref.read(userWishlistPlacesControllerProvider.notifier).removeLocally(place.placesId);

    try {
      // toggle() flips the saved state it knows, so the ids must be loaded
      // first or the place would be added instead of removed.
      await ref.read(userWishlistControllerProvider.future);
      await wishlist.toggle(place.placesId);
    } catch (_) {
      ref.invalidate(userWishlistPlacesControllerProvider);
      if (mounted) _showSnackBar(l10n.catalogWishlistFailed);
      return;
    }

    if (!mounted) return;
    _showSnackBar(
      l10n.wishlistRemoved(place.name),
      action: SnackBarAction(
        label: l10n.wishlistUndo,
        textColor: AppColors.sun400,
        onPressed: () => wishlist.toggle(place.placesId).ignore(),
      ),
    );
  }

  Future<void> _removeSelected() async {
    final l10n = AppLocalizations.of(context);
    final ids = [..._selected];
    final service = ref.read(wishlistServiceProvider);
    final places = ref.read(userWishlistPlacesControllerProvider.notifier);
    _setSelecting(false);

    var failed = 0;
    for (final id in ids) {
      places.removeLocally(id);
      try {
        await service.remove(id);
      } catch (_) {
        failed++;
      }
    }
    ref
      ..invalidate(userWishlistControllerProvider)
      ..invalidate(userWishlistPlacesControllerProvider);

    if (!mounted) return;
    _showSnackBar(failed == 0 ? l10n.wishlistRemovedMany(ids.length) : l10n.wishlistRemoveFailed(failed));
  }

  Future<void> _addSelectedToTrip() async {
    final l10n = AppLocalizations.of(context);
    final trip = await TripPickerSheet.show(context);
    if (trip == null || !mounted) return;

    final ids = [..._selected];
    final service = ref.read(tripServiceProvider);
    var added = 0;
    var failed = 0;
    for (final id in ids) {
      try {
        if (await service.addPlaceToTripWishlist(trip.tripsId, id)) added++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    _setSelecting(false);
    _showSnackBar(_addedMessage(l10n, trip, added: added, failed: failed));
  }

  String _addedMessage(AppLocalizations l10n, TripSummary trip, {required int added, required int failed}) {
    final parts = [
      if (added > 0)
        trip.hasItinerary ? l10n.wishlistAddedManyNeedsRegenerate(added, trip.title) : l10n.wishlistAddedMany(added, trip.title)
      else if (failed == 0)
        l10n.detailAlreadyInTrip(trip.title),
      if (failed > 0) l10n.wishlistAddFailed(failed),
    ];
    return parts.join(' ');
  }

  Future<void> _pickSort() async {
    final l10n = AppLocalizations.of(context);
    final sort = await showModalBottomSheet<WishlistSort>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.wishlistSortTitle, style: appText(18, FontWeight.w800, AppColors.ink)),
            ),
            for (final option in WishlistSort.values)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  option == _sort ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: option == _sort ? AppColors.sea600 : AppColors.inkMuted,
                ),
                title: Text(
                  _sortLabel(l10n, option),
                  style: appText(15, option == _sort ? FontWeight.w700 : FontWeight.w500, AppColors.ink),
                ),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  static String _sortLabel(AppLocalizations l10n, WishlistSort sort) => switch (sort) {
    WishlistSort.newest => l10n.wishlistSortNewest,
    WishlistSort.rating => l10n.wishlistSortRating,
    WishlistSort.name => l10n.wishlistSortName,
    WishlistSort.cost => l10n.wishlistSortCost,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(sessionControllerProvider).valueOrNull != null;
    final placesState = ref.watch(userWishlistPlacesControllerProvider);
    final bottomSpace = AppBottomBar.barHeight + AppBottomBar.fabRise + 16 + MediaQuery.paddingOf(context).bottom;

    final header = PanoramaHeader(
      eyebrow: l10n.wishlistEyebrow,
      title: l10n.wishlistTitle,
      bottom: CatalogSearchField(
        controller: _searchController,
        hintText: l10n.wishlistSearchHint,
        onChanged: (value) => setState(() => _query = value),
        onClear: () {
          _searchController.clear();
          setState(() => _query = '');
        },
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.navy900,
        onRefresh: () => ref.refresh(userWishlistPlacesControllerProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: header),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (!isLoggedIn)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.wishlistGuestTitle,
                  body: l10n.wishlistGuestBody,
                  actionLabel: l10n.catalogLogin,
                  // go, not push: see CatalogScreen._goToLogin.
                  onAction: () => context.go(AppRoutes.login),
                ),
              )
            else if (placesState.isLoading && !placesState.hasValue)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: AppColors.navy900)),
              )
            else if (placesState.hasError && !placesState.hasValue)
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoadErrorView(
                  message: l10n.wishlistLoadFailed,
                  onRetry: () => ref.invalidate(userWishlistPlacesControllerProvider),
                ),
              )
            else
              ..._buildList(l10n, placesState.valueOrNull ?? const [], bottomSpace),
          ],
        ),
      ),
      bottomNavigationBar: _isSelecting
          ? _SelectionBar(
              count: _selected.length,
              onRemove: _removeSelected,
              onAddToTrip: _addSelectedToTrip,
            )
          : AppBottomBar(
              current: AppTab.wishlist,
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
    );
  }

  List<Widget> _buildList(AppLocalizations l10n, List<CatalogPlace> places, double bottomSpace) {
    if (places.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.favorite_border_rounded,
            title: l10n.wishlistEmptyTitle,
            body: l10n.wishlistEmptyBody,
            actionLabel: l10n.wishlistExplore,
            onAction: () => context.go(AppRoutes.catalog),
          ),
        ),
      ];
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final visible = _visible(places, languageCode);
    // The chips offer only the categories of the saved places.
    final categories = <String, ({TripCategory category, int count})>{};
    for (final place in places) {
      for (final category in place.categories) {
        categories[category.slug] = (category: category, count: (categories[category.slug]?.count ?? 0) + 1);
      }
    }

    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              CatalogFilterChip(
                label: '${l10n.catalogFilterAll} (${places.length})',
                selected: _categorySlug == null,
                onTap: () => setState(() => _categorySlug = null),
              ),
              for (final entry in categories.entries) ...[
                const SizedBox(width: 8),
                CatalogFilterChip(
                  label: '${entry.value.category.localizedName(languageCode)} (${entry.value.count})',
                  leading: categoryIcon(entry.value.category.iconSymbol),
                  selected: _categorySlug == entry.key,
                  onTap: () => setState(() => _categorySlug = _categorySlug == entry.key ? null : entry.key),
                ),
              ],
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.wishlistSavedCount(places.length), style: appText(13, FontWeight.w700, AppColors.sea600)),
              ),
              TextButton.icon(
                onPressed: _pickSort,
                style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft, visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.sort_rounded, size: 18),
                label: Text(_sortLabel(l10n, _sort), style: appText(12.5, FontWeight.w600, AppColors.inkSoft)),
              ),
              TextButton.icon(
                onPressed: () => _setSelecting(!_isSelecting),
                style: TextButton.styleFrom(foregroundColor: AppColors.sea600, visualDensity: VisualDensity.compact),
                icon: Icon(_isSelecting ? Icons.close_rounded : Icons.checklist_rtl_rounded, size: 18),
                label: Text(
                  _isSelecting ? l10n.wishlistSelectDone : l10n.wishlistSelect,
                  style: appText(13, FontWeight.w700, AppColors.sea600),
                ),
              ),
            ],
          ),
        ),
      ),
      if (visible.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.search_off_rounded,
            title: l10n.catalogNoResults,
            actionLabel: l10n.wishlistClearFilters,
            onAction: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _categorySlug = null;
              });
            },
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottomSpace),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final place = visible[index];
              return WishlistPlaceCard(
                place: place,
                isSelecting: _isSelecting,
                isSelected: _selected.contains(place.placesId),
                onTap: () => _isSelecting ? _toggleSelected(place.placesId) : context.push(AppRoutes.place(place.placesId)),
                onLongPress: () {
                  if (!_isSelecting) setState(() => _isSelecting = true);
                  _toggleSelected(place.placesId);
                },
                onRemove: () => _remove(place),
              );
            },
          ),
        ),
    ];
  }
}

/// Guest, empty and no-match states: an icon, a line or two and a button.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body, required this.actionLabel, required this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final body = this.body;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.field, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.sea600),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: appText(17, FontWeight.w800, AppColors.ink, height: 24)),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: appText(13.5, FontWeight.w500, AppColors.inkMuted, height: 20)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy900,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel, style: appText(14, FontWeight.w700, Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Replaces the bottom bar while picking: how many are picked, Hapus and
/// Tambah ke Trip.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.count, required this.onRemove, required this.onAddToTrip});

  final int count;
  final VoidCallback onRemove;
  final VoidCallback onAddToTrip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const danger = Color(0xFFC0392B);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.wishlistSelectedCount(count), style: appText(15, FontWeight.w800, AppColors.ink)),
                Text(
                  l10n.wishlistSelectHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appText(11.5, FontWeight.w500, AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: count == 0 ? null : onRemove,
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: const BorderSide(color: danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(l10n.wishlistRemove, style: appText(13, FontWeight.w700, danger)),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: count == 0 ? null : onAddToTrip,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sea600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.detailAddToTrip, style: appText(13, FontWeight.w700, Colors.white)),
          ),
        ],
      ),
    );
  }
}
