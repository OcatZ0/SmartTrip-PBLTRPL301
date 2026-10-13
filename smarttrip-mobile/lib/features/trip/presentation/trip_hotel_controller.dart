import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_models.dart';
import '../data/trip_repository.dart';

/// Top-3 TOPSIS hotels for the trip (design spec Section 7).
final hotelOptionsProvider =
    FutureProvider.autoDispose.family<List<HotelOption>, int>((ref, tripsId) {
  return ref.watch(tripRepositoryProvider).fetchHotelOptions(tripsId);
});

/// "Cari Semua Hotel": every catalog place of type lodging matching the query.
final hotelSearchProvider =
    FutureProvider.autoDispose.family<List<TripPlace>, String>((ref, query) {
  return ref.watch(tripRepositoryProvider).searchHotels(query);
});

/// The hotel picked in step 4: a catalog place or a custom map pin.
sealed class HotelChoice {
  const HotelChoice();

  String get name;
}

class CatalogHotelChoice extends HotelChoice {
  const CatalogHotelChoice(this.place);

  final TripPlace place;

  @override
  String get name => place.name;
}

class CustomHotelChoice extends HotelChoice {
  const CustomHotelChoice({required this.name, required this.lat, required this.lng});

  @override
  final String name;
  final double lat;
  final double lng;
}

/// Step 4 (C4) submission: saves the hotel as every day's start/end point.
class TripHotelController extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(int tripsId, HotelChoice choice) async {
    final repository = ref.read(tripRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      switch (choice) {
        case CatalogHotelChoice(:final place):
          await repository.setCatalogHotel(tripsId, place.placesId!);
        case CustomHotelChoice(:final name, :final lat, :final lng):
          await repository.setCustomHotel(tripsId, name: name, lat: lat, lng: lng);
      }
      return true;
    });
  }
}

final tripHotelControllerProvider =
    AsyncNotifierProvider.autoDispose<TripHotelController, bool>(
  TripHotelController.new,
);
