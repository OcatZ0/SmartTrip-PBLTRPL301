import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../widgets/category_icons.dart';
import '../../catalog/widgets/catalog_photo.dart';
import '../../catalog/widgets/place_bits.dart';

/// A saved place: the photo with its category, area and heart (a check box
/// while picking several), then the name, rating and price.
class WishlistPlaceCard extends StatelessWidget {
  const WishlistPlaceCard({
    super.key,
    required this.place,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  final CatalogPlace place;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final kecamatan = place.kecamatan;
    final icon = place.categories.isEmpty ? null : categoryIcon(place.categories.first.iconSymbol);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected ? const BorderSide(color: AppColors.sea600, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CatalogPhoto(place: place, iconSize: 40),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 64,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon ?? Icons.place_rounded, size: 13, color: AppColors.navy900),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  placeCategoryLabel(place, l10n, languageCode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(11.5, FontWeight.w700, AppColors.navy900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: isSelecting
                          ? _SelectionMark(isSelected: isSelected, onTap: onTap)
                          : CatalogHeartButton(isSaved: true, onPressed: onRemove, onPhoto: true),
                    ),
                    if (kecamatan != null && kecamatan.isNotEmpty)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 15, color: AppColors.sun400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                kecamatan,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: appText(12, FontWeight.w700, Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: appText(17, FontWeight.w800, AppColors.ink, height: 22, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PlaceRating(place: place),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 15, color: AppColors.sea600),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            placePrice(place, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(12.5, FontWeight.w600, AppColors.inkSoft),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·', style: appText(12.5, FontWeight.w900, AppColors.inkMuted)),
                        ),
                        Flexible(
                          child: Text(
                            switch (place.type) {
                              'culinary' => l10n.catalogTypeCulinary,
                              'lodging' => l10n.catalogTypeLodging,
                              _ => l10n.catalogTypeAttraction,
                            },
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(12.5, FontWeight.w500, AppColors.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sea600 : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppColors.sea600 : AppColors.line, width: 2),
            ),
            child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        ),
      ),
    );
  }
}
