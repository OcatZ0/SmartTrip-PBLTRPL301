import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import 'catalog_photo.dart';
import 'place_bits.dart';

class PlaceListTile extends StatelessWidget {
  const PlaceListTile({super.key, required this.place, required this.isSaved, required this.onToggleSaved, this.onTap});

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

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
                        style: appText(15, FontWeight.w700, AppColors.ink, height: 20),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        placeMeta(place, l10n, languageCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: PlaceRating(place: place),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            placePrice(place, l10n),
                            style: appText(
                              12,
                              FontWeight.w700,
                              knownPrice ? AppColors.sea600 : AppColors.inkMuted,
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
          ),
        ),
      ),
    );
  }
}
