import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Decodes a Google-format encoded polyline (the per-leg route geometry stored
/// in `itinerary_items.polyline_to_here`).
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  int readValue() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    // Not ~(result >> 1): on the web, bitwise results are unsigned 32-bit, so
    // every negative step would turn into a latitude in the thousands.
    return (result & 1) != 0 ? -(result >> 1) - 1 : result >> 1;
  }

  while (index < encoded.length) {
    lat += readValue();
    if (index >= encoded.length) break;
    lng += readValue();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

/// Straight-line distance, only for display ("± 4.2 km"); routing and the
/// day time budget are computed by the backend.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double radians(double degrees) => degrees * math.pi / 180;

  final dLat = radians(lat2 - lat1);
  final dLng = radians(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(radians(lat1)) * math.cos(radians(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
