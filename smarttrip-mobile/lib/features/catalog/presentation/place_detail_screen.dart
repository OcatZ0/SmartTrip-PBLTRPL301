import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/glass_top_bar.dart';
import '../../../core/widgets/osm_tile_layers.dart' show osmTileLayer;
import '../../../l10n/app_localizations.dart';
import '../../trip/data/trip_models.dart';
import '../../trip/data/trip_repository.dart';
import '../../trip/presentation/trip_error_message.dart';
import '../../wishlist/presentation/user_wishlist_controller.dart';
import '../data/catalog_models.dart';
import 'place_detail_controller.dart';
import 'widgets/catalog_photo.dart';
import 'widgets/catalog_style.dart';
import 'widgets/place_bits.dart';
import 'widgets/place_reviews_section.dart';

/// B2. Detail Tempat (F006): dark "glass" layout over the place photo, with
/// facts, description, location, reviews and a fixed save / add-to-trip bar.
/// Public, like the catalog it opens from.
class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placesId});

  final int placesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(placeDetailProvider(placesId));
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: CatalogColors.navy900,
        body: Stack(
          children: [
            Positioned.fill(
              child: detail.when(
                data: (place) => _DetailBody(detail: place),
                loading: () => const Center(child: CircularProgressIndicator(color: CatalogColors.sun400)),
                error: (error, _) => _LoadError(
                  message: '${l10n.detailLoadFailed} ${tripErrorMessage(error, l10n)}',
                  topInset: topInset,
                  onRetry: () => ref.invalidate(placeDetailProvider(placesId)),
                ),
              ),
            ),
            Positioned(left: 0, right: 0, top: 0, child: GlassTopBar(title: l10n.detailTitle)),
            if (detail.valueOrNull case final place?)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
                child: _ActionBar(detail: place),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});

  // Content starts this far down the hero (252 of 440 in the reference).
  static const _contentStart = 252 / 440;

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = (width * 440 / 360).clamp(360.0, 520.0);
    final description = detail.description(languageCode);
    final position = ref.watch(userPositionProvider).valueOrNull;

    return SingleChildScrollView(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroHeight,
            child: _Hero(detail: detail),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              heroHeight * _contentStart,
              16,
              120 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TitleBlock(detail: detail),
                const SizedBox(height: 16),
                _Facts(detail: detail, position: position),
                if (description != null) ...[
                  const SizedBox(height: 16),
                  _GlassSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.detailAbout, style: catalogText(16, FontWeight.w700, Colors.white, height: 22)),
                        const SizedBox(height: 8),
                        _ExpandableText(text: description),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _LocationCard(detail: detail),
                const SizedBox(height: 16),
                PlaceReviewsSection(detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.detail});

  final PlaceDetail detail;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final photos = detail.photos;
    final placeholder = CatalogPhoto(place: detail.summary, iconSize: 96, iconAlignment: const Alignment(0, -0.35));
    final belowBar = MediaQuery.paddingOf(context).top + GlassTopBar.height + 8;

    Widget image(String url) => CatalogPhoto.network(url, placeholder: placeholder);

    final heroUrl = detail.heroPhotoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (photos.length > 1)
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (_, index) => image(photos[index].url),
          )
        else if (heroUrl == null)
          placeholder
        else
          image(heroUrl),
        // Darkens the top for the bar and fades into the page at the bottom.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x800A2440), Color(0x000A2440), Color(0x590A2440), CatalogColors.navy900],
                stops: [0, 0.25, 0.55, 1],
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            top: belowBar + 6,
            left: 16,
            child: Row(
              children: [
                for (var index = 0; index < photos.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 4),
                    width: index == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _page ? CatalogColors.sun400 : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.detail});

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final place = detail.summary;
    final muted = Colors.white.withValues(alpha: 0.85);
    final labels = place.categories.isEmpty
        ? [placeCategoryLabel(place, l10n, languageCode)]
        : place.categories.map((category) => category.localizedName(languageCode)).toList();
    final kecamatan = place.kecamatan;
    final rating = place.rating;

    final meta = <Widget>[
      if (rating == null)
        Text(l10n.catalogNoReviews, style: catalogText(13, FontWeight.w500, muted))
      else
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: CatalogColors.sun400),
            const SizedBox(width: 4),
            Text(rating.toStringAsFixed(1), style: catalogText(13, FontWeight.w700, Colors.white)),
            const SizedBox(width: 4),
            Text(
              '(${NumberFormat.compact(locale: languageCode).format(place.reviewCount)})',
              style: catalogText(13, FontWeight.w500, muted),
            ),
          ],
        ),
      if (kecamatan != null && kecamatan.isNotEmpty) Text(kecamatan, style: catalogText(13, FontWeight.w500, muted)),
      if (detail.businessStatus == 'closed_temporarily')
        Text(l10n.detailClosedTemporarily, style: catalogText(13, FontWeight.w700, CatalogColors.sun400)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (index, label) in labels.indexed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: index == 0 ? CatalogColors.sun400 : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: index == 0 ? null : Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Text(
                  label,
                  style: catalogText(
                    11,
                    index == 0 ? FontWeight.w800 : FontWeight.w600,
                    index == 0 ? CatalogColors.navy900 : Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(place.name, style: catalogText(30, FontWeight.w800, Colors.white, height: 34, letterSpacing: -0.6)),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (index, item) in meta.indexed) ...[
              if (index > 0) Text('·', style: catalogText(13, FontWeight.w700, muted)),
              item,
            ],
          ],
        ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.detail, required this.position});

  final PlaceDetail detail;
  final LatLng? position;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final minutes = detail.estimatedVisitMinutes;
    final here = position;

    final facts = <(String, String)>[
      (l10n.detailFactTicket, placePrice(detail.summary, l10n)),
      if (minutes != null) (l10n.detailFactVisit, _visitLength(l10n, languageCode, minutes)),
      (l10n.detailFactHours, detail.openingHours ?? l10n.catalogPriceUnknown),
      if (here != null)
        (
          l10n.detailFactDistance,
          '${NumberFormat('0.0', languageCode).format(const Distance().as(LengthUnit.Meter, here, LatLng(detail.lat, detail.lng)) / 1000)} km',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, value) in facts)
              Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: catalogText(11, FontWeight.w500, Colors.white.withValues(alpha: 0.7), height: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: catalogText(16, FontWeight.w700, Colors.white, height: 22),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _visitLength(AppLocalizations l10n, String languageCode, int minutes) {
    if (minutes < 60) return l10n.detailVisitMinutes(minutes);
    return l10n.detailVisitHours(NumberFormat('0.#', languageCode).format(minutes / 60));
  }
}

