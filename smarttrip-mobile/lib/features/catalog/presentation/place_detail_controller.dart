import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../trip/data/trip_models.dart';
import '../../trip/data/trip_repository.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

/// B2 Detail Tempat (F006).
final placeDetailProvider = FutureProvider.autoDispose.family<PlaceDetail, int>((ref, placesId) {
  return ref.watch(catalogRepositoryProvider).fetchPlaceDetail(placesId);
});

/// Trips offered by "Tambah ke Trip".
final myTripsProvider = FutureProvider.autoDispose<List<TripSummary>>((ref) {
  return ref.watch(tripRepositoryProvider).fetchMyTrips();
});

/// Where the user is, for the "Jarak" fact. Only read when location access
/// was already granted elsewhere (live map, geofencing): a detail page should
/// not pop a permission prompt. Null when unknown.
final userPositionProvider = FutureProvider.autoDispose<LatLng?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return null;

    final position =
        await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)));
    return LatLng(position.latitude, position.longitude);
  } catch (_) {
    // No location service, plugin or fix: the fact is simply left out.
    return null;
  }
});
