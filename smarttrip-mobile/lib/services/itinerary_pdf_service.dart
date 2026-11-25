import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/trip.dart';
import '../models/weather.dart';
import 'itinerary_pdf_assets.dart';
import 'itinerary_pdf_plan.dart';
import 'pdf_map.dart';

/// Builds the itinerary PDF on the device from the trip already loaded by the
/// itinerary screen (UC-018 Mengekspor Itinerary ke PDF): a cover with the
/// whole trip, one section per day with its map, timed schedule and stop
/// cards, and a page of practical info. [ItineraryPdfAssetsLoader] fetches
/// the optional extras first; without them (offline) the PDF still builds.
class ItineraryPdfService {
  const ItineraryPdfService();

  static const _margin = 28.0;
  static const _contentWidth = 595.28 - 2 * _margin;
  static const _coverMapHeight = 250.0;
  static const _dayMapHeight = 190.0;

  static const _navy = PdfColor.fromInt(0xFF0A2440);
  static const _navySoft = PdfColor.fromInt(0xFF16476D);
  static const _sea = PdfColor.fromInt(0xFF2B6FAB);
  static const _sun = PdfColor.fromInt(0xFFF6B03C);
  static const _surface = PdfColor.fromInt(0xFFF5F7FB);
  static const _line = PdfColor.fromInt(0xFFDBE2EC);
  static const _ink = PdfColor.fromInt(0xFF14212F);
  static const _muted = PdfColor.fromInt(0xFF5D6B7C);
  static const _danger = PdfColor.fromInt(0xFFC0392B);
  static const _good = PdfColor.fromInt(0xFF1E8449);

  /// One colour per day on the overview map, repeating after eight days.
  static const _dayColors = [
    PdfColor.fromInt(0xFF2B6FAB),
    PdfColor.fromInt(0xFFE67E22),
    PdfColor.fromInt(0xFF27AE60),
    PdfColor.fromInt(0xFF8E44AD),
    PdfColor.fromInt(0xFFC0392B),
    PdfColor.fromInt(0xFF16A085),
    PdfColor.fromInt(0xFFD4AC0D),
    PdfColor.fromInt(0xFF34495E),
  ];

  static PdfColor dayColor(int dayNumber) => _dayColors[(dayNumber - 1) % _dayColors.length];

  /// The maps the PDF draws, so the loader can fetch their tiles first.
  static List<PdfMapFrame> mapFrames(ItineraryPdfPlan plan) => [
        _overviewFrame(plan),
        for (final day in plan.days)
          if (day.stops.isNotEmpty) _dayFrame(day),
      ];

  static PdfMapFrame _overviewFrame(ItineraryPdfPlan plan) =>
      PdfMapFrame.fit([for (final day in plan.days) ..._pointsOf(day)], width: _contentWidth, height: _coverMapHeight);

  static PdfMapFrame _dayFrame(PlannedDay day) =>
      PdfMapFrame.fit(_pointsOf(day), width: _contentWidth, height: _dayMapHeight);

  static List<LatLng> _pointsOf(PlannedDay day) => [
        if (day.stops.isNotEmpty && day.start != null) LatLng(day.start!.lat, day.start!.lng),
        if (day.stops.isNotEmpty && day.end != null) LatLng(day.end!.lat, day.end!.lng),
        for (final stop in day.stops) stop.point,
        for (final leg in day.legs) ...leg.path,
      ];

