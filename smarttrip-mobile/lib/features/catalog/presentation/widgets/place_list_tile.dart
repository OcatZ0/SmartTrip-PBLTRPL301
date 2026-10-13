import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/catalog_models.dart';
import 'catalog_photo.dart';
import 'catalog_style.dart';
import 'place_bits.dart';

class PlaceListTile extends StatelessWidget {
  const PlaceListTile({super.key, required this.place, required this.isSaved, required this.onToggleSaved});

  final CatalogPlace place;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final knownPrice = place.estimatedCostIdr != null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CatalogColors.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 72, height: 72, child: CatalogPhoto(place: place, iconSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: catalogText(15, FontWeight.w700, CatalogColors.ink, height: 20),
                ),
                const SizedBox(height: 3),
                Text(
                  placeMeta(place, l10n, languageCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: catalogText(12, FontWeight.w500, CatalogColors.inkMuted, height: 16),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: PlaceRating(place: place))),
                    const SizedBox(width: 8),
                    Text(
                      placePrice(place, l10n),
                      style: catalogText(
                        12,
                        FontWeight.w700,
                        knownPrice ? CatalogColors.sea600 : CatalogColors.inkMuted,
                        height: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CatalogHeartButton(isSaved: isSaved, onPressed: onToggleSaved),
        ],
      ),
    );
  }
}
