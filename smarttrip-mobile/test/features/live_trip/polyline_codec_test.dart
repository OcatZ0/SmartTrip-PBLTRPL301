import 'package:flutter_test/flutter_test.dart';
import 'package:smarttrip_mobile/services/polyline_codec.dart';

void main() {
  test('decodes the Google encoded polyline reference example', () {
    final points = decodePolyline(r'_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 1e-5));
    expect(points[0].longitude, closeTo(-120.2, 1e-5));
    expect(points[1].latitude, closeTo(40.7, 1e-5));
    expect(points[1].longitude, closeTo(-120.95, 1e-5));
    expect(points[2].latitude, closeTo(43.252, 1e-5));
    expect(points[2].longitude, closeTo(-126.453, 1e-5));
  });

  test('an empty polyline has no points', () {
    expect(decodePolyline(''), isEmpty);
  });

  test('haversine distance between two Batam spots is a few kilometres', () {
    // Batam Centre to Nagoya, roughly 9 km apart in a straight line.
    final km = haversineKm(1.1301, 104.0529, 1.1440, 103.9930);

    expect(km, closeTo(6.85, 0.5));
  });
}
