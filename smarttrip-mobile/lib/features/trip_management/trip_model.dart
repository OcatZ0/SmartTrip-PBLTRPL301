// Domain model statis untuk fitur Trip Tersimpan

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
}

class TripModel {
  const TripModel({
    required this.id,
    required this.title,
    required this.status,
    required this.dateRange,
    required this.numPersons,
    required this.numDestinations,
    this.numDays = 1,
    this.currentDay = 1,
    this.visitedCount = 0,
    this.budgetSpent = 0,
    this.budgetTotal = 0,
    this.wishlistCount = 0,
  });

  final int id;
  final String title;
  final TripStatus status;
  final String dateRange;
  final int numPersons;
  final int numDestinations;
  final int numDays;
  final int currentDay;
  final int visitedCount;
  final int budgetSpent;
  final int budgetTotal;
  final int wishlistCount;

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

/// Data statis
class TripData {
  static const List<TripModel> mockTrips = [
    // ─── TAB: BERLANGSUNG ─────────────────────────────
    TripModel(
      id: 1,
      title: 'Wisata Batam – Long Weekend',
      status: TripStatus.berlangsung,
      dateRange: '12–14 Sep 2026',
      numPersons: 4,
      numDestinations: 6,
      numDays: 3,
      currentDay: 2,
      visitedCount: 3,
      budgetSpent: 1850000,
      budgetTotal: 2500000,
    ),

    // ─── TAB: AKAN DATANG ─────────────────────────────
    TripModel(
      id: 2,
      title: 'Trip Kuliner & Pantai',
      status: TripStatus.akanDatang,
      dateRange: '28–29 Sep 2026',
      numPersons: 2,
      numDestinations: 5,
      numDays: 2,
      currentDay: 1,
      budgetTotal: 1200000,
    ),

    // ─── TAB: SELESAI ─────────────────────────────────
    TripModel(
      id: 3,
      title: 'Explore Batam Bersama Keluarga',
      status: TripStatus.selesai,
      dateRange: '2–4 Agu 2026',
      numPersons: 5,
      numDestinations: 7,
      numDays: 3,
      currentDay: 3,
      visitedCount: 7,
      budgetSpent: 3100000,
      budgetTotal: 3500000,
    ),

    // ─── TAB: DRAFT ───────────────────────────────────
    TripModel(
      id: 4,
      title: 'Trip ke Nagoya & Sekitarnya',
      status: TripStatus.draft,
      dateRange: 'Tanggal belum ditentukan',
      numPersons: 2,
      numDestinations: 3,
      numDays: 1,
      wishlistCount: 3,
    ),
  ];

  static List<TripModel> byStatus(TripStatus status) =>
      mockTrips.where((t) => t.status == status).toList();
}
