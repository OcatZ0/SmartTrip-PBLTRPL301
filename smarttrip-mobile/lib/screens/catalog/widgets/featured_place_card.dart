import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import 'catalog_photo.dart';
import 'place_bits.dart';

class FeaturedPlaceCard extends StatelessWidget {
  const FeaturedPlaceCard({
    super.key,
    required this.place,
    required this.isSaved,
    required this.onToggleSaved,
    this.onTap,
  });

  static const width = 248.0;
  static const height = 168.0;

  final CatalogPlace place;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  /// Opens the place detail (B2).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final kecamatan = place.kecamatan;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CatalogPhoto(place: place, iconSize: 40),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xD90A2440), Color(0x000A2440)],
                  stops: [0, 0.65],
                ),
              ),
            ),
            // Below the heart, so the heart keeps its own tap.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CatalogHeartButton(isSaved: isSaved, onPressed: onToggleSaved, onPhoto: true),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      placeCategoryLabel(place, l10n, languageCode),
                      style: appText(11, FontWeight.w600, Colors.white, height: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(16, FontWeight.w700, Colors.white, height: 22),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(child: PlaceRating(place: place, onPhoto: true)),
                      if (kecamatan != null && kecamatan.isNotEmpty) ...[
                        _dot(),
                        Flexible(
                          child: Text(
                            kecamatan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(12, FontWeight.w500, Colors.white.withValues(alpha: 0.85), height: 16),
                          ),
                        ),
                      ],
                      _dot(),
                      Text(
                        placePrice(place, l10n),
                        style: appText(12, FontWeight.w700, AppColors.sun400, height: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: appText(12, FontWeight.w700, Colors.white.withValues(alpha: 0.7))),
    );
  }
}
