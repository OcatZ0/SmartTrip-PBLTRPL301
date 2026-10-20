import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/place.dart';

class CatalogPhoto extends StatelessWidget {
  const CatalogPhoto({super.key, required this.place, this.iconSize = 28, this.iconAlignment = Alignment.center});

  final CatalogPlace place;
  final double iconSize;

  /// Where the placeholder icon sits, e.g. higher up on the detail hero so
  /// the title over the bottom of the photo does not cover it.
  final Alignment iconAlignment;

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
      child: Align(
        alignment: iconAlignment,
        child: Icon(_icon(place), size: iconSize, color: Colors.white.withValues(alpha: 0.55)),
      ),
    );

    final url = place.photoUrl;
    if (url == null) return placeholder;

    return network(url, placeholder: placeholder);
  }

  /// A place photo decoded at about the size it is shown, not at full
  /// resolution (source photos are often 2000-4000px wide, which makes the
  /// list stutter while they decode). The placeholder shows until the first
  /// frame, without a rebuild for every downloaded chunk.
  static Widget network(String url, {required Widget placeholder}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        // BoxFit.cover crops: width * 1.8 leaves room for landscape photos up
        // to about 16:9 in a box taller than the photo's own shape.
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : null;
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : null;
        final target = [if (width != null) width, if (height != null) height * 1.8];
        final cacheWidth = target.isEmpty ? null : (target.reduce(math.max) * pixelRatio).round();

        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => placeholder,
          frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
              wasSynchronouslyLoaded || frame != null ? child : placeholder,
        );
      },
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
