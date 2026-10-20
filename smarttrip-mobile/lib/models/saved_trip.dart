import 'dart:math' as math;

import '../core/config/app_config.dart';

/// Where a saved trip stands, from `summary.status` of `GET /api/trips`.
enum TripStatus {
  berlangsung,
  akanDatang,
  selesai,
  draft;

  String get label {
    switch (this) {
      case TripStatus.berlangsung:
        return 'Berlangsung';
      case TripStatus.akanDatang:
        return 'Akan Datang';
      case TripStatus.selesai:
        return 'Selesai';
      case TripStatus.draft:
        return 'Draft';
    }
  }

  static TripStatus fromApi(String? value) => switch (value) {
        'berlangsung' => TripStatus.berlangsung,
        'akan_datang' => TripStatus.akanDatang,
        'selesai' => TripStatus.selesai,
        _ => TripStatus.draft,
      };
}

/// One card on Trip Tersimpan: a trip of `GET /api/trips` with its summary.
class TripModel {
  const TripModel({
    required this.id,
    required this.title,
    required this.status,
    required this.numDays,
    this.startDate,
    this.currentDay = 1,
    this.numDestinations = 0,
    this.visitedCount = 0,
    this.budgetSpent = 0,
    this.budgetTotal = 0,
    this.wishlistCount = 0,
    this.photoUrls = const [],
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    int toInt(Object? value) => (value as num?)?.toInt() ?? 0;

    return TripModel(
      id: json['trips_id'] as int,
      title: (json['title'] as String?)?.trim().isNotEmpty == true ? json['title'] as String : 'Trip tanpa judul',
      status: TripStatus.fromApi(summary['status'] as String?),
      numDays: toInt(json['num_days']),
      startDate: DateTime.tryParse('${json['start_date'] ?? ''}'),
      currentDay: math.max(1, toInt(summary['current_day'])),
      numDestinations: toInt(summary['places_count']),
      visitedCount: toInt(summary['visited_count']),
      budgetSpent: toInt(summary['spent_estimate_idr']),
      budgetTotal: toInt(json['budget_total']),
      wishlistCount: toInt(summary['wishlist_count']),
      photoUrls: (summary['photo_urls'] as List? ?? const [])
          .map((url) => AppConfig.resolveMediaUrl(url?.toString()))
          .whereType<String>()
          .toList(),
    );
  }

  final int id;
  final String title;
  final TripStatus status;
  final int numDays;
  final DateTime? startDate;

  /// The trip day today is, while the trip is on.
  final int currentDay;

  /// Stops in the generated itinerary.
  final int numDestinations;
  final int visitedCount;

  /// Estimated cost of the visited places (the app does not track real spending).
  final int budgetSpent;
  final int budgetTotal;
  final int wishlistCount;

  /// Photos of up to four places in the trip, shown as the card's mosaic.
  final List<String> photoUrls;

  DateTime? get endDate => startDate?.add(Duration(days: (numDays < 1 ? 1 : numDays) - 1));

  /// Format Rp1.850.000
  static String rupiahFormat(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) buf.write('.');
    }
    return 'Rp${buf.toString().split('').reversed.join('')}';
  }

  String get budgetSpentLabel => rupiahFormat(budgetSpent);
  String get budgetTotalLabel => rupiahFormat(budgetTotal);
}
