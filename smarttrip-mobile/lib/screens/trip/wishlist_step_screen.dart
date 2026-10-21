import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/place.dart' show CatalogPlace;
import '../../models/trip.dart';
import '../../services/place_service.dart';
import '../../services/trip_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_pill.dart';
import '../catalog/catalog_screen.dart' show catalogCategoriesProvider;
import '../catalog/widgets/catalog_filter_chip.dart';
import '../catalog/widgets/catalog_search_field.dart';
import '../catalog/widgets/place_grid_card.dart';
import 'map_pin_picker_screen.dart';

/// The trip's wishlist (`GET /api/trips/{id}/wishlist`).
final tripWishlistProvider = FutureProvider.autoDispose.family<List<TripWishlistItem>, int>((ref, tripsId) {
  return ref.watch(tripServiceProvider).fetchTripWishlist(tripsId);
});

/// The places the user saved with the heart in the catalog; they lead the grid.
final heartedPlacesProvider = FutureProvider.autoDispose<List<CatalogPlace>>((ref) {
  return ref.watch(wishlistServiceProvider).fetchPlaces();
});

/// C2. Susun Wishlist (F007, US3) - step 2 of the trip setup, laid out like
/// the catalog: search, category chips and the place grid, with the user's
/// hearted places first. Tapping a card puts it in the trip wishlist or takes
/// it out; a pin on the map adds a place outside the catalog. Optional: the
/// itinerary fills the rest with TOPSIS recommendations.
class WishlistStepScreen extends ConsumerStatefulWidget {
  const WishlistStepScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<WishlistStepScreen> createState() => _WishlistStepScreenState();
}

class _WishlistStepScreenState extends ConsumerState<WishlistStepScreen> {
  /// Catalog place ids, and wishlist item ids (negative), with a request running.
  final _busy = <int>{};
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _query = '';
  String? _categorySlug;

  // Catalog pages after the hearted places (hotels left out: they are step 4).
  final _places = <CatalogPlace>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _loadError;

