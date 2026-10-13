import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trip/data/trip_models.dart';
import '../../trip/data/trip_repository.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

/// Chips above the grid: every interest category from the API.
final catalogCategoriesProvider = FutureProvider<List<TripCategory>>((ref) {
  return ref.watch(tripRepositoryProvider).fetchCategories();
});

/// What the grid is filtered by. A chip selects either one category or the
/// lodging type, never both; the search term combines with either.
@immutable
class CatalogFilter {
  const CatalogFilter({this.search = '', this.categorySlug, this.type});

  final String search;
  final String? categorySlug;
  final String? type;

  bool get isUnfiltered => search.isEmpty && categorySlug == null && type == null;

  CatalogFilter withSearch(String value) => CatalogFilter(search: value, categorySlug: categorySlug, type: type);

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter && other.search == search && other.categorySlug == categorySlug && other.type == type;

  @override
  int get hashCode => Object.hash(search, categorySlug, type);
}

@immutable
class CatalogState {
  const CatalogState({
    this.filter = const CatalogFilter(),
    this.places = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  final CatalogFilter filter;
  final List<CatalogPlace> places;

  /// Last page loaded, 0 before the first one arrives.
  final int page;
  final bool hasMore;
  final bool isLoading;
  final Object? error;

  CatalogState copyWith({bool? isLoading, Object? error}) {
    return CatalogState(
      filter: filter,
      places: places,
      page: page,
      hasMore: hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// B1 catalog grid with infinite scroll (PRD Section 9, PlaceCatalogGrid).
class CatalogController extends Notifier<CatalogState> {
  // Bumped on every new filter, so a page that arrives for an older filter
  // is dropped instead of mixed into the new results.
  int _generation = 0;

  @override
  CatalogState build() {
    Future.microtask(refresh);
    return const CatalogState(isLoading: true);
  }

  Future<void> search(String term) => _applyFilter(state.filter.withSearch(term.trim()));

  Future<void> selectCategory(String? slug) =>
      _applyFilter(CatalogFilter(search: state.filter.search, categorySlug: slug));

  Future<void> selectType(String type) => _applyFilter(CatalogFilter(search: state.filter.search, type: type));

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.error != null) return;
    await _load(reset: false);
  }

  /// After a failed page, loads that page again.
  Future<void> retry() => _load(reset: state.page == 0);

  Future<void> _applyFilter(CatalogFilter filter) async {
    if (filter == state.filter) return;
    state = CatalogState(filter: filter, isLoading: true);
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    final generation = reset ? ++_generation : _generation;
    final filter = state.filter;
    final previous = reset ? const <CatalogPlace>[] : state.places;

    state = reset ? CatalogState(filter: filter, isLoading: true) : state.copyWith(isLoading: true);

    try {
      final page = await ref.read(catalogRepositoryProvider).fetchPlaces(
            page: reset ? 1 : state.page + 1,
            search: filter.search,
            categorySlug: filter.categorySlug,
            type: filter.type,
          );
      if (generation != _generation) return;

      state = CatalogState(
        filter: filter,
        places: [...previous, ...page.places],
        page: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }
}

final catalogControllerProvider = NotifierProvider<CatalogController, CatalogState>(CatalogController.new);
