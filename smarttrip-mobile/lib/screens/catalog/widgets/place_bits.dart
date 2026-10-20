import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../widgets/rupiah_input_formatter.dart';

String placeCategoryLabel(CatalogPlace place, AppLocalizations l10n, String languageCode) {
  if (place.categories.isNotEmpty) return place.categories.first.localizedName(languageCode);

  return switch (place.type) {
    'culinary' => l10n.catalogTypeCulinary,
    'lodging' => l10n.catalogTypeLodging,
    _ => l10n.catalogTypeAttraction,
  };
}

String placeMeta(CatalogPlace place, AppLocalizations l10n, String languageCode) {
  final category = placeCategoryLabel(place, l10n, languageCode);
  final kecamatan = place.kecamatan;
  return kecamatan == null || kecamatan.isEmpty ? category : '$category · $kecamatan';
}

String placePrice(CatalogPlace place, AppLocalizations l10n) {
  return switch (place.estimatedCostIdr) {
    null => l10n.catalogPriceUnknown,
    0 => l10n.catalogPriceFree,
    final int cost => 'Rp ${RupiahInputFormatter.format(cost)}',
  };
}

class PlaceRating extends StatelessWidget {
  const PlaceRating({super.key, required this.place, this.onPhoto = false});

  final CatalogPlace place;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final strong = onPhoto ? Colors.white : AppColors.ink;
    final muted = onPhoto ? Colors.white.withValues(alpha: 0.85) : AppColors.inkMuted;
    final rating = place.rating;

    if (rating == null) {
      return Text(
        AppLocalizations.of(context).catalogNoReviews,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: appText(12, FontWeight.w500, muted, height: 16),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: AppColors.sun400),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: appText(12, FontWeight.w700, strong, height: 16)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '(${NumberFormat.compact(locale: languageCode).format(place.reviewCount)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appText(12, FontWeight.w500, muted, height: 16),
          ),
        ),
      ],
    );
  }
}

class CatalogHeartButton extends StatelessWidget {
  const CatalogHeartButton({super.key, required this.isSaved, required this.onPressed, this.onPhoto = false});

  final bool isSaved;
  final VoidCallback onPressed;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tooltip = isSaved ? l10n.catalogRemoveFromWishlist : l10n.catalogSaveToWishlist;
    final icon = Icon(
      isSaved ? Icons.favorite : Icons.favorite_border,
      size: onPhoto ? 18 : 22,
      color: isSaved ? AppColors.sun400 : AppColors.ink,
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: isSaved,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: onPhoto
                  ? Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                      child: icon,
                    )
                  : icon,
            ),
          ),
        ),
      ),
    );
  }
}