/// Description clamped to four lines with a "Baca selengkapnya" toggle that
/// only shows when the text is actually longer.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  static const collapsedLines = 4;

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = catalogText(14, FontWeight.w400, Colors.white.withValues(alpha: 0.85), height: 22);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _ExpandableText.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _ExpandableText.collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: style,
            ),
            if (overflows || _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _expanded ? l10n.detailReadLess : l10n.detailReadMore,
                    style: catalogText(13, FontWeight.w700, CatalogColors.sun400),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.detail});

  final PlaceDetail detail;

  Future<void> _openMaps() async {
    final url = detail.mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${detail.lat},${detail.lng}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final point = LatLng(detail.lat, detail.lng);
    final address = detail.address ?? detail.summary.kecamatan ?? detail.summary.name;
    final hours = detail.openingHours;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The map tiles repaint on their own layer, not with the page scroll.
            RepaintBoundary(
              child: SizedBox(
                height: 140,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    osmTileLayer(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on, size: 40, color: CatalogColors.sun400),
                        ),
                      ],
                    ),
                    // flutter_map's SimpleAttributionWidget overflows a card
                    // this narrow; OSM only asks that the credit stays visible.
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        color: Colors.white.withValues(alpha: 0.8),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: catalogText(9, FontWeight.w500, CatalogColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address, style: catalogText(13, FontWeight.w700, Colors.white, height: 18)),
                        if (hours != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            hours,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: catalogText(12, FontWeight.w500, Colors.white.withValues(alpha: 0.7), height: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _openMaps,
                      child: SizedBox(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Text(l10n.detailOpenMaps, style: catalogText(12, FontWeight.w700, Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed bottom bar: wishlist heart and "Tambah ke Trip". Hotels are picked
/// in step C4, so a lodging place only gets the heart.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.detail});

  final PlaceDetail detail;

  bool _requireLogin(BuildContext context, WidgetRef ref) {
    if (ref.read(sessionControllerProvider).valueOrNull != null) return false;
    // go, not push: see CatalogScreen._goToLogin.
    context.go(AppRoutes.login);
    return true;
  }

  Future<void> _toggleSaved(BuildContext context, WidgetRef ref) async {
    if (_requireLogin(context, ref)) return;

    try {
      await ref.read(userWishlistControllerProvider.notifier).toggle(detail.summary.placesId);
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, AppLocalizations.of(context).catalogWishlistFailed);
    }
  }

  Future<void> _addToTrip(BuildContext context, WidgetRef ref) async {
    if (_requireLogin(context, ref)) return;

    final trip = await showModalBottomSheet<TripSummary>(
      context: context,
      backgroundColor: CatalogColors.navy900,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _TripPickerSheet(),
    );
    if (trip == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    try {
      final added = await ref
          .read(tripRepositoryProvider)
          .addPlaceToTripWishlist(trip.tripsId, detail.summary.placesId);
      if (!context.mounted) return;
      _showSnackBar(
        context,
        !added
            ? l10n.detailAlreadyInTrip(trip.title)
            : trip.hasItinerary
            ? l10n.detailAddedNeedsRegenerate(trip.title)
            : l10n.detailAddedToTrip(trip.title),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showSnackBar(context, tripErrorMessage(error, l10n));
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      // Floats above the fixed action bar instead of covering it.
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isSaved = (ref.watch(userWishlistControllerProvider).valueOrNull ?? const <int>{}).contains(
      detail.summary.placesId,
    );
    final tooltip = isSaved ? l10n.catalogRemoveFromWishlist : l10n.catalogSaveToWishlist;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CatalogColors.navy900.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Tooltip(
                message: tooltip,
                child: Semantics(
                  button: true,
                  toggled: isSaved,
                  label: tooltip,
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _toggleSaved(context, ref),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: CatalogColors.sun400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!detail.summary.isLodging) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _addToTrip(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: CatalogColors.sun400,
                        foregroundColor: CatalogColors.navy900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l10n.detailAddToTrip, style: catalogText(15, FontWeight.w700, CatalogColors.navy900)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TripPickerSheet extends ConsumerWidget {
  const _TripPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final trips = ref.watch(myTripsProvider);
    final muted = Colors.white.withValues(alpha: 0.7);

    final newTripButton = OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.newTrip);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: CatalogColors.sun400,
        side: const BorderSide(color: CatalogColors.sun400),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.add),
      label: Text(l10n.detailNewTrip, style: catalogText(14, FontWeight.w700, CatalogColors.sun400)),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.detailChooseTrip, style: catalogText(18, FontWeight.w700, Colors.white, height: 24)),
              const SizedBox(height: 12),
              Flexible(
                child: trips.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: CatalogColors.sun400)),
                  ),
                  error: (error, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tripErrorMessage(error, l10n), style: catalogText(14, FontWeight.w500, muted)),
                      TextButton(
                        onPressed: () => ref.invalidate(myTripsProvider),
                        child: Text(l10n.actionRetry, style: catalogText(14, FontWeight.w700, CatalogColors.sun400)),
                      ),
                    ],
                  ),
                  data: (list) => list.isEmpty
                      ? Text(l10n.detailNoTrips, style: catalogText(14, FontWeight.w500, muted, height: 20))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                          itemBuilder: (context, index) {
                            final trip = list[index];
                            final date = trip.startDate;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.of(context).pop(trip),
                              leading: const Icon(Icons.luggage_outlined, color: CatalogColors.sun400),
                              title: Text(trip.title, style: catalogText(15, FontWeight.w700, Colors.white)),
                              subtitle: Text(
                                l10n.detailTripMeta(
                                  trip.numDays,
                                  date == null ? '-' : DateFormat.yMMMd(languageCode).format(date),
                                ),
                                style: catalogText(12, FontWeight.w500, muted),
                              ),
                              trailing: Icon(Icons.chevron_right, color: muted),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              newTripButton,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.topInset, required this.onRetry});

  final String message;
  final double topInset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, topInset + GlassTopBar.height, 32, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: catalogText(14, FontWeight.w500, Colors.white.withValues(alpha: 0.85), height: 20),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: CatalogColors.sun400,
              foregroundColor: CatalogColors.navy900,
            ),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).actionRetry),
          ),
        ],
      ),
    );
  }
}
