import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/trip.dart';

/// Builds the itinerary PDF on the device from the trip already loaded by the
/// itinerary screen (UC-018 Mengekspor Itinerary ke PDF). There is no server
/// call, so the export also works offline.
class ItineraryPdfService {
  const ItineraryPdfService();

  Future<Uint8List> build(Trip trip, {String languageCode = 'id'}) {
    final date = DateFormat('EEEE, d MMMM y', languageCode);
    final shortDate = DateFormat('d MMM y', languageCode);
    final money = NumberFormat.decimalPattern('id');
    final lastDay = trip.dateOfDay(trip.numDays);
    String hhmm(String time) => time.length >= 5 ? time.substring(0, 5) : time;
    String rupiah(int value) => 'Rp ${money.format(value)}';

    final doc = pw.Document(title: _clean(trip.title), creator: 'SmartTrip Batam');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SmartTrip Batam', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
        build: (context) => [
          pw.Text(_clean(trip.title), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('${shortDate.format(trip.startDate)} - ${shortDate.format(lastDay)}'),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: const {0: pw.FixedColumnWidth(110), 1: pw.FlexColumnWidth()},
            children: [
              for (final row in [
                ('Jumlah hari', '${trip.numDays} hari'),
                ('Anggaran', rupiah(trip.budgetTotal)),
                ('Jam harian', '${hhmm(trip.dailyStartTime)} - ${hhmm(trip.dailyEndTime)}'),
                if (trip.hotel != null) ('Penginapan', _clean(trip.hotel!.name)),
              ])
                pw.TableRow(children: [
                  pw.Text(row.$1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(row.$2),
                ]),
            ],
          ),
          for (final day in trip.days) ...[
            pw.SizedBox(height: 18),
            pw.Text('Hari ${day.dayNumber} - ${date.format(trip.dateOfDay(day.dayNumber))}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (day.start != null) pw.Text('Mulai dari: ${_clean(day.start!.name)}'),
            pw.SizedBox(height: 6),
            if (day.items.isEmpty)
              pw.Text('Belum ada tempat pada hari ini.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: const ['No', 'Tempat', 'Lokasi', 'Durasi', 'Estimasi biaya'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F4C81)),
                cellStyle: const pw.TextStyle(fontSize: 9),
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FixedColumnWidth(52),
                  4: pw.FixedColumnWidth(80),
                },
                data: [
                  for (final (i, item) in day.items.indexed)
                    [
                      '${i + 1}',
                      _clean(item.place?.name ?? '-'),
                      _clean(item.place?.kecamatan ?? item.place?.address ?? '-'),
                      item.place?.estimatedVisitMinutes == null ? '-' : '${item.place!.estimatedVisitMinutes} menit',
                      switch (item.place?.estimatedCostIdr) {
                        null => '-',
                        0 => 'Gratis',
                        final cost => rupiah(cost),
                      },
                    ],
                ],
              ),
            if (day.end != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Selesai di: ${_clean(day.end!.name)}'),
            ],
          ],
        ],
      ),
    );
    return doc.save();
  }

  /// The built-in PDF fonts only cover Latin-1, so other characters (smart
  /// quotes, dashes, emoji) are swapped or dropped instead of failing to draw.
  static String _clean(String text) {
    const swaps = {'–': '-', '—': '-', '‘': "'", '’': "'", '“': '"', '”': '"'};
    final out = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      out.write(swaps[char] ?? (rune <= 0xFF ? char : ''));
    }
    return out.toString();
  }
}
