import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A route drawn on a PDF map.
class PdfMapRoute {
  const PdfMapRoute(this.points, this.color, {this.dashed = false});

  final List<LatLng> points;
  final PdfColor color;

  /// A straight line where the leg has no road geometry.
  final bool dashed;
}

/// A numbered pin on a PDF map.
class PdfMapPin {
  const PdfMapPin(this.point, this.label, this.color, {this.square = false});

  final LatLng point;
  final String label;
  final PdfColor color;

  /// Start and end points are squares, stops are circles.
  final bool square;
}

/// Which OpenStreetMap tiles a map of [width] x [height] PDF points needs to
/// show every point, and where they go. Web Mercator, 256 px tiles drawn at
/// [_pointsPerPixel] so the print stays sharp.
class PdfMapFrame {
  PdfMapFrame._(this.width, this.height, this.zoom, this.originX, this.originY);

  factory PdfMapFrame.fit(List<LatLng> points, {required double width, required double height}) {
    final spread = points.isEmpty ? [const LatLng(1.1301, 104.0529)] : points;
    // Pixels available at the print density, less a margin so pins at the
    // edge are not cut.
    final availableWidth = (width - 2 * _padding) / _pointsPerPixel;
    final availableHeight = (height - 2 * _padding) / _pointsPerPixel;

    var zoom = _maxZoom;
    while (zoom > _minZoom) {
      final xs = spread.map((point) => _worldX(point.longitude, zoom));
      final ys = spread.map((point) => _worldY(point.latitude, zoom));
      if (xs.reduce(math.max) - xs.reduce(math.min) <= availableWidth &&
          ys.reduce(math.max) - ys.reduce(math.min) <= availableHeight) {
        break;
      }
      zoom--;
    }

    final xs = spread.map((point) => _worldX(point.longitude, zoom));
    final ys = spread.map((point) => _worldY(point.latitude, zoom));
    final centreX = (xs.reduce(math.max) + xs.reduce(math.min)) / 2;
    final centreY = (ys.reduce(math.max) + ys.reduce(math.min)) / 2;
    return PdfMapFrame._(
      width,
      height,
      zoom,
      centreX - width / _pointsPerPixel / 2,
      centreY - height / _pointsPerPixel / 2,
    );
  }

  static const _tileSize = 256;
  static const _pointsPerPixel = 0.6;
  static const _padding = 18.0;
  static const _minZoom = 9;

  /// Street level; a day of stops a few hundred metres apart stops here.
  static const _maxZoom = 16;

  final double width;
  final double height;
  final int zoom;

  /// The world pixel at the map's top-left corner.
  final double originX;
  final double originY;

  /// "z/x/y" of every tile the map covers.
  List<String> get tileKeys => [for (final tile in _tiles) tile.key];

  static String tileUrl(String key) => 'https://tile.openstreetmap.org/$key.png';

  Iterable<({String key, int x, int y})> get _tiles sync* {
    final count = 1 << zoom;
    final firstX = (originX / _tileSize).floor();
    final firstY = (originY / _tileSize).floor();
    final lastX = ((originX + width / _pointsPerPixel) / _tileSize).floor();
    final lastY = ((originY + height / _pointsPerPixel) / _tileSize).floor();
    for (var y = math.max(firstY, 0); y <= math.min(lastY, count - 1); y++) {
      for (var x = firstX; x <= lastX; x++) {
        yield (key: '$zoom/${x % count}/$y', x: x, y: y);
      }
    }
  }

  /// [point] in PDF points from the map's top-left corner.
  PdfPoint offsetOf(LatLng point) => PdfPoint(
        (_worldX(point.longitude, zoom) - originX) * _pointsPerPixel,
        (_worldY(point.latitude, zoom) - originY) * _pointsPerPixel,
      );

  static double _worldX(double lng, int zoom) => (lng + 180) / 360 * _tileSize * (1 << zoom);

  static double _worldY(double lat, int zoom) {
    final sin = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
    return (0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi)) * _tileSize * (1 << zoom);
  }

  /// The map: OpenStreetMap tiles when [tiles] has them (a plain background
  /// otherwise, e.g. offline), then the routes, then the pins.
  pw.Widget build({
    required Map<String, Uint8List> tiles,
    required List<PdfMapRoute> routes,
    required List<PdfMapPin> pins,
  }) {
    final tileWidgets = <pw.Widget>[];
    var hasTiles = false;
    for (final tile in _tiles) {
      final bytes = tiles[tile.key];
      if (bytes == null) continue;
      hasTiles = true;
      const side = _tileSize * _pointsPerPixel;
      tileWidgets.add(pw.Positioned(
        left: tile.x * _tileSize * _pointsPerPixel - originX * _pointsPerPixel,
        top: tile.y * _tileSize * _pointsPerPixel - originY * _pointsPerPixel,
        child: pw.Image(pw.MemoryImage(bytes), width: side, height: side, fit: pw.BoxFit.fill),
      ));
    }

    return pw.ClipRRect(
      horizontalRadius: 10,
      verticalRadius: 10,
      child: pw.Container(
        width: width,
        height: height,
        color: const PdfColor.fromInt(0xFFE8EEF5),
        child: pw.Stack(
          children: [
            ...tileWidgets,
            pw.Positioned.fill(
              child: pw.CustomPaint(
                size: PdfPoint(width, height),
                painter: (canvas, size) => _paintRoutes(canvas, size, routes),
              ),
            ),
            for (final pin in pins) _pin(pin),
            pw.Positioned(
              right: 0,
              bottom: 0,
              child: pw.Container(
                color: PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                child: pw.Text(
                  hasTiles ? '© OpenStreetMap contributors' : 'Peta latar tidak tersedia (offline)',
                  style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _paintRoutes(PdfGraphics canvas, PdfPoint size, List<PdfMapRoute> routes) {
    for (final route in routes) {
      if (route.points.length < 2) continue;
      // A white casing under the line keeps it readable over busy tiles.
      for (final (color, lineWidth) in [(PdfColors.white, 4.2), (route.color, 2.4)]) {
        canvas
          ..setStrokeColor(color)
          ..setLineWidth(lineWidth)
          ..setLineCap(PdfLineCap.round)
          ..setLineJoin(PdfLineJoin.round);
        if (route.dashed) {
          canvas.setLineDashPattern([4, 3]);
        } else {
          canvas.setLineDashPattern();
        }
        for (final (index, point) in route.points.indexed) {
          final offset = offsetOf(point);
          // PDF graphics count y from the bottom.
          final y = size.y - offset.y;
          if (index == 0) {
            canvas.moveTo(offset.x, y);
          } else {
            canvas.lineTo(offset.x, y);
          }
        }
        canvas.strokePath();
      }
    }
    canvas.setLineDashPattern();
  }

  pw.Widget _pin(PdfMapPin pin) {
    const diameter = 15.0;
    final offset = offsetOf(pin.point);
    return pw.Positioned(
      left: offset.x - diameter / 2,
      top: offset.y - diameter / 2,
      child: pw.Container(
        width: diameter,
        height: diameter,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: pin.color,
          shape: pin.square ? pw.BoxShape.rectangle : pw.BoxShape.circle,
          borderRadius: pin.square ? const pw.BorderRadius.all(pw.Radius.circular(3)) : null,
          border: pw.Border.all(color: PdfColors.white, width: 1.4),
        ),
        child: pw.Text(pin.label, style: pw.TextStyle(fontSize: 7, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }
}
