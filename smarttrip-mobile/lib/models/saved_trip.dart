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
    this.photoUrls = const [],
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

  /// Photos of up to four places in the trip, shown as the card's mosaic.
  final List<String> photoUrls;

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

// Sample photos (real place photos on the API server) until the trip list
// comes from the API.
const _photoBase = 'https://smarttrip.filltech.network/storage/place-photos';

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
      photoUrls: [
        '$_photoBase/32/e50a96ce-0f53-4bae-a397-36945ff538d3.jpg',
        '$_photoBase/30/44dc090c-edbc-4b59-9dc9-b8935ffc4b13.jpg',
        '$_photoBase/32/85f90e09-e82f-4186-9bf2-8b83bf9420ff.jpg',
        '$_photoBase/3/f724d97b-323b-4444-8c09-f40f3768ce99.jpg',
      ],
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
      photoUrls: [
        '$_photoBase/30/d243820d-7fba-4866-b63a-91833b82d8fc.jpg',
        '$_photoBase/32/9d6298b8-c2f8-4d7b-9a07-3c851ef04330.jpg',
      ],
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
      photoUrls: [
        '$_photoBase/30/090c86dc-f4ec-4e06-ad0c-15e08243201f.jpg',
        '$_photoBase/32/7955abad-ff53-4ae7-93cf-849a7c754d9c.jpg',
        '$_photoBase/30/44dc090c-edbc-4b59-9dc9-b8935ffc4b13.jpg',
      ],
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
      photoUrls: [
        '$_photoBase/3/f724d97b-323b-4444-8c09-f40f3768ce99.jpg',
      ],
    ),
  ];

  static List<TripModel> byStatus(TripStatus status) =>
      mockTrips.where((t) => t.status == status).toList();
}
