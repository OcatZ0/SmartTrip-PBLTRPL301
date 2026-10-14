import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../place_detail_screen.dart';
import 'catalog_style.dart';

/// Container transform from a catalog card into the place detail (B2): the
/// card grows into the detail page and shrinks back on return. [builder]
/// gets the callback that opens it, to use as the card's onTap.
class PlaceOpenContainer extends StatelessWidget {
  const PlaceOpenContainer({
    super.key,
    required this.placesId,
    required this.radius,
    required this.builder,
    this.closedColor = Colors.transparent,
  });

  final int placesId;
  final double radius;
  final Color closedColor;
  final Widget Function(VoidCallback open) builder;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      closedElevation: 0,
      openElevation: 0,
      closedColor: closedColor,
      openColor: CatalogColors.navy900,
      middleColor: CatalogColors.navy900,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      closedBuilder: (context, open) => builder(open),
      openBuilder: (context, _) => PlaceDetailScreen(placesId: placesId),
    );
  }
}
