import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../data/user_wishlist_repository.dart';

/// Ids of the places in the logged-in user's wishlist; empty for a guest.
/// Reloads whenever the logged-in user changes.
class UserWishlistController extends AsyncNotifier<Set<int>> {
  final _pending = <int>{};

  @override
  Future<Set<int>> build() async {
    final usersId = ref.watch(sessionControllerProvider.select((session) => session.valueOrNull?.usersId));
    if (usersId == null) return const {};

    return ref.read(userWishlistRepositoryProvider).fetchPlaceIds();
  }

  /// The heart flips at once and flips back if the request fails. A second
  /// tap while the first request is still running is ignored.
  Future<void> toggle(int placesId) async {
    if (!_pending.add(placesId)) return;

    final wasSaved = (state.valueOrNull ?? const {}).contains(placesId);
    _set(placesId, saved: !wasSaved);

    try {
      final repository = ref.read(userWishlistRepositoryProvider);
      if (wasSaved) {
        await repository.remove(placesId);
      } else {
        await repository.add(placesId);
      }
    } catch (_) {
      _set(placesId, saved: wasSaved);
      rethrow;
    } finally {
      _pending.remove(placesId);
    }
  }

  void _set(int placesId, {required bool saved}) {
    final ids = {...?state.valueOrNull};
    if (saved) {
      ids.add(placesId);
    } else {
      ids.remove(placesId);
    }
    state = AsyncData(ids);
  }
}

final userWishlistControllerProvider =
    AsyncNotifierProvider<UserWishlistController, Set<int>>(UserWishlistController.new);