  int get _tripsId => widget.tripsId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _places.clear();
    _page = 0;
    _hasMore = true;
    _loadError = null;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final query = _query;
    final category = _categorySlug;
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(placeServiceProvider)
          .fetchPlaces(page: _page + 1, search: query, categorySlug: category);
      // A newer search or filter started meanwhile: drop this page.
      if (!mounted || query != _query || category != _categorySlug) return;
      setState(() {
        _places.addAll(page.places.where((place) => !place.isLodging));
        _page = page.currentPage;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || value.trim() == _query) return;
      setState(() => _query = value.trim());
      _reload();
    });
  }

  void _selectCategory(String? slug) {
    if (slug == _categorySlug) return;
    setState(() => _categorySlug = slug);
    _reload();
  }

  bool _matchesFilters(CatalogPlace place) {
    if (place.isLodging) return false;
    final category = _categorySlug;
    if (category != null && !place.categories.any((item) => item.slug == category)) return false;
    final query = _query.toLowerCase();
    return query.isEmpty ||
        place.name.toLowerCase().contains(query) ||
        (place.kecamatan?.toLowerCase().contains(query) ?? false);
  }

  Future<void> _run(int key, Future<void> Function() request) async {
    if (!_busy.add(key)) return;
    setState(() {});
    try {
      await request();
      ref.invalidate(tripWishlistProvider(_tripsId));
      await ref.read(tripWishlistProvider(_tripsId).future);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${l10n.tripWishlistActionFailed} ${tripErrorMessage(error, l10n)}')));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  /// Puts the place in the trip wishlist, or takes it out when it is there.
  void _togglePicked(CatalogPlace place, TripWishlistItem? picked) {
    final trips = ref.read(tripServiceProvider);
    if (picked != null) {
      _run(place.placesId, () => trips.removeFromTripWishlist(_tripsId, picked.id));
    } else {
      _run(place.placesId, () => trips.addPlaceToTripWishlist(_tripsId, place.placesId));
    }
  }

  Future<void> _toggleHeart(int placesId) async {
    try {
      await ref.read(userWishlistControllerProvider.notifier).toggle(placesId);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    }
  }

  Future<void> _addPin() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const MapPinPickerScreen()),
    );
    if (picked == null || !mounted) return;

    final minutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _VisitLengthSheet(placeName: picked.name),
    );
    if (minutes == null || !mounted) return;

    await _run(
      -1,
      () => ref.read(tripServiceProvider).addCustomPinToTripWishlist(
            _tripsId,
            name: picked.name,
            lat: picked.lat,
            lng: picked.lng,
            visitMinutes: minutes,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final wishlist = ref.watch(tripWishlistProvider(_tripsId));
    final items = wishlist.valueOrNull ?? const <TripWishlistItem>[];
    final pickedByPlace = {for (final item in items) if (item.placesId != null) item.placesId!: item};
    final pins = items.where((item) => item.isCustomPin).toList();
    final totalMinutes = items.fold<int>(0, (sum, item) => sum + item.visitMinutes);

    final saved = ref.watch(userWishlistControllerProvider).valueOrNull ?? const <int>{};
    final hearted = ref.watch(heartedPlacesProvider).valueOrNull ?? const <CatalogPlace>[];
    final heartedIds = {for (final place in hearted) place.placesId};
    final grid = [
      ...hearted.where(_matchesFilters),
      ..._places.where((place) => !heartedIds.contains(place.placesId)),
    ];
    final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <TripCategory>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ScreenHeader(
        subtitle: l10n.tripWishlistHeader,
        trailing: StepPill(step: 2, total: 4, label: l10n.tripStepLabel(2, 4, l10n.tripWishlistHeader)),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WishlistSummary(
              places: items.length,
              hours: l10n.tripWishlistHours(_hours(totalMinutes)),
              placesLabel: l10n.tripWishlistSummaryPlaces,
              hoursLabel: l10n.tripWishlistSummaryVisit,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l10n.tripWishlistNext,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(AppRoutes.tripPreferences(_tripsId)),
            ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) _loadMore();
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tripWishlistPageTitle,
                      style: appText(22, FontWeight.w800, AppColors.ink, height: 28, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tripWishlistPageSubtitle,
                      style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 19),
                    ),
                    const SizedBox(height: 14),
                    CatalogSearchField(
                      controller: _searchController,
                      hintText: l10n.tripWishlistSearchHint,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  children: [
                    CatalogFilterChip(
                      label: l10n.catalogFilterAll,
                      selected: _categorySlug == null,
                      onTap: () => _selectCategory(null),
                    ),
                    for (final category in categories) ...[
                      const SizedBox(width: 8),
                      CatalogFilterChip(
                        label: category.localizedName(languageCode),
                        selected: _categorySlug == category.slug,
                        leading: categoryIcon(category.iconSymbol),
                        onTap: () => _selectCategory(category.slug),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Center(child: Container(width: 1, height: 24, color: AppColors.line)),
                    const SizedBox(width: 8),
                    CatalogFilterChip(
                      label: l10n.tripWishlistPin,
                      selected: false,
                      leading: Icons.add_location_alt_outlined,
                      onTap: _busy.contains(-1) ? () {} : _addPin,
                    ),
                  ],
                ),
              ),
            ),
            if (pins.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.tripWishlistPins, style: appText(12, FontWeight.w700, AppColors.inkMuted)),
                      for (final pin in pins)
                        _PinChip(
                          name: pin.name,
                          minutes: l10n.itineraryVisitMinutes(pin.visitMinutes),
                          removeLabel: l10n.tripWishlistRemove(pin.name),
                          isBusy: _busy.contains(-pin.id),
                          onRemove: () => _run(
                            -pin.id,
                            () => ref.read(tripServiceProvider).removeFromTripWishlist(_tripsId, pin.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (wishlist.hasError && !wishlist.hasValue)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LoadErrorView(
                    message: tripErrorMessage(wishlist.error!, l10n),
                    onRetry: () => ref.invalidate(tripWishlistProvider(_tripsId)),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: PlaceGridCard.height,
                ),
                itemCount: grid.length,
                itemBuilder: (_, index) {
                  final place = grid[index];
                  final picked = pickedByPlace[place.placesId];
                  return Opacity(
                    opacity: _busy.contains(place.placesId) ? 0.6 : 1,
                    child: PlaceGridCard(
                      place: place,
                      isSaved: saved.contains(place.placesId),
                      onToggleSaved: () => _toggleHeart(place.placesId),
                      pickedLabel: picked == null ? null : l10n.tripWishlistPicked,
                      onTap: _busy.contains(place.placesId) ? null : () => _togglePicked(place, picked),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: switch ((_loading, _loadError, grid.isEmpty)) {
                  (true, _, _) => const Center(child: CircularProgressIndicator(color: AppColors.sea600)),
                  (_, final error?, _) => LoadErrorView(message: tripErrorMessage(error, l10n), onRetry: _reload),
                  (_, _, true) => Center(
                      child: Text(
                        l10n.tripWishlistNoResults,
                        style: appText(13, FontWeight.w600, AppColors.inkMuted),
                      ),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "4", "4,5" (one decimal only when needed, Indonesian comma).
  static String _hours(int minutes) {
    final rounded = (minutes / 60 * 2).round() / 2;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1).replaceAll('.', ',');
  }
}

/// A custom pin in the trip wishlist, with a button to take it out.
class _PinChip extends StatelessWidget {
  const _PinChip({
    required this.name,
    required this.minutes,
    required this.removeLabel,
    required this.isBusy,
    required this.onRemove,
  });

  final String name;
  final String minutes;
  final String removeLabel;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sea600, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded, size: 15, color: AppColors.sea600),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              '$name · $minutes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appText(12, FontWeight.w700, AppColors.ink),
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: isBusy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkMuted),
                  )
                : IconButton(
                    tooltip: removeLabel,
                    padding: EdgeInsets.zero,
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.inkMuted),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Places and total visit time side by side above the button.
class _WishlistSummary extends StatelessWidget {
  const _WishlistSummary({
    required this.places,
    required this.hours,
    required this.placesLabel,
    required this.hoursLabel,
  });

  final int places;
  final String hours;
  final String placesLabel;
  final String hoursLabel;

  @override
  Widget build(BuildContext context) {
    Widget cell(IconData icon, String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: AppColors.sea600),
                  const SizedBox(width: 5),
                  Text(value, style: appText(13, FontWeight.w800, AppColors.ink, height: 18)),
                ],
              ),
              const SizedBox(height: 2),
              Text(label, style: appText(10.5, FontWeight.w600, AppColors.inkMuted, height: 14)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell(Icons.place_outlined, '$places', placesLabel),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
            cell(Icons.timelapse_rounded, hours, hoursLabel),
          ],
        ),
      ),
    );
  }
}

/// After a pin is dropped: how long the user plans to stay there.
class _VisitLengthSheet extends StatefulWidget {
  const _VisitLengthSheet({required this.placeName});

  final String placeName;

  @override
  State<_VisitLengthSheet> createState() => _VisitLengthSheetState();
}

class _VisitLengthSheetState extends State<_VisitLengthSheet> {
  static const _options = [30, 60, 90, 120, 180];
  int _minutes = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.placeName, style: appText(17, FontWeight.w800, AppColors.ink)),
            const SizedBox(height: 4),
            Text(l10n.tripWishlistVisitLengthHint, style: appText(13, FontWeight.w500, AppColors.inkMuted)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in _options)
                  ChoiceChip(
                    label: Text(l10n.itineraryVisitMinutes(minutes)),
                    selected: minutes == _minutes,
                    onSelected: (_) => setState(() => _minutes = minutes),
                    showCheckmark: false,
                    labelStyle: appText(13, FontWeight.w700, minutes == _minutes ? Colors.white : AppColors.ink),
                    selectedColor: AppColors.sea600,
                    backgroundColor: AppColors.field,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.tripWishlistSave,
              onPressed: () => Navigator.of(context).pop(_minutes),
            ),
          ],
        ),
      ),
    );
  }
}
