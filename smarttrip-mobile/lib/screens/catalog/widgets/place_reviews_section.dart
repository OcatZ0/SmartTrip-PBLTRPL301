import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';

/// B2 "Ulasan": rating summary with a 5-1 star breakdown, then the reviews.
/// The breakdown counts in-app reviews only; the headline rating is the
/// blended one from the API.
class PlaceReviewsSection extends StatefulWidget {
  const PlaceReviewsSection({super.key, required this.detail});

  /// Reviews shown before "Lihat semua".
  static const previewCount = 3;

  final PlaceDetail detail;

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reviews = widget.detail.reviews;
    final visible = _showAll ? reviews : reviews.take(PlaceReviewsSection.previewCount).toList();
    final canExpand = reviews.length > PlaceReviewsSection.previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.detailReviews, style: appText(18, FontWeight.w700, Colors.white, height: 24)),
            ),
            if (canExpand)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                style: TextButton.styleFrom(foregroundColor: AppColors.sun400),
                child: Text(
                  _showAll ? l10n.detailShowFewerReviews : l10n.detailSeeAllReviews,
                  style: appText(13, FontWeight.w700, AppColors.sun400),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.detail.summary.rating == null && reviews.isEmpty)
          _GlassCard(
            child: Text(
              l10n.detailNoReviews,
              style: appText(14, FontWeight.w500, Colors.white.withValues(alpha: 0.85), height: 22),
            ),
          )
        else
          _Summary(detail: widget.detail),
        for (final review in visible) ...[const SizedBox(height: 12), _ReviewCard(review: review)],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.detail});

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final rating = detail.summary.rating;
    final reviews = detail.reviews;

    return _GlassCard(
      radius: 20,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Column(
              children: [
                Text(
                  rating?.toStringAsFixed(1) ?? '-',
                  style: appText(36, FontWeight.w800, Colors.white, height: 40),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.detailReviewCount(NumberFormat.compact(locale: languageCode).format(detail.summary.reviewCount)),
                  textAlign: TextAlign.center,
                  style: appText(12, FontWeight.w500, Colors.white.withValues(alpha: 0.7), height: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: EdgeInsets.only(bottom: star == 1 ? 0 : 5),
                    child: _StarBar(
                      star: star,
                      share: reviews.isEmpty
                          ? 0
                          : reviews.where((review) => review.rating == star).length / reviews.length,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  const _StarBar({required this.star, required this.share});

  final int star;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          child: Text('$star', style: appText(11, FontWeight.w600, Colors.white.withValues(alpha: 0.7))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.12))),
                  FractionallySizedBox(
                    widthFactor: share.clamp(0, 1),
                    heightFactor: 1,
                    child: const ColoredBox(color: AppColors.sun400),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  static const _tints = [Color(0xFF2B6FAB), Color(0xFFC9964A), Color(0xFF4B3B7A), Color(0xFF2F6B4F)];

  final PlaceReview review;

  @override
  Widget build(BuildContext context) {
    final name = review.userName.trim();
    final comment = review.comment?.trim() ?? '';

    return _GlassCard(
      radius: 16,
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tints[(review.usersId ?? review.placeReviewsId) % _tints.length],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: appText(13, FontWeight.w800, Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(14, FontWeight.w700, Colors.white, height: 20),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _relativeDate(context, review.createdAt!),
                        style: appText(11, FontWeight.w500, Colors.white.withValues(alpha: 0.7), height: 14),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sun400.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.sun400),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: appText(12, FontWeight.w700, AppColors.sun400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: appText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.85), height: 20)),
          ],
        ],
      ),
    );
  }

  static String _relativeDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;

    return switch (days) {
      <= 0 => l10n.detailToday,
      1 => l10n.detailYesterday,
      < 7 => l10n.detailDaysAgo(days),
      _ => DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(date),
    };
  }
}

/// Translucent card on the dark detail screen.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.radius = 20, this.padding = 16});

  final Widget child;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
