import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/core/auth/session_controller.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/features/catalog/data/catalog_models.dart';
import 'package:smarttrip_mobile/features/catalog/presentation/catalog_controller.dart';
import 'package:smarttrip_mobile/features/wishlist/presentation/user_wishlist_controller.dart';

import '../../helpers/catalog_doubles.dart';
import '../../helpers/test_doubles.dart';

void main() {
  test('parses a PlaceResource page, summing both review counts', () {
    final page = CatalogPage.fromJson({
      'data': [
        {
          'places_id': 4,
          'name': 'Pantai Melur',
          'type': 'attraction',
          'photo_url': null,
          'rating': 4.25,
          'review_count_google': null,
          'review_count_in_app': 3,
          'estimated_cost_idr': 0,
          'categories': [
            {'categories_id': 1, 'name_id': 'Pantai', 'name_en': 'Beach', 'slug': 'pantai'},
          ],
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2},
    });

    final place = page.places.single;
    expect(place.reviewCount, 3);
    expect(place.estimatedCostIdr, 0);
    expect(place.categories.single.slug, 'pantai');
    expect(page.hasMore, isTrue);
  });

  test('a page that arrives for an older filter is dropped', () async {
    final catalog = FakeCatalogRepository()..gate = Completer<void>();
    final container = ProviderContainer(overrides: catalogOverrides(catalog: catalog));
    addTearDown(container.dispose);

    container.read(catalogControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(catalogControllerProvider.notifier);

    // The first (unfiltered) request is still waiting when the user picks a
    // category; both then answer.
    final filtered = controller.selectCategory('pantai');
    catalog.gate!.complete();
    await filtered;

    final state = container.read(catalogControllerProvider);
    expect(state.filter.categorySlug, 'pantai');
    expect(state.places, hasLength(20));
    expect(state.isLoading, isFalse);
  });

  test('loadMore stops at the last page', () async {
    final catalog = FakeCatalogRepository(total: 25);
    final container = ProviderContainer(overrides: catalogOverrides(catalog: catalog));
    addTearDown(container.dispose);

    container.read(catalogControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(catalogControllerProvider.notifier);
    await controller.refresh();
    await controller.loadMore();
    await controller.loadMore();

    expect(container.read(catalogControllerProvider).places, hasLength(25));
    expect(catalog.calls.where((call) => call.page == 3), isEmpty);
  });

  group('user wishlist', () {
    ProviderContainer containerFor(FakeUserWishlistRepository wishlist, {bool loggedIn = true}) {
      final container = ProviderContainer(overrides: [
        ...catalogOverrides(wishlist: wishlist),
        sessionControllerProvider.overrideWith(() => FakeSessionController(loggedIn ? testUser : null)),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('is empty for a guest without calling the API', () async {
      final wishlist = FakeUserWishlistRepository(saved: {1});
      final container = containerFor(wishlist, loggedIn: false);
      await container.read(sessionControllerProvider.future);

      expect(await container.read(userWishlistControllerProvider.future), isEmpty);
    });

    test('toggle adds, removes, and reverts when the request fails', () async {
      final wishlist = FakeUserWishlistRepository();
      final container = containerFor(wishlist);
      // The wishlist reloads once the session resolves; start after that.
      await container.read(sessionControllerProvider.future);
      await container.read(userWishlistControllerProvider.future);
      final controller = container.read(userWishlistControllerProvider.notifier);

      await controller.toggle(5);
      expect(container.read(userWishlistControllerProvider).value, {5});

      await controller.toggle(5);
      expect(container.read(userWishlistControllerProvider).value, isEmpty);

      wishlist.failNext = true;
      await expectLater(controller.toggle(6), throwsA(isA<NetworkFailure>()));
      expect(container.read(userWishlistControllerProvider).value, isEmpty);
      expect(wishlist.added, [5]);
      expect(wishlist.removed, [5]);
    });
  });
}
