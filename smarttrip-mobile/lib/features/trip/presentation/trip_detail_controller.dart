import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live_trip/data/visit_sync.dart';
import '../data/trip_models.dart';
import '../data/trip_repository.dart';

/// One trip with its itinerary, shared by the itinerary screen (D1) and the
/// live map (E1) so a visit marked on the map shows up on D1 right away.
class TripDetailController extends AutoDisposeFamilyAsyncNotifier<Trip, int> {
  @override
  Future<Trip> build(int tripsId) async {
    final trip = await ref.read(tripRepositoryProvider).fetchTrip(tripsId);
    final changes = await ref.read(visitSyncProvider).flush(trip);
    return _applyVisits(trip, changes);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => build(arg));
  }

  /// Marks or unmarks a stop (manual toggle, US7). The change shows
  /// immediately; returns whether it reached the server or was queued.
  Future<VisitChange> setVisited(ItineraryItem item, {required bool visited}) async {
    applyVisit(item.itineraryItemsId, visited ? DateTime.now() : null);

    final change = await ref.read(visitSyncProvider).setVisited(item, visited: visited);
    if (change is VisitSynced) applyVisit(item.itineraryItemsId, change.visitedAt);
    return change;
  }

  void applyVisit(int itineraryItemsId, DateTime? visitedAt) {
    final trip = state.valueOrNull;
    if (trip == null) return;
    state = AsyncData(_applyVisits(trip, {itineraryItemsId: visitedAt}));
  }

  static Trip _applyVisits(Trip trip, Map<int, DateTime?> visits) {
    if (visits.isEmpty) return trip;

    var updated = trip;
    for (final day in trip.days) {
      if (!day.items.any((item) => visits.containsKey(item.itineraryItemsId))) continue;

      updated = updated.withDay(day.withItems([
        for (final item in day.items)
          visits.containsKey(item.itineraryItemsId)
              ? item.copyWith(visitedAt: () => visits[item.itineraryItemsId])
              : item,
      ]));
    }
    return updated;
  }
}

final tripDetailProvider =
    AsyncNotifierProvider.autoDispose.family<TripDetailController, Trip, int>(
  TripDetailController.new,
);

/// The `padat`/`tidak_muat` flags of the last generate run per trip. The
/// trip detail endpoint does not return them, so they live for the session.
final generatedFlagsProvider = StateProvider.family<GenerateResult?, int>((ref, tripsId) => null);
