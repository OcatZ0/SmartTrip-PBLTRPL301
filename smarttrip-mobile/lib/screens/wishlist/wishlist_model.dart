import 'package:flutter/material.dart';

enum WishlistCategory {
  semua('Semua', Icons.explore_outlined),
  pantai('Pantai & Bahari', Icons.waves_rounded),
  kuliner('Kuliner & Resto', Icons.restaurant_rounded),
  sejarah('Ikon & Sejarah', Icons.account_balance_rounded),
  belanja('Belanja & Hiburan', Icons.shopping_bag_outlined);

  const WishlistCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum WishlistSort {
  baruDisimpan('Baru Disimpan'),
  ratingTertinggi('Rating Tertinggi'),
  namaAZ('Nama (A-Z)'),
  terdekat('Terdekat');

  const WishlistSort(this.label);
  final String label;
}

class WishlistPlaceItem {
  WishlistPlaceItem({
    required this.id,
    required this.name,
    required this.categoryGroup,
    required this.badge1Text,
    required this.badge1Icon,
    required this.badge2Text,
    required this.badge2Color,
    required this.imageUrl,
    required this.location,
    required this.highlightBadge,
    required this.rating,
    required this.reviewCount,
    this.priceInfo,
    this.hoursInfo,
    this.facilityInfo,
    required this.savedDate,
    required this.distanceKm,
    this.isSaved = true,
  });

  final int id;
  final String name;
  final WishlistCategory categoryGroup;
  final String badge1Text;
  final IconData badge1Icon;
  final String badge2Text;
  final Color badge2Color;
  final String imageUrl;
  final String location;
  final String highlightBadge;
  final double rating;
  final String reviewCount;
  final String? priceInfo;
  final String? hoursInfo;
  final String? facilityInfo;
  final DateTime savedDate;
  final double distanceKm;
  bool isSaved;

  WishlistPlaceItem copyWith({
    bool? isSaved,
  }) {
    return WishlistPlaceItem(
      id: id,
      name: name,
      categoryGroup: categoryGroup,
      badge1Text: badge1Text,
      badge1Icon: badge1Icon,
      badge2Text: badge2Text,
      badge2Color: badge2Color,
      imageUrl: imageUrl,
      location: location,
      highlightBadge: highlightBadge,
      rating: rating,
      reviewCount: reviewCount,
      priceInfo: priceInfo,
      hoursInfo: hoursInfo,
      facilityInfo: facilityInfo,
      savedDate: savedDate,
      distanceKm: distanceKm,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static List<WishlistPlaceItem> initialItems() {
    return [
      WishlistPlaceItem(
        id: 1,
        name: 'Wey Wey Seafood Harbour Bay',
        categoryGroup: WishlistCategory.kuliner,
        badge1Text: 'Kuliner Seafood',
        badge1Icon: Icons.restaurant_rounded,
        badge2Text: 'Tepi Laut',
        badge2Color: const Color(0xFF0284C7),
        imageUrl:
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80',
        location: 'Batu Ampar, Batam',
        highlightBadge: '1.2 km dari Feri Harbour Bay',
        rating: 4.7,
        reviewCount: '1.8k',
        priceInfo: 'Rp 85.000 – 150.000 / orang',
        hoursInfo: 'Buka s/d 23:00',
        savedDate: DateTime.now().subtract(const Duration(hours: 2)),
        distanceKm: 1.2,
      ),
      WishlistPlaceItem(
        id: 2,
        name: 'Jembatan Barelang',
        categoryGroup: WishlistCategory.sejarah,
        badge1Text: 'Ikon Batam',
        badge1Icon: Icons.tour_rounded,
        badge2Text: 'Akses Gratis',
        badge2Color: const Color(0xFF92400E),
        imageUrl:
            'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=800&auto=format&fit=crop&q=80',
        location: 'Barelang, Batam',
        highlightBadge: 'Spot Sunset Terbaik',
        rating: 4.8,
        reviewCount: '3.4k',
        hoursInfo: 'Buka 24 Jam',
        facilityInfo: 'Tersedia Parkir & Jagung Bakar',
        savedDate: DateTime.now().subtract(const Duration(hours: 6)),
        distanceKm: 18.5,
      ),
      WishlistPlaceItem(
        id: 3,
        name: 'Pulau Ranoh',
        categoryGroup: WishlistCategory.pantai,
        badge1Text: 'Pulau Tropis',
        badge1Icon: Icons.waves_rounded,
        badge2Text: 'Wisata Bahari',
        badge2Color: const Color(0xFF0369A1),
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
        location: 'Galang, Batam',
        highlightBadge: 'Tur Snorkeling & Glamping',
        rating: 4.9,
        reviewCount: '1.2k',
        priceInfo: 'Rp 350.000 / orang',
        facilityInfo: 'Termasuk Speedboat & Makan Siang',
        savedDate: DateTime.now().subtract(const Duration(days: 1)),
        distanceKm: 42.0,
      ),
      WishlistPlaceItem(
        id: 4,
        name: 'Pantai Viovio',
        categoryGroup: WishlistCategory.pantai,
        badge1Text: 'Pantai Pasir Putih',
        badge1Icon: Icons.beach_access_rounded,
        badge2Text: 'Spot Ayunan Laut',
        badge2Color: const Color(0xFF0F766E),
        imageUrl:
            'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?w=800&auto=format&fit=crop&q=80',
        location: 'Galang Baru, Batam',
        highlightBadge: 'Sunset View & Gazebo',
        rating: 4.6,
        reviewCount: '890',
        priceInfo: 'Rp 15.000 / orang',
        hoursInfo: 'Buka 06:00 – 19:00',
        savedDate: DateTime.now().subtract(const Duration(days: 2)),
        distanceKm: 48.0,
      ),
      WishlistPlaceItem(
        id: 5,
        name: 'Nagoya Hill Shopping Mall',
        categoryGroup: WishlistCategory.belanja,
        badge1Text: 'Belanja & Mall',
        badge1Icon: Icons.shopping_bag_outlined,
        badge2Text: 'Pusat Oleh-Oleh',
        badge2Color: const Color(0xFF6B21A8),
        imageUrl:
            'https://images.unsplash.com/photo-1567449303078-57ad995bd301?w=800&auto=format&fit=crop&q=80',
        location: 'Lubuk Baja, Batam',
        highlightBadge: 'Pusat Elektronik & Mode',
        rating: 4.5,
        reviewCount: '2.5k',
        hoursInfo: 'Buka 10:00 – 22:00',
        facilityInfo: 'Area Kuliner & Bioskop Lengkap',
        savedDate: DateTime.now().subtract(const Duration(days: 3)),
        distanceKm: 3.5,
      ),
      WishlistPlaceItem(
        id: 6,
        name: 'Kelong Seafood Restaurant Piayu',
        categoryGroup: WishlistCategory.kuliner,
        badge1Text: 'Restoran Apung',
        badge1Icon: Icons.restaurant_rounded,
        badge2Text: 'Seafood Segar',
        badge2Color: const Color(0xFF0284C7),
        imageUrl:
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80',
        location: 'Sei Beduk, Batam',
        highlightBadge: 'Kepiting Saus Padang & Gonggong',
        rating: 4.7,
        reviewCount: '920',
        priceInfo: 'Rp 75.000 – 130.000 / orang',
        hoursInfo: 'Buka 10:00 – 21:00',
        savedDate: DateTime.now().subtract(const Duration(days: 4)),
        distanceKm: 14.0,
      ),
    ];
  }
}
