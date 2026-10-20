import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttrip_mobile/core/api/api_client.dart';
import 'package:smarttrip_mobile/core/error/api_failure.dart';
import 'package:smarttrip_mobile/models/trip.dart';
import 'package:smarttrip_mobile/services/trip_service.dart';
import 'package:smarttrip_mobile/services/visit_sync.dart';

import '../../helpers/test_doubles.dart';

/// Mimics the server toggle of `POST /itinerary-items/{id}/visit`.
class FakeVisitRepository extends TripService {
  FakeVisitRepository({Map<int, bool>? serverVisited})
      : serverVisited = serverVisited ?? {},
        super(ApiClient(tokenStorage: InMemoryTokenStorage()));

  final Map<int, bool> serverVisited;
  bool isOffline = false;
  final toggled = <int>[];

  @override
  Future<DateTime?> toggleVisit(int itineraryItemsId) async {
    if (isOffline) throw const NetworkFailure();

    toggled.add(itineraryItemsId);
    final visited = !(serverVisited[itineraryItemsId] ?? false);
    serverVisited[itineraryItemsId] = visited;
    return visited ? DateTime(2026, 10, 20, 10) : null;
  }
}

ItineraryItem item(int id, {bool visited = false}) => ItineraryItem(
      itineraryItemsId: id,
      visitOrder: id,
      isFromWishlist: false,
      visitedAt: visited ? DateTime(2026, 10, 20, 9) : null,
    );

Trip tripWith(List<ItineraryItem> items) => Trip(
      tripsId: 1,
      title: 'Trip',
      numDays: 1,
      budgetTotal: 1000000,
      startDate: DateTime(2026, 10, 20),
      dailyStartTime: '09:00',
      dailyEndTime: '19:00',
      days: [ItineraryDay(itineraryDaysId: 1, dayNumber: 1, items: items)],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('marking a stop online sends one toggle and nothing is queued', () async {
    final repository = FakeVisitRepository();
    final sync = VisitSync(repository);

    final change = await sync.setVisited(item(1), visited: true);

    expect(change, isA<VisitSynced>());
    expect((change as VisitSynced).visitedAt, isNotNull);
    expect(repository.toggled, [1]);
    expect(await sync.hasPending(), isFalse);
  });

  test('a mark made offline is queued and sent once the connection is back', () async {
    final repository = FakeVisitRepository()..isOffline = true;
    final sync = VisitSync(repository);

    final change = await sync.setVisited(item(1), visited: true);
    expect(change, isA<VisitQueued>());
    expect(await sync.hasPending(), isTrue);

    repository.isOffline = false;
    final applied = await sync.flush(tripWith([item(1)]));

    expect(applied.keys, [1]);
    expect(repository.serverVisited[1], isTrue);
    expect(await sync.hasPending(), isFalse);
  });

  test('replaying a queued mark the server already has does not toggle it back', () async {
    final repository = FakeVisitRepository()..isOffline = true;
    final sync = VisitSync(repository);
    await sync.setVisited(item(1), visited: true);

    // The request actually reached the server before the connection dropped.
    repository
      ..isOffline = false
      ..serverVisited[1] = true;
    final applied = await sync.flush(tripWith([item(1, visited: true)]));

    expect(applied, isEmpty);
    expect(repository.toggled, isEmpty);
    expect(repository.serverVisited[1], isTrue);
    expect(await sync.hasPending(), isFalse);
  });
}
