import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/catalog_models.dart';
import 'catalog_photo.dart';
import 'catalog_style.dart';
import 'place_bits.dart';

class PlaceGridCard extends StatelessWidget {
  const PlaceGridCard({super.key, required this.place, required this.isSaved, required this.onToggleSaved, this.onTap});

  static const height = 232.0;
  static const _photoHeight = 118.0;

  final CatalogPlace place;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  /// Opens the place detail (B2).
  final VoidCallback? onTap;

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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
                    Positioned(
                      left: 8,
                      bottom: 8,
                      right: 48,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CatalogColors.navy900.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            placeCategoryLabel(place, l10n, languageCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: catalogText(11, FontWeight.w600, Colors.white, height: 16),
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
                        style: catalogText(15, FontWeight.w700, CatalogColors.ink, height: 20),
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
                                  style: catalogText(11, FontWeight.w500, CatalogColors.inkMuted, height: 16),
                                ),
                                Text(
                                  placePrice(place, l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: catalogText(
                                    13,
                                    FontWeight.w700,
                                    knownPrice ? CatalogColors.sea600 : CatalogColors.inkMuted,
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
                            decoration: const BoxDecoration(color: CatalogColors.field, shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right_rounded, size: 20, color: CatalogColors.sea600),
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
