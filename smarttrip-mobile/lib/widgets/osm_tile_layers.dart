import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Batam island, used when a map has nothing to center on yet.
const batamCenter = LatLng(1.0907, 104.0393);

/// OpenStreetMap base tiles (no API key). The OSM tile usage policy requires
/// an identifying User-Agent and visible attribution, see [osmAttribution].
TileLayer osmTileLayer() {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.smarttrip.batam.smarttrip_mobile',
    maxZoom: 19,
  );
}

Widget osmAttribution() {
  return const SimpleAttributionWidget(
    source: Text('OpenStreetMap contributors'),
  );
}
