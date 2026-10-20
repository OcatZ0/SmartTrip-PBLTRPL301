import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error/api_failure.dart';
import '../models/trip.dart';
import 'trip_service.dart';

/// Outcome of a visit change: sent to the server, or kept in the offline queue.
sealed class VisitChange {
  const VisitChange();
}

class VisitSynced extends VisitChange {
  const VisitSynced(this.visitedAt);

  final DateTime? visitedAt;
}

class VisitQueued extends VisitChange {
  const VisitQueued();
}

/// Sends visit marks (F013) and keeps the ones made offline in a local queue
/// (design spec Section 8: queued, retried, never dropped silently).
///
/// The server endpoint is a toggle, so the queue stores the *wanted* state
/// per item and a retry only toggles items whose server state still differs.
/// Replaying a request that already reached the server can then never undo it.
class VisitSync {
  VisitSync(this._repository);

  static const _queueKey = 'pending_visit_marks';

  final TripService _repository;

  Future<VisitChange> setVisited(ItineraryItem item, {required bool visited}) async {
    if (item.isVisited == visited) return VisitSynced(item.visitedAt);

    try {
      var visitedAt = await _repository.toggleVisit(item.itineraryItemsId);
      if ((visitedAt != null) != visited) {
        visitedAt = await _repository.toggleVisit(item.itineraryItemsId);
      }
      await _dequeue([item.itineraryItemsId]);
      return VisitSynced(visitedAt);
    } on NetworkFailure {
      final queue = await _readQueue();
      queue[item.itineraryItemsId] = visited;
      await _writeQueue(queue);
      return const VisitQueued();
    }
  }

  Future<bool> hasPending() async => (await _readQueue()).isNotEmpty;

  /// Sends queued marks that belong to [trip]. Returns the server's new
  /// `visited_at` for every item it changed; stops at the first network error.
  Future<Map<int, DateTime?>> flush(Trip trip) async {
    final queue = await _readQueue();
    if (queue.isEmpty) return const {};

    final items = {
      for (final day in trip.days)
        for (final item in day.items) item.itineraryItemsId: item,
    };
    final changed = <int, DateTime?>{};
    final done = <int>[];

    for (final entry in queue.entries) {
      final item = items[entry.key];
      if (item == null) continue;

      if (item.isVisited == entry.value) {
        done.add(entry.key);
        continue;
      }

      try {
        changed[entry.key] = await _repository.toggleVisit(entry.key);
        done.add(entry.key);
      } on NetworkFailure {
        break;
      } on ApiFailure {
        // The item is gone or no longer ours (e.g. regenerated itinerary).
        done.add(entry.key);
      }
    }

    await _dequeue(done);
    return changed;
  }

  Future<Map<int, bool>> _readQueue() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_queueKey);
    if (raw == null) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(int.parse(key), value as bool));
  }

  Future<void> _writeQueue(Map<int, bool> queue) async {
    final preferences = await SharedPreferences.getInstance();
    if (queue.isEmpty) {
      await preferences.remove(_queueKey);
      return;
    }
    await preferences.setString(
      _queueKey,
      jsonEncode(queue.map((key, value) => MapEntry(key.toString(), value))),
    );
  }

  Future<void> _dequeue(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    final queue = await _readQueue();
    final before = queue.length;
    itemIds.forEach(queue.remove);
    if (queue.length != before) await _writeQueue(queue);
  }
}

final visitSyncProvider = Provider<VisitSync>((ref) {
  return VisitSync(ref.watch(tripServiceProvider));
});
