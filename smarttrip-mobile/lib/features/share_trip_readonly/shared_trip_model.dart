enum BadgeCategory {
  rekomendasi,
  wishlist,
  indoorRain,
  goldenHour;
}

class SharedDestinationItem {
  const SharedDestinationItem({
    required this.orderNumber,
    required this.time,
    required this.title,
    required this.badgeText,
    required this.badgeCategory,
    required this.duration,
    required this.highlightText,
    required this.imageUrl,
    this.transitInfo,
  });

  final int orderNumber;
  final String time;
  final String title;
  final String badgeText;
  final BadgeCategory badgeCategory;
  final String duration;
  final String highlightText;
  final String imageUrl;
  final String? transitInfo; // Contoh: '25 menit berkendara (12 km)'
}

class DaySchedule {
  const DaySchedule({
    required this.dayNumber,
    required this.dateLabel,
    required this.weatherTemp,
    required this.weatherLocation,
    required this.weatherCondition,
    required this.humidity,
    required this.rainPrediction,
    required this.destinations,
  });

  final int dayNumber;
  final String dateLabel;
  final String weatherTemp;
  final String weatherLocation;
  final String weatherCondition;
  final String humidity;
  final String rainPrediction;
  final List<SharedDestinationItem> destinations;
}

class SharedTripData {
  static const String tripTitle = 'Eksplorasi Bahari Batam (3 Hari)';
  static const String dateRange = '18 - 20 Mei 2025';
  static const String sharedBy = 'DIBAGIKAN OLEH NERO';

  static const List<DaySchedule> schedules = [
    // ── HARI 1 ─────────────────────────────────────────────────────────────
    DaySchedule(
      dayNumber: 1,
      dateLabel: 'Hari 1 (18 Mei)',
      weatherTemp: '31°C',
      weatherLocation: 'Batam Centre',
      weatherCondition: 'Cuaca Kondusif untuk Wisata Terbuka',
      humidity: '78%',
      rainPrediction:
          'Prediksi hujan ringan pukul 14.00 — rekomendasi transit indoor disiapkan cerdas.',
      destinations: [
        SharedDestinationItem(
          orderNumber: 1,
          time: '09:30',
          title: 'Welcome to Batam...',
          badgeText: 'Rekomendasi',
          badgeCategory: BadgeCategory.rekomendasi,
          duration: '45 menit',
          highlightText: 'Foto Ikonik',
          imageUrl:
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300&auto=format&fit=crop&q=80',
          transitInfo: '25 menit berkendara (12 km)',
        ),
        SharedDestinationItem(
          orderNumber: 2,
          time: '11:30',
          title: 'Golden Prawn 933...',
          badgeText: '♥ Wishlist',
          badgeCategory: BadgeCategory.wishlist,
          duration: '1 jam 30 menit',
          highlightText: 'Makan Siang',
          imageUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300&auto=format&fit=crop&q=80',
          transitInfo: '20 menit berkendara (8.4 km)',
        ),
        SharedDestinationItem(
          orderNumber: 3,
          time: '14:30',
          title: 'Nagoya Hill Shopping',
          badgeText: '☂ Rekomendasi (Indoor Hujan)',
          badgeCategory: BadgeCategory.indoorRain,
          duration: '2 jam',
          highlightText: 'Belanja & Relaksasi',
          imageUrl:
              'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?w=300&auto=format&fit=crop&q=80',
          transitInfo: '30 menit berkendara (19 km via Trans Barelang)',
        ),
        SharedDestinationItem(
          orderNumber: 4,
          time: '17:00',
          title: 'Jembatan Barelang &',
          badgeText: '★ Wishlist • Golden Hour',
          badgeCategory: BadgeCategory.goldenHour,
          duration: '1 jam 30 menit',
          highlightText: 'Momen Sunset 17:45',
          imageUrl:
              'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=300&auto=format&fit=crop&q=80',
        ),
      ],
    ),

    // ── HARI 2 ─────────────────────────────────────────────────────────────
    DaySchedule(
      dayNumber: 2,
      dateLabel: 'Hari 2 (19 Mei)',
      weatherTemp: '29°C',
      weatherLocation: 'Nongsa Coast',
      weatherCondition: 'Cerah Berawan, Ideal Wisata Pantai',
      humidity: '72%',
      rainPrediction:
          'Kemungkinan hujan sangat rendah. Disarankan menggunakan tabir surya.',
      destinations: [
        SharedDestinationItem(
          orderNumber: 1,
          time: '08:30',
          title: 'Pantai Nongsa',
          badgeText: 'Rekomendasi',
          badgeCategory: BadgeCategory.rekomendasi,
          duration: '2 jam',
          highlightText: 'Pemandangan Singapura',
          imageUrl:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&auto=format&fit=crop&q=80',
          transitInfo: '15 menit berkendara (6 km)',
        ),
        SharedDestinationItem(
          orderNumber: 2,
          time: '11:00',
          title: 'Kelong Seafood Nongsa',
          badgeText: '♥ Wishlist',
          badgeCategory: BadgeCategory.wishlist,
          duration: '1 jam 30 menit',
          highlightText: 'Kuliner Tradisional',
          imageUrl:
              'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=300&auto=format&fit=crop&q=80',
        ),
      ],
    ),

    // ── HARI 3 ─────────────────────────────────────────────────────────────
    DaySchedule(
      dayNumber: 3,
      dateLabel: 'Hari 3 (20 Mei)',
      weatherTemp: '30°C',
      weatherLocation: 'Batam Kota',
      weatherCondition: 'Cerah, Cocok Belanja Oleh-Oleh',
      humidity: '70%',
      rainPrediction: 'Kondisi cuaca stabil sepanjang hari.',
      destinations: [
        SharedDestinationItem(
          orderNumber: 1,
          time: '10:00',
          title: 'Pusat Oleh-Oleh Batam',
          badgeText: 'Rekomendasi',
          badgeCategory: BadgeCategory.rekomendasi,
          duration: '1 jam 30 menit',
          highlightText: 'Lapis Legit & Kuliner',
          imageUrl:
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300&auto=format&fit=crop&q=80',
        ),
      ],
    ),
  ];
}
