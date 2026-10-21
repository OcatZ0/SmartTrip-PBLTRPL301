import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip.dart';
import '../../../widgets/place_photo.dart';
import '../../catalog/place_detail_screen.dart' show placeDetailProvider, userPositionProvider;
import '../../catalog/widgets/place_bits.dart';
import 'source_badge.dart';

/// The menu of one itinerary stop, opened from the ⋮ on its card: the stop
/// (photo, badge, name, category, area and distance), then Detail Tempat
/// Wisata, Ganti Lokasi Wisata and Buka di Google Maps. Pops with true when
/// the user wants to swap the stop.
class StopDetailSheet extends ConsumerWidget {
  const StopDetailSheet({super.key, required this.item, this.previous});

  final ItineraryItem item;

  /// The stop before it, for the distance when the user's own position is
  /// unknown.
  final TripPlace? previous;

  static Future<bool?> show(BuildContext context, {required ItineraryItem item, TripPlace? previous}) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StopDetailSheet(item: item, previous: previous),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final place = item.place;
    final placesId = place?.placesId;
    final detail = placesId == null ? null : ref.watch(placeDetailProvider(placesId)).valueOrNull;
    final here = ref.watch(userPositionProvider).valueOrNull;

    final meta = detail != null
        ? placeMeta(detail.summary, l10n, languageCode)
        : placesId == null
        ? l10n.placeSheetCustomPin
        : [_typeLabel(place?.type, l10n), if (place?.kecamatan case final kecamatan?) kecamatan].join(' · ');

    String? distance;
    if (place != null) {
      final km = NumberFormat('0.0', languageCode);
      final previous = this.previous;
      if (here != null) {
        final meters = const Distance().as(LengthUnit.Meter, here, LatLng(place.lat, place.lng));
        distance = l10n.stopSheetFromYou(km.format(meters / 1000));
      } else if (previous != null) {
        final meters = const Distance().as(
          LengthUnit.Meter,
          LatLng(previous.lat, previous.lng),
          LatLng(place.lat, place.lng),
        );
        distance = l10n.itineraryDistance(km.format(meters / 1000));
      }
    }

    Future<void> openMaps() async {
      if (place == null) return;
      Navigator.of(context).pop();
      final destination = '${place.lat},${place.lng}';
      await launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination'),
        mode: LaunchMode.externalApplication,
      );
    }

    void openDetail() {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(AppRoutes.place(placesId!));
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: PlacePhoto(url: detail?.heroPhotoUrl ?? place?.photoUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SourceBadge(isFromWishlist: item.isFromWishlist),
                      const SizedBox(height: 5),
                      Text(
                        place?.name ?? l10n.itineraryUnknownPlace,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: appText(16, FontWeight.w800, AppColors.ink, height: 21),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 13, color: AppColors.inkMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                            ),
                          ),
                        ],
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.near_me_outlined, size: 13, color: AppColors.sea600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                distance,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: appText(12, FontWeight.w600, AppColors.sea600, height: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 6),
            if (placesId != null)
              _ActionRow(
                icon: Icons.info_outline_rounded,
                title: l10n.stopSheetDetail,
                subtitle: l10n.stopSheetDetailHint,
                tint: AppColors.field,
                iconColor: AppColors.sea600,
                onTap: openDetail,
              ),
            _ActionRow(
              icon: Icons.swap_horiz_rounded,
              title: l10n.stopSheetSwap,
              subtitle: l10n.stopSheetSwapHint,
              tint: AppColors.field,
              iconColor: AppColors.sea600,
              onTap: () => Navigator.of(context).pop(true),
            ),
            _ActionRow(
              icon: Icons.directions_outlined,
              title: l10n.stopSheetMaps,
              subtitle: l10n.stopSheetMapsHint,
              tint: const Color(0xFFD5F5EF),
              iconColor: const Color(0xFF0F766E),
              onTap: place == null ? null : openMaps,
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(String? type, AppLocalizations l10n) {
    return switch (type) {
      'culinary' => l10n.catalogTypeCulinary,
      'lodging' => l10n.catalogTypeLodging,
      _ => l10n.catalogTypeAttraction,
    };
  }
}

/// A menu row: round icon, title over a caption, chevron.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, size: 21, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: appText(14.5, FontWeight.w700, AppColors.ink, height: 20)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
