import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trip/presentation/widgets/place_photo.dart';
import '../../../trip/presentation/widgets/rupiah_input_formatter.dart';
import '../../data/catalog_models.dart';

/// Catalog card (Figma B1 "Background+Shadow", PRD PlaceCard): photo with a
/// category badge and a wishlist heart, then name, rating and price.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, required this.isSaved, required this.onToggleSaved});

  /// Photo height over card width in the design (125.25 / 178).
  static const photoAspectRatio = 178 / 125.25;

  /// Info block height at text scale 1: 24 padding + 66 of text + 8 gaps.
  static const infoHeight = 98.0;

  /// Height of the text inside the info block, the part that grows with the
  /// system font size.
  static const infoTextHeight = 66.0;

  static const _heartSaved = Color(0xFFFFB956);
  static const _star = Color(0xFFFFB956);

  final CatalogPlace place;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        boxShadow: const [BoxShadow(color: Color(0x0F0B2E4A), offset: Offset(0, 4), blurRadius: 16)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: photoAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlacePhoto(url: place.photoUrl, icon: _placeholderIcon(place.type)),
                  // Keeps the badge readable over a photo; the plain
                  // placeholder does not need it.
                  if (place.photoUrl != null)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x66000000), Color(0x00000000)],
                          stops: [0, 0.5],
                        ),
                      ),
                    ),
                  // The 32px heart sits 10px from the corner; its touch padding
                  // takes 6 of those.
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _HeartButton(
                      isSaved: isSaved,
                      tooltip: isSaved ? l10n.catalogRemoveFromWishlist : l10n.catalogSaveToWishlist,
                      onPressed: onToggleSaved,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 8,
                    right: 52,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Frosted(
                        borderRadius: BorderRadius.circular(9999),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          _badgeLabel(l10n, languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                      ),
                    ),
                    _RatingRow(place: place, star: _star, languageCode: languageCode),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _PriceLabel(place: place)),
                        const SizedBox(width: 4),
                        // Detail (B2) is not built yet, so this is a visual cue only.
                        ExcludeSemantics(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: tokens.accentSoft, shape: BoxShape.circle),
                            child: Icon(Icons.chevron_right, size: 18, color: tokens.accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _badgeLabel(AppLocalizations l10n, String languageCode) {
    if (place.categories.isNotEmpty) return place.categories.first.localizedName(languageCode);

    return switch (place.type) {
      'culinary' => l10n.catalogTypeCulinary,
      'lodging' => l10n.catalogTypeLodging,
      _ => l10n.catalogTypeAttraction,
    };
  }

  static IconData _placeholderIcon(String type) {
    return switch (type) {
      'culinary' => Icons.restaurant,
      'lodging' => Icons.hotel_outlined,
      _ => Icons.landscape_outlined,
    };
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isSaved, required this.tooltip, required this.onPressed});

  final bool isSaved;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
          // 32px circle in the design, padded to a 44px touch target.
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: _Frosted(
              borderRadius: BorderRadius.circular(9999),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  size: 17,
                  color: isSaved ? PlaceCard._heartSaved : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White 90% pill with a background blur, used for the badge and the heart.
class _Frosted extends StatelessWidget {
  const _Frosted({required this.borderRadius, required this.child, this.padding = EdgeInsets.zero});

  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(padding: padding, color: Colors.white.withValues(alpha: 0.9), child: child),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.place, required this.star, required this.languageCode});

  final CatalogPlace place;
  final Color star;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final rating = place.rating;

    if (rating == null) {
      return Text(
        AppLocalizations.of(context).catalogNoReviews,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 16 / 12, color: tokens.textHint),
      );
    }

    return Row(
      children: [
        Icon(Icons.star_rounded, size: 15, color: star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '(${NumberFormat.compact(locale: languageCode).format(place.reviewCount)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 16 / 12, color: tokens.textHint),
          ),
        ),
      ],
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.place});

  final CatalogPlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final cost = place.estimatedCostIdr;

    final (label, value) = switch (cost) {
      null => (l10n.catalogPriceUnknownLabel, l10n.catalogPriceUnknown),
      0 => (l10n.catalogPriceFreeLabel, l10n.catalogPriceFree),
      _ => (l10n.catalogPriceFromLabel, 'Rp ${RupiahInputFormatter.format(cost)}'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: tokens.textHint),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
            color: cost == null ? tokens.textHint : tokens.accent,
          ),
        ),
      ],
    );
  }
}
