import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Where an itinerary stop came from: "Dari Wishlist" in sun with a heart,
/// or "Rekomendasi" in sea blue. Used by the itinerary and its stop sheet.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.isFromWishlist});

  final bool isFromWishlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foreground = isFromWishlist ? AppColors.navy900 : AppColors.sea600;

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 2, 8, 2),
      decoration: BoxDecoration(
        color: isFromWishlist ? AppColors.sun400 : AppColors.field,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFromWishlist ? Icons.favorite_rounded : Icons.auto_awesome_rounded, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            isFromWishlist ? l10n.itineraryFromWishlist : l10n.itineraryRecommended,
            style: appText(10.5, FontWeight.w800, foreground, height: 15),
          ),
        ],
      ),
    );
  }
}
