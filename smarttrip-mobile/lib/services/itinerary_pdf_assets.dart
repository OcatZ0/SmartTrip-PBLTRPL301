import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import '../models/trip.dart';
import '../models/weather.dart';
import 'pdf_map.dart';
import 'weather_service.dart';

/// What the PDF draws besides the trip itself: the app font, map tiles, stop
/// photos and the forecast. Every part is optional; whatever could not be
/// loaded (offline, a slow host) is simply left out of the PDF.
class ItineraryPdfAssets {
  const ItineraryPdfAssets({
    this.regular,
    this.bold,
    this.tiles = const {},
    this.photos = const {},
    this.forecast = const {},
  });

  static const none = ItineraryPdfAssets();

  final pw.Font? regular;
  final pw.Font? bold;

  /// OpenStreetMap tiles by "z/x/y".
  final Map<String, Uint8List> tiles;

  /// Small JPEG thumbnails by photo URL.
  final Map<String, Uint8List> photos;

  /// Forecast by date, only for trip days within Open-Meteo's range.
  final Map<DateTime, DayForecast> forecast;

  bool get hasFont => regular != null && bold != null;
}

class ItineraryPdfAssetsLoader {
  ItineraryPdfAssetsLoader({Dio? dio, WeatherService? weather})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 10))),
        _weather = weather ?? WeatherService();

  final Dio _dio;
  final WeatherService _weather;

  /// OpenStreetMap's tile policy asks for an identifying User-Agent and few
  /// parallel downloads.
  static const _userAgent = 'SmartTripBatam/1.0 (+https://smarttrips.my.id)';
  static const _tileDownloads = 2;

  /// A cap so one long trip cannot pull hundreds of tiles; maps past it are
  /// drawn without a background.
  static const _maxTiles = 160;

  static const _thumbnailWidth = 240;

  /// Batam city centre, for a trip without a start point yet.
  static const _batamCentre = (lat: 1.1301, lng: 104.0529);

  Future<ItineraryPdfAssets> load(Trip trip, {required List<PdfMapFrame> maps}) async {
    final results = await Future.wait([
      _fonts(),
      _tiles(maps),
      _photos(trip),
      _forecast(trip),
    ]);
    final fonts = results[0] as (pw.Font, pw.Font)?;
    return ItineraryPdfAssets(
      regular: fonts?.$1,
      bold: fonts?.$2,
      tiles: results[1] as Map<String, Uint8List>,
      photos: results[2] as Map<String, Uint8List>,
      forecast: results[3] as Map<DateTime, DayForecast>,
    );
  }

  Future<(pw.Font, pw.Font)?> _fonts() async {
    try {
      final regular = await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf');
      return (pw.Font.ttf(regular), pw.Font.ttf(bold));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Uint8List>> _tiles(List<PdfMapFrame> maps) async {
    final keys = maps.expand((map) => map.tileKeys).toSet().take(_maxTiles).toList();
    final tiles = <String, Uint8List>{};
    var next = 0;

    Future<void> worker() async {
      while (next < keys.length) {
        final key = keys[next++];
        final bytes = await _download(PdfMapFrame.tileUrl(key), userAgent: true);
        if (bytes != null) tiles[key] = bytes;
      }
    }

    await Future.wait(List.generate(_tileDownloads, (_) => worker()));
    return tiles;
  }

  Future<Map<String, Uint8List>> _photos(Trip trip) async {
    final urls = {
      for (final day in trip.days)
        for (final item in day.items)
          if (item.place?.photoUrl case final url? when url.isNotEmpty) url,
    };
    final photos = <String, Uint8List>{};
    await Future.wait(urls.map((url) async {
      final bytes = await _download(url);
      if (bytes == null) return;
      final thumbnail = await _thumbnail(bytes);
      if (thumbnail != null) photos[url] = thumbnail;
    }));
    return photos;
  }

  /// Server photos are up to 1600 px; a 240 px JPEG keeps the PDF small. The
  /// decode runs off the UI thread (not on the web, which has no isolates).
  static Future<Uint8List?> _thumbnail(Uint8List bytes) async {
    Uint8List? shrink() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = decoded.width > _thumbnailWidth ? img.copyResize(decoded, width: _thumbnailWidth) : decoded;
      return img.encodeJpg(resized, quality: 72);
    }

    try {
      return kIsWeb ? shrink() : await Isolate.run(shrink);
    } catch (_) {
      return null;
    }
  }

  Future<Map<DateTime, DayForecast>> _forecast(Trip trip) async {
    try {
      final start = trip.hotel;
      return await _weather.fetch(
        lat: start?.lat ?? _batamCentre.lat,
        lng: start?.lng ?? _batamCentre.lng,
        start: trip.startDate,
        end: trip.dateOfDay(trip.numDays),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<Uint8List?> _download(String url, {bool userAgent = false}) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          // Browsers refuse a script-set User-Agent.
          headers: userAgent && !kIsWeb ? {'User-Agent': _userAgent} : null,
        ),
      );
      final data = response.data;
      return data == null ? null : Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
}