  Future<Uint8List> build(
    Trip trip, {
    String languageCode = 'id',
    ItineraryPdfAssets assets = ItineraryPdfAssets.none,
    DateTime? now,
  }) {
    final plan = ItineraryPdfPlan.of(trip);
    final text = _Text(assets.hasFont);
    final fmt = _Formats(languageCode);

    final doc = pw.Document(
      title: text.clean(trip.title),
      creator: 'SmartTrip Batam',
      theme: assets.hasFont ? pw.ThemeData.withFont(base: assets.regular, bold: assets.bold) : null,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        maxPages: 200,
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SmartTrip Batam ${text.dot} ${text.clean(trip.title)}', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            ],
          ),
        ),
        build: (context) => [
          ..._cover(plan, assets, text, fmt),
          for (final day in plan.days) ...[
            pw.NewPage(),
            ..._daySection(plan, day, assets, text, fmt),
          ],
          pw.NewPage(),
          ..._practicalInfo(plan, assets, text, fmt, now ?? DateTime.now()),
        ],
      ),
    );
    return doc.save();
  }

  // --- cover ---

  List<pw.Widget> _cover(ItineraryPdfPlan plan, ItineraryPdfAssets assets, _Text text, _Formats fmt) {
    final trip = plan.trip;
    final lastDay = trip.dateOfDay(trip.numDays);
    final hotel = trip.hotel;

    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: const pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.all(pw.Radius.circular(14))),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SMARTTRIP BATAM ${text.dot} ITINERARY',
                style: pw.TextStyle(fontSize: 8, color: _sun, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
            pw.SizedBox(height: 6),
            pw.Text(text.clean(trip.title), style: pw.TextStyle(fontSize: 22, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${fmt.shortDate.format(trip.startDate)} - ${fmt.shortDate.format(lastDay)} ${text.dot} '
              'jam harian ${_hhmm(trip.dailyStartTime)} - ${_hhmm(trip.dailyEndTime)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300),
            ),
            if (hotel != null)
              pw.Text('Titik awal: ${text.clean(hotel.name)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300)),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        _stat('${trip.numDays}', 'hari'),
        _stat('${plan.stops.length}', 'tempat'),
        _stat('${fmt.km(plan.km)} km', 'jarak tempuh'),
        _stat(fmt.duration(plan.travelMinutes), 'di perjalanan'),
      ]),
      pw.SizedBox(height: 10),
      _budget(plan, fmt),
      pw.SizedBox(height: 12),
      _sectionTitle('Peta perjalanan'),
      pw.SizedBox(height: 6),
      _overviewFrame(plan).build(
        tiles: assets.tiles,
        routes: [
          for (final day in plan.days)
            for (final leg in day.legs) PdfMapRoute(leg.path, dayColor(day.day.dayNumber), dashed: !leg.isRoad),
        ],
        pins: [
          for (final day in plan.days)
            for (final stop in day.stops) PdfMapPin(stop.point, '${stop.number}', dayColor(day.day.dayNumber)),
          if (plan.trip.hotel case final start?) PdfMapPin(LatLng(start.lat, start.lng), 'A', _navy, square: true),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Wrap(spacing: 10, runSpacing: 4, children: [
        for (final day in plan.days)
          if (day.stops.isNotEmpty)
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Container(width: 9, height: 9, decoration: pw.BoxDecoration(color: dayColor(day.day.dayNumber), shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 3),
              pw.Text('Hari ${day.day.dayNumber}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ]),
        pw.Text('A = titik awal', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
      pw.SizedBox(height: 12),
      _composition(plan),
      if (assets.forecast.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _sectionTitle('Prakiraan cuaca'),
        pw.SizedBox(height: 6),
        pw.Wrap(spacing: 6, runSpacing: 6, children: [
          for (final day in plan.days)
            if (assets.forecast[_dateOnly(day.date)] case final forecast?) _weatherTile(day, forecast, text, fmt),
        ]),
      ],
    ];
  }

  pw.Widget _stat(String value, String label) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: const pw.BoxDecoration(color: _surface, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
          child: pw.Column(children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ]),
        ),
      );

  pw.Widget _budget(ItineraryPdfPlan plan, _Formats fmt) {
    final budget = plan.trip.budgetTotal;
    final cost = plan.costIdr;
    final over = cost > budget;
    final share = budget <= 0 ? 1.0 : (cost / budget).clamp(0.0, 1.0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Estimasi biaya tempat ${fmt.rupiah(cost)} dari anggaran ${fmt.rupiah(budget)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.Text(over ? 'Lebih ${fmt.rupiah(cost - budget)}' : 'Sisa ${fmt.rupiah(budget - cost)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: over ? _danger : _good)),
        ]),
        pw.SizedBox(height: 6),
        pw.Stack(children: [
          pw.Container(height: 7, decoration: const pw.BoxDecoration(color: _line, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)))),
          pw.Container(
            height: 7,
            width: (_contentWidth - 24) * share,
            decoration: pw.BoxDecoration(color: over ? _danger : _sea, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
          ),
        ]),
        pw.SizedBox(height: 5),
        pw.Text('Tiket dan biaya masuk tempat saja; penginapan, makan di luar daftar, dan transportasi belum termasuk.',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
      ]),
    );
  }

  pw.Widget _composition(ItineraryPdfPlan plan) {
    int count(bool Function(PlannedStop stop) test) => plan.countWhere(test);
    final groups = [
      ('Jenis tempat', [
        ('Wisata', count((stop) => stop.place?.type == 'attraction')),
        ('Kuliner', count((stop) => stop.place?.type == 'culinary')),
        ('Pin sendiri', count((stop) => stop.place?.placesId == null)),
      ]),
      ('Asal pilihan', [
        ('Pilihanmu', count((stop) => stop.item.isFromWishlist)),
        ('Rekomendasi', count((stop) => !stop.item.isFromWishlist)),
      ]),
      ('Suasana', [
        ('Outdoor', count((stop) => stop.place?.isOutdoor ?? false)),
        ('Indoor', count((stop) => stop.place?.placesId != null && !(stop.place?.isOutdoor ?? false))),
      ]),
    ];

    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      for (final (title, rows) in groups)
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: _surface, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _navySoft)),
              pw.SizedBox(height: 4),
              for (final (label, value) in rows)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _ink)),
                  pw.Text('$value', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
                ]),
            ]),
          ),
        ),
    ]);
  }

  pw.Widget _weatherTile(PlannedDay day, DayForecast forecast, _Text text, _Formats fmt) {
    return pw.Container(
      width: (_contentWidth - 6 * 6) / 7,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: forecast.isRainy ? const PdfColor.fromInt(0xFFFDECEA) : _surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(children: [
        pw.Text('Hari ${day.day.dayNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.Text(fmt.tinyDate.format(day.date), style: const pw.TextStyle(fontSize: 7, color: _muted)),
        pw.SizedBox(height: 3),
        pw.Text(weatherLabel(forecast.weatherCode), style: const pw.TextStyle(fontSize: 7.5, color: _ink), textAlign: pw.TextAlign.center),
        pw.Text('${forecast.minTemperature.round()}-${forecast.maxTemperature.round()}${text.degree}C',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.Text('Hujan ${forecast.rainChance}%',
            style: pw.TextStyle(fontSize: 7, color: forecast.isRainy ? _danger : _muted, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  // --- one day ---

  List<pw.Widget> _daySection(ItineraryPdfPlan plan, PlannedDay day, ItineraryPdfAssets assets, _Text text, _Formats fmt) {
    final color = dayColor(day.day.dayNumber);
    final forecast = assets.forecast[_dateOnly(day.date)];
    final warnings = _warnings(plan, day, forecast, fmt);

    return [
      pw.Row(children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Text('HARI ${day.day.dayNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(fmt.longDate.format(day.date), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy)),
        ),
        if (forecast != null)
          pw.Text(
            '${weatherLabel(forecast.weatherCode)} ${text.dot} ${forecast.minTemperature.round()}-${forecast.maxTemperature.round()}${text.degree}C '
            '${text.dot} hujan ${forecast.rainChance}%',
            style: pw.TextStyle(fontSize: 8.5, color: forecast.isRainy ? _danger : _muted),
          ),
      ]),
      pw.SizedBox(height: 10),
      if (day.stops.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: const pw.BoxDecoration(color: _surface, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
          child: pw.Text('Belum ada tempat pada hari ini. Buat atau lengkapi itinerary di aplikasi.',
              style: const pw.TextStyle(fontSize: 10, color: _muted)),
        )
      else ...[
        _dayFrame(day).build(
          tiles: assets.tiles,
          routes: [for (final leg in day.legs) PdfMapRoute(leg.path, color, dashed: !leg.isRoad)],
          pins: [
            if (day.end case final end? when day.end != day.start)
              PdfMapPin(LatLng(end.lat, end.lng), 'S', _navy, square: true),
            if (day.start case final start?) PdfMapPin(LatLng(start.lat, start.lng), 'A', _navy, square: true),
            for (final stop in day.stops) PdfMapPin(stop.point, '${stop.number}', color),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          day.end != day.start ? 'A = titik awal ${text.dot} S = titik selesai ${text.dot} angka = urutan kunjungan' : 'A = titik awal dan selesai ${text.dot} angka = urutan kunjungan',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          _dayFact('Jarak', '${fmt.km(day.km)} km'),
          _dayFact('Di perjalanan', fmt.duration(day.travelMinutes)),
          _dayFact('Di tempat', fmt.duration(day.visitMinutes)),
          _dayFact('Biaya tempat', fmt.rupiah(day.costIdr)),
          _dayFact('Selesai sekitar', ItineraryPdfPlan.clock(day.endMinute)),
        ]),
        if (warnings.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(9),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF6E5),
              // Square corners: the pdf package cannot round a one-sided border.
              border: pw.Border(left: pw.BorderSide(color: _sun, width: 3)),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              for (final warning in warnings)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Text('${text.bullet} $warning', style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                ),
            ]),
          ),
        ],
        pw.SizedBox(height: 10),
        if (day.start case final start?)
          _endpointRow(day.startMinute, 'Berangkat dari ${text.clean(start.name)}'),
        for (final stop in day.stops) _stopCard(stop, color, assets, text, fmt),
        if (day.end case final end?)
          _endpointRow(day.endMinute, 'Tiba di ${text.clean(end.name)}'
              '${day.legToEnd == null ? '' : ' (${fmt.km(day.legToEnd!.km)} km, ${fmt.duration(day.legToEnd!.minutes)})'}'),
      ],
    ];
  }

  List<String> _warnings(ItineraryPdfPlan plan, PlannedDay day, DayForecast? forecast, _Formats fmt) => [
        if (forecast != null && forecast.isRainy && day.outdoorCount > 0)
          'Prakiraan hujan ${forecast.rainChance}% dan ada ${day.outdoorCount} tempat outdoor. '
              'Siapkan payung, atau tukar tempat outdoor dengan tempat indoor lewat aplikasi.',
        if (day.overruns)
          'Jadwal diperkirakan selesai ${ItineraryPdfPlan.clock(day.endMinute)}, '
              'melewati jam selesai harian ${_hhmm(plan.trip.dailyEndTime)}.',
        if (day.legs.any((leg) => !leg.isRoad))
          'Sebagian rute digambar garis putus-putus karena rute jalannya belum ada; jarak dan waktunya perkiraan.',
      ];

  pw.Widget _dayFact(String label, String value) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: const pw.BoxDecoration(color: _surface, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Column(children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ]),
        ),
      );

  pw.Widget _endpointRow(int minute, String label) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 46,
            child: pw.Text(ItineraryPdfPlan.clock(minute), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
          ),
          pw.Container(
            width: 15,
            height: 15,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink))),
        ]),
      );

  pw.Widget _stopCard(PlannedStop stop, PdfColor color, ItineraryPdfAssets assets, _Text text, _Formats fmt) {
    final place = stop.place;
    final photo = place?.photoUrl == null ? null : assets.photos[place!.photoUrl];
    final navigateUrl = 'https://www.google.com/maps/dir/?api=1&destination=${stop.point.latitude},${stop.point.longitude}';
    final name = text.clean(place?.name ?? '-');

    final facts = [
      ?typeLabel(place),
      if (place?.kecamatan case final kecamatan? when kecamatan.isNotEmpty) text.clean(kecamatan),
      if (place?.rating case final rating? when rating > 0) '${text.star} ${rating.toStringAsFixed(1)}',
      switch (place?.estimatedCostIdr) {
        null => null,
        0 => 'Gratis',
        final cost => fmt.rupiah(cost),
      },
      '${stop.visitMinutes} mnt di sini',
    ].whereType<String>();

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(
          width: 38,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(ItineraryPdfPlan.clock(stop.arriveMinute), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.Text('s/d ${ItineraryPdfPlan.clock(stop.departMinute)}', style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ]),
        ),
        pw.Container(
          width: 17,
          height: 17,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          child: pw.Text('${stop.number}', style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 8),
        pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: photo == null
              ? pw.Container(
                  width: 46,
                  height: 46,
                  color: _surface,
                  alignment: pw.Alignment.center,
                  child: pw.Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _line)),
                )
              : pw.Image(pw.MemoryImage(photo), width: 46, height: 46, fit: pw.BoxFit.cover),
        ),
        pw.SizedBox(width: 9),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.UrlLink(
              destination: navigateUrl,
              child: pw.Text(name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            ),
            pw.SizedBox(height: 2),
            pw.Text(facts.join('  ${text.dot}  '), style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 3),
            pw.Wrap(spacing: 4, runSpacing: 3, children: [
              _badge(stop.item.isFromWishlist ? 'Pilihanmu' : 'Rekomendasi', stop.item.isFromWishlist ? _sea : _navySoft),
              if (place?.placesId != null) _badge((place?.isOutdoor ?? false) ? 'Outdoor' : 'Indoor', _muted),
              if (stop.item.isVisited) _badge('Sudah dikunjungi', _good),
            ]),
            if (stop.leg case final leg?) ...[
              pw.SizedBox(height: 3),
              pw.Text('${fmt.km(leg.km)} km ${text.dot} ${fmt.duration(leg.minutes)} dari titik sebelumnya',
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            ],
          ]),
        ),
        pw.SizedBox(width: 8),
        pw.Column(children: [
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: navigateUrl, width: 40, height: 40, drawText: false),
          pw.SizedBox(height: 2),
          pw.Text('Pindai untuk rute', style: const pw.TextStyle(fontSize: 5.5, color: _muted)),
        ]),
      ]),
    );
  }

  pw.Widget _badge(String label, PdfColor color) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.7),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(label, style: pw.TextStyle(fontSize: 7, color: color, fontWeight: pw.FontWeight.bold)),
      );

  // --- practical info ---

  List<pw.Widget> _practicalInfo(ItineraryPdfPlan plan, ItineraryPdfAssets assets, _Text text, _Formats fmt, DateTime now) {
    return [
      pw.Text('Info praktis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
      pw.SizedBox(height: 12),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _sectionTitle('Nomor darurat'),
            pw.SizedBox(height: 6),
            for (final (number, label) in const [
              ('112', 'Panggilan darurat (semua layanan)'),
              ('110', 'Polisi'),
              ('118 / 119', 'Ambulans'),
              ('113', 'Pemadam kebakaran'),
            ])
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Row(children: [
                  pw.SizedBox(
                    width: 62,
                    child: pw.Text(number, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _danger)),
                  ),
                  pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 9.5, color: _ink))),
                ]),
              ),
          ]),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _sectionTitle('Bawaan'),
            pw.SizedBox(height: 6),
            for (final item in checklist(plan, assets.forecast))
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Row(children: [
                  pw.Container(
                    width: 9,
                    height: 9,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _muted, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
                  pw.SizedBox(width: 7),
                  pw.Expanded(child: pw.Text(item, style: const pw.TextStyle(fontSize: 9.5, color: _ink))),
                ]),
              ),
          ]),
        ),
      ]),
      pw.SizedBox(height: 18),
      _sectionTitle('Catatan'),
      for (var line = 0; line < 8; line++)
        pw.Container(height: 24, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line)))),
      pw.SizedBox(height: 16),
      pw.Text(
        'Jam dan jarak adalah perkiraan dari rute di aplikasi dengan kecepatan rata-rata 27,5 km/jam, bukan kondisi lalu lintas saat itu. '
        'Pindai QR di setiap tempat untuk membuka navigasi Google Maps. '
        'Dibuat ${fmt.shortDate.format(now)} dengan SmartTrip Batam.',
        style: const pw.TextStyle(fontSize: 7.5, color: _muted),
      ),
    ];
  }

  /// What to pack, from the stops and the forecast.
  static List<String> checklist(ItineraryPdfPlan plan, Map<DateTime, DayForecast> forecast) {
    final stops = plan.stops.toList();
    final names = stops.map((stop) => stop.place?.name.toLowerCase() ?? '');
    final rainy = forecast.values.any((day) => day.isRainy);
    final outdoor = stops.any((stop) => stop.place?.isOutdoor ?? false);
    final water = names.any((name) => name.contains('pantai') || name.contains('pulau') || name.contains('beach'));

    return [
      'KTP atau identitas lain',
      'Ponsel, charger, dan power bank',
      'Uang tunai untuk tiket, parkir, dan jajanan',
      if (rainy) 'Payung atau jas hujan',
      if (outdoor) 'Tabir surya, topi, dan air minum',
      if (water) 'Baju ganti dan sandal untuk pantai',
      if (plan.trip.numDays > 1) 'Obat-obatan pribadi',
    ];
  }

  pw.Widget _sectionTitle(String title) =>
      pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _sea, letterSpacing: 1));

  static String? typeLabel(TripPlace? place) => switch (place) {
        null => null,
        TripPlace(placesId: null) => 'Pin sendiri',
        TripPlace(type: 'attraction') => 'Wisata',
        TripPlace(type: 'culinary') => 'Kuliner',
        TripPlace(type: 'lodging') => 'Penginapan',
        _ => null,
      };

  /// WMO weather codes as used by Open-Meteo.
  static String weatherLabel(int code) => switch (code) {
        0 => 'Cerah',
        1 || 2 => 'Cerah berawan',
        3 => 'Berawan',
        45 || 48 => 'Berkabut',
        >= 51 && <= 57 => 'Gerimis',
        >= 61 && <= 67 => 'Hujan',
        >= 80 && <= 82 => 'Hujan lokal',
        >= 95 => 'Badai petir',
        _ => 'Berawan',
      };

  static String _hhmm(String time) => time.length >= 5 ? time.substring(0, 5) : time;

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

