import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_repository.dart';

/// Step 1 (C1): the state is the id of the trip this setup created. Coming
/// back to step 1 and submitting again edits that trip instead of creating a
/// second one.
class TripSetupController extends AutoDisposeAsyncNotifier<int?> {
  int? _tripId;

  @override
  FutureOr<int?> build() => null;

  Future<void> submit({
    required int numDays,
    required int budgetTotal,
    required DateTime startDate,
    required String dailyStartTime,
    required String dailyEndTime,
  }) async {
    final repository = ref.read(tripRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final tripId = _tripId;
      if (tripId == null) {
        return _tripId = await repository.createTrip(
          numDays: numDays,
          budgetTotal: budgetTotal,
          startDate: startDate,
          dailyStartTime: dailyStartTime,
          dailyEndTime: dailyEndTime,
        );
      }

      await repository.updateTrip(
        tripId,
        numDays: numDays,
        budgetTotal: budgetTotal,
        startDate: startDate,
        dailyStartTime: dailyStartTime,
        dailyEndTime: dailyEndTime,
      );
      return tripId;
    });
  }
}

final tripSetupControllerProvider =
    AsyncNotifierProvider.autoDispose<TripSetupController, int?>(
  TripSetupController.new,
);
