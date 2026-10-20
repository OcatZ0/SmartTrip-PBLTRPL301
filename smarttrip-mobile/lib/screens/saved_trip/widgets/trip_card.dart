import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/saved_trip.dart';
import '../../../widgets/place_photo.dart';

/// One saved trip: a mosaic of up to four of its places' photos with the
/// status on top, then the title, the facts and the trip's next action.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final TripModel trip;

  static const _radius = 20.0;

  void _open(BuildContext context) {
    switch (trip.status) {
      case TripStatus.berlangsung:
        context.push(AppRoutes.liveMap(trip.id, trip.currentDay));
      case TripStatus.akanDatang:
      case TripStatus.selesai:
        context.push(AppRoutes.trip(trip.id));
      case TripStatus.draft:
        context.push(AppRoutes.tripPreferences(trip.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius),
            onTap: () => _open(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoHeader(trip: trip),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: _Body(trip: trip),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo mosaic with the status badge and the day pill on top.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.trip});

  final TripModel trip;

  static const _height = 148.0;

  @override
  Widget build(BuildContext context) {
    final photos = trip.photoUrls.take(4).toList();
    final hiddenPlaces = trip.numDestinations - photos.length;

    return SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photos.isEmpty ? const _NoPhoto() : _Mosaic(photos: photos, morePlaces: hiddenPlaces),
          // Darkens the top so the badges read on any photo.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x800A2440), Color(0x000A2440)],
                  stops: [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _StatusBadge(status: trip.status),
                const Spacer(),
                _GlassPill(text: _dayLabel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel() => switch (trip.status) {
        TripStatus.berlangsung => 'Hari ${trip.currentDay}/${trip.numDays}',
        TripStatus.draft => 'Belum dijadwalkan',
        _ => '${trip.numDays} hari',
      };
}

/// 1 photo: full width. 2: side by side. 3: one large, two stacked.
/// 4: a 2x2 grid. The last tile says how many places are not shown.
class _Mosaic extends StatelessWidget {
  const _Mosaic({required this.photos, required this.morePlaces});

  final List<String> photos;
  final int morePlaces;

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    Widget tile(int index) {
      final isLast = index == photos.length - 1;
      return Stack(
        fit: StackFit.expand,
        children: [
          PlacePhoto(url: photos[index]),
          if (isLast && morePlaces > 0)
            ColoredBox(
              color: const Color(0x8C0A2440),
              child: Center(
                child: Text('+$morePlaces', style: appText(18, FontWeight.w800, Colors.white)),
              ),
            ),
        ],
      );
    }

    Widget column(List<Widget> children) => Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              Expanded(child: children[i]),
            ],
          ],
        );

    Widget row(List<Widget> children, {List<int>? flex}) => Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ],
        );

    return switch (photos.length) {
      1 => tile(0),
      2 => row([tile(0), tile(1)]),
      3 => row([tile(0), column([tile(1), tile(2)])], flex: [3, 2]),
      _ => column([
          row([tile(0), tile(1)]),
          row([tile(2), tile(3)]),
        ]),
    };
  }
}

/// No place photo yet (a new draft): the brand navy with a suitcase.
class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy700, AppColors.navy900],
        ),
      ),
      child: Center(
        child: Icon(Icons.luggage_outlined, size: 40, color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (Widget icon, Color color) = switch (status) {
      TripStatus.berlangsung => (const _LiveDot(), const Color(0xFFD92D20)),
      TripStatus.akanDatang => (const Icon(Icons.event_rounded, size: 13, color: AppColors.sea600), AppColors.sea600),
      TripStatus.selesai => (const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF1D7A55)), const Color(0xFF1D7A55)),
      TripStatus.draft => (const Icon(Icons.edit_note_rounded, size: 15, color: AppColors.inkMuted), AppColors.inkMuted),
    };

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(
            status == TripStatus.berlangsung ? 'Sedang berjalan' : status.label,
            style: appText(11, FontWeight.w700, color),
          ),
        ],
      ),
    );
  }
}

/// A red dot that softly pulses: the trip is live.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFD92D20), shape: BoxShape.circle),
        child: SizedBox(width: 7, height: 7),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x8C0A2440),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: appText(11, FontWeight.w700, Colors.white)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trip.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: appText(16, FontWeight.w800, AppColors.ink, height: 22, letterSpacing: -0.2),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _Fact(icon: Icons.calendar_today_rounded, text: trip.dateRange),
            if (trip.status == TripStatus.draft)
              _Fact(icon: Icons.favorite_border_rounded, text: '${trip.wishlistCount} di wishlist')
            else ...[
              _Fact(icon: Icons.group_outlined, text: '${trip.numPersons} orang'),
              _Fact(icon: Icons.place_outlined, text: '${trip.numDestinations} tempat'),
            ],
          ],
        ),
        if (trip.status == TripStatus.berlangsung) ...[
          const SizedBox(height: 14),
          _Progress(trip: trip),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.field),
        const SizedBox(height: 12),
        _Footer(trip: trip),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(text, style: appText(12, FontWeight.w500, AppColors.inkMuted)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final fraction = trip.numDestinations > 0 ? (trip.visitedCount / trip.numDestinations).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Progres kunjungan', style: appText(12, FontWeight.w600, AppColors.inkMuted)),
            const Spacer(),
            Text(
              '${trip.visitedCount}/${trip.numDestinations} tempat',
              style: appText(12, FontWeight.w700, AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.field,
            valueColor: const AlwaysStoppedAnimation(AppColors.sun400),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final (String label, String value, String? total, String action, String route) = switch (trip.status) {
      TripStatus.berlangsung => (
          'Terpakai',
          trip.budgetSpentLabel,
          trip.budgetTotalLabel,
          'Lihat Live Map',
          AppRoutes.liveMap(trip.id, trip.currentDay),
        ),
      TripStatus.akanDatang => ('Anggaran', trip.budgetTotalLabel, null, 'Lihat detail', AppRoutes.trip(trip.id)),
      TripStatus.selesai => ('Terpakai', trip.budgetSpentLabel, null, 'Beri ulasan', AppRoutes.review),
      TripStatus.draft => ('Langkah berikutnya', 'Atur preferensi', null, 'Lanjutkan', AppRoutes.tripPreferences(trip.id)),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: appText(11, FontWeight.w600, AppColors.inkMuted)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: appText(14, FontWeight.w800, AppColors.ink)),
                    if (total != null) TextSpan(text: ' / $total', style: appText(12, FontWeight.w500, AppColors.inkMuted)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.field,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action, style: appText(12, FontWeight.w700, AppColors.link)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.link),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
