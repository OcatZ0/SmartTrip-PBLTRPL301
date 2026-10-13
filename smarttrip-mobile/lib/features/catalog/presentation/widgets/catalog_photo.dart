import 'package:flutter/material.dart';

import '../../data/catalog_models.dart';

class CatalogPhoto extends StatelessWidget {
  const CatalogPhoto({super.key, required this.place, this.iconSize = 28});

  final CatalogPlace place;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palette(place),
        ),
      ),
      child: Center(child: Icon(_icon(place), size: iconSize, color: Colors.white.withValues(alpha: 0.55))),
    );

    final url = place.photoUrl;
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }

  static String? _slug(CatalogPlace place) => place.categories.isEmpty ? null : place.categories.first.slug;

  static List<Color> _palette(CatalogPlace place) {
    if (place.isLodging) return const [Color(0xFF9FB6CF), Color(0xFF3F5873)];
    if (place.type == 'culinary') return const [Color(0xFFFFB38A), Color(0xFF8F2F1C)];

    return switch (_slug(place)) {
      'pantai' || 'alam' => const [Color(0xFF9FD3EC), Color(0xFF2B6FAB)],
      'landmark' || 'spot-foto' => const [Color(0xFFF6B03C), Color(0xFF16476D)],
      'religi' || 'sejarah' => const [Color(0xFFF1DCA7), Color(0xFF7A5226)],
      'kuliner-seafood' || 'kuliner-lokal' => const [Color(0xFFFFB38A), Color(0xFF8F2F1C)],
      'belanja' || 'rekreasi' => const [Color(0xFFC9B6E8), Color(0xFF4B3B7A)],
      _ => const [Color(0xFF4F8FB8), Color(0xFF0A2440)],
    };
  }

  static IconData _icon(CatalogPlace place) {
    if (place.isLodging) return Icons.hotel_outlined;
    if (place.type == 'culinary') return Icons.restaurant;

    return switch (_slug(place)) {
      'pantai' => Icons.waves,
      'alam' => Icons.park_outlined,
      'sejarah' => Icons.account_balance_outlined,
      'religi' => Icons.mosque_outlined,
      'landmark' => Icons.location_city,
      'spot-foto' => Icons.photo_camera_outlined,
      'rekreasi' => Icons.attractions_outlined,
      'belanja' => Icons.shopping_bag_outlined,
      'kuliner-seafood' => Icons.set_meal_outlined,
      'kuliner-lokal' => Icons.restaurant,
      _ => Icons.landscape_outlined,
    };
  }
}
