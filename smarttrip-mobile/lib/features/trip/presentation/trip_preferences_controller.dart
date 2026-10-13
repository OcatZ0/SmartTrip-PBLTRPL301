import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_models.dart';
import '../data/trip_repository.dart';

/// Categories plus the profile defaults that pre-fill step 3 (Section 13
/// step 4).
class TripPreferencesData {
  const TripPreferencesData({required this.categories, required this.defaults});

  final List<TripCategory> categories;
  final PreferenceDefaults defaults;
}

final tripPreferencesDataProvider =
    FutureProvider.autoDispose<TripPreferencesData>((ref) async {
  final repository = ref.watch(tripRepositoryProvider);
  final (categories, defaults) = await (
    repository.fetchCategories(),
    repository.fetchPreferenceDefaults(),
  ).wait;
  return TripPreferencesData(categories: categories, defaults: defaults);
});

/// Step 3 (C3) submission: trip interests + weights, and optionally the same
/// values as profile defaults ("simpan sebagai default", US8).
class TripPreferencesController extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(
    int tripsId, {
    required Set<int> categoryIds,
    required List<double> ratings,
    required bool saveAsDefault,
  }) async {
    final repository = ref.read(tripRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.saveTripPreferences(tripsId, categoryIds: categoryIds, ratings: ratings);
      if (saveAsDefault) {
        await repository.saveProfileDefaults(categoryIds: categoryIds, ratings: ratings);
      }
      return true;
    });
  }
}

final tripPreferencesControllerProvider =
    AsyncNotifierProvider.autoDispose<TripPreferencesController, bool>(
  TripPreferencesController.new,
);
