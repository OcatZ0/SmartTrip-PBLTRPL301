import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import 'catalog_photo.dart';
import 'place_bits.dart';

class PlaceGridCard extends StatelessWidget {
  const PlaceGridCard({
    super.key,
    required this.place,
    required this.isSaved,
    required this.onToggleSaved,
    this.onTap,
    this.pickedLabel,
  });

  static const height = 232.0;
  static const _photoHeight = 118.0;

  final CatalogPlace place;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  /// Opens the place detail (B2).
  final VoidCallback? onTap;

  /// Trip step 2: set when the place is in the trip wishlist ("Terpilih"),
  /// which adds a badge on the photo and a blue border. Null in the catalog.
  final String? pickedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final knownPrice = place.estimatedCostIdr != null;
    final priceLabel = switch (place.estimatedCostIdr) {
      null => l10n.catalogPriceUnknownLabel,
      0 => l10n.catalogPriceFreeLabel,
      _ => l10n.catalogPriceFromLabel,
    };

    final isPicked = pickedLabel != null;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPicked ? const BorderSide(color: AppColors.sea600, width: 2) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _photoHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CatalogPhoto(place: place, iconSize: 32),
                    if (isPicked)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                          decoration: BoxDecoration(
                            color: AppColors.sun400,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 14, color: AppColors.navy900),
                              const SizedBox(width: 3),
                              Text(pickedLabel!, style: appText(11, FontWeight.w800, AppColors.navy900, height: 16)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      right: 48,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.navy900.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            placeCategoryLabel(place, l10n, languageCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(11, FontWeight.w600, Colors.white, height: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(15, FontWeight.w700, AppColors.ink, height: 20),
                      ),
                      const SizedBox(height: 4),
                      PlaceRating(place: place),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  priceLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(11, FontWeight.w500, AppColors.inkMuted, height: 16),
                                ),
                                Text(
                                  placePrice(place, l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(
                                    13,
                                    FontWeight.w700,
                                    knownPrice ? AppColors.sea600 : AppColors.inkMuted,
                                    height: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(color: AppColors.field, shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.sea600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Below the heart, so the heart keeps its own tap.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: CatalogHeartButton(isSaved: isSaved, onPressed: onToggleSaved, onPhoto: true),
          ),
        ],
      ),
    );
  }
}