/// Text helpers that depend on the font: the app font has symbols the
/// built-in PDF font (Latin-1 only) does not.
class _Text {
  _Text(this.hasFont);

  final bool hasFont;

  String get dot => hasFont ? '·' : '-';
  String get bullet => hasFont ? '•' : '-';
  String get star => hasFont ? '★' : 'Rating';
  String get degree => '°';

  /// Characters the font cannot draw (emoji, other scripts) are swapped or
  /// dropped instead of breaking the export.
  String clean(String value) {
    const swaps = {'–': '-', '—': '-', '‘': "'", '’': "'", '“': '"', '”': '"'};
    const fontSymbols = {0x2022, 0x2192, 0x2605, 0xB7};
    final out = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (swaps[char] case final swap?) {
        out.write(swap);
      } else if (rune <= 0xFF || (hasFont && (rune <= 0x24F || fontSymbols.contains(rune)))) {
        out.write(char);
      }
    }
    return out.toString().trim();
  }
}

class _Formats {
  _Formats(String languageCode)
      : longDate = DateFormat('EEEE, d MMMM y', languageCode),
        shortDate = DateFormat('d MMM y', languageCode),
        tinyDate = DateFormat('d MMM', languageCode);

  final DateFormat longDate;
  final DateFormat shortDate;
  final DateFormat tinyDate;
  final _money = NumberFormat.decimalPattern('id');
  final _distance = NumberFormat('0.0', 'id');

  String rupiah(int value) => 'Rp ${_money.format(value)}';
  String km(double value) => _distance.format(value);

  String duration(int minutes) {
    if (minutes < 60) return '$minutes mnt';
    final rest = minutes % 60;
    return rest == 0 ? '${minutes ~/ 60} jam' : '${minutes ~/ 60} j $rest mnt';
  }
}
