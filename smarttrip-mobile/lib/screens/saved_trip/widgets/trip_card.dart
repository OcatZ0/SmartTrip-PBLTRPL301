import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../models/saved_trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final TripModel trip;

  void _handleCardTap(BuildContext context) {
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleCardTap(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBanner(),
                _buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BANNER (area abu/hijau/biru atas kartu) ───────────────────────────────
  Widget _buildBanner() {
    final config = _bannerConfig();

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: config.bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          config.leftBadge,
          config.rightBadge,
        ],
      ),
    );
  }

  _BannerConfig _bannerConfig() {
    switch (trip.status) {
      // ── BERLANGSUNG ──────────────────────────────────────────────────────
      case TripStatus.berlangsung:
        return _BannerConfig(
          bgColor: const Color(0xFFD6E6F5),
          leftBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFFE53935)),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          rightBadge: _darkPill('Hari ${trip.currentDay}/${trip.numDays}'),
        );

      // ── AKAN DATANG ──────────────────────────────────────────────────────
      case TripStatus.akanDatang:
        return _BannerConfig(
          bgColor: const Color(0xFFD6E6F5),
          leftBadge: const Text(
            'AKAN DATANG',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D6FA5),
              letterSpacing: 0.6,
            ),
          ),
          rightBadge: _darkPill('${trip.numDays} Hari'),
        );

      // ── SELESAI ──────────────────────────────────────────────────────────
      case TripStatus.selesai:
        return _BannerConfig(
          bgColor: const Color(0xFFD7EED9),
          leftBadge: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 13, color: Color(0xFF16A34A)),
              SizedBox(width: 3),
              Text(
                'SELESAI',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          rightBadge: _darkPill('${trip.numDays} Hari'),
        );

      // ── DRAFT ─────────────────────────────────────────────────────────────
      case TripStatus.draft:
        return _BannerConfig(
          bgColor: const Color(0xFFE8ECF0),
          leftBadge: const Text(
            'DRAFT',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          rightBadge: _darkPill('Belum diatur'),
        );
    }
  }

  static Widget _darkPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF475569),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── BODY (konten bawah kartu) ─────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul trip
          Text(
            trip.title,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B1C30),
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle: tanggal • orang • destinasi
          Text(
            _subtitle(),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),

          // Progress bar (Berlangsung saja)
          if (trip.status == TripStatus.berlangsung) ...[
            const SizedBox(height: 10),
            _buildProgressRow(),
          ],

          const SizedBox(height: 10),

          // Divider tipis
          const Divider(color: Color(0xFFF0F4F8), height: 1),
          const SizedBox(height: 10),

          // Footer: budget + aksi
          _buildFooter(context),
        ],
      ),
    );
  }

  String _subtitle() {
    switch (trip.status) {
      case TripStatus.draft:
        return '${trip.dateRange} • ${trip.wishlistCount} tempat di wishlist';
      default:
        return '${trip.dateRange} • ${trip.numPersons} orang • ${trip.numDestinations} destinasi';
    }
  }

  Widget _buildProgressRow() {
    final fraction = trip.numDestinations > 0
        ? (trip.visitedCount / trip.numDestinations).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progres kunjungan',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
            Text(
              '${trip.visitedCount}/${trip.numDestinations} selesai',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE58A1F)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    switch (trip.status) {
      // ── BERLANGSUNG: budget terpakai / total + Lihat Live Map ─────────────
      case TripStatus.berlangsung:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                  children: [
                    TextSpan(
                      text: trip.budgetSpentLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    TextSpan(
                      text: ' / ${trip.budgetTotalLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _linkButton(
              'Lihat Live Map',
              onTap: () => context.push(
                AppRoutes.liveMap(trip.id, trip.currentDay),
              ),
            ),
          ],
        );

      // ── AKAN DATANG: anggaran + Lihat Detail ─────────────────────────────
      case TripStatus.akanDatang:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                  children: [
                    const TextSpan(
                      text: 'Anggaran ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    TextSpan(
                      text: trip.budgetTotalLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _linkButton(
              'Lihat Detail',
              onTap: () => context.push(AppRoutes.trip(trip.id)),
            ),
          ],
        );

      // ── SELESAI: biaya terpakai + Beri Ulasan ────────────────────────────
      case TripStatus.selesai:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                  children: [
                    const TextSpan(
                      text: 'Terpakai ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    TextSpan(
                      text: trip.budgetSpentLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _linkButton(
              'Beri Ulasan',
              onTap: () => context.push(AppRoutes.review),
            ),
          ],
        );

      // ── DRAFT: lanjutkan pengaturan + Lanjutkan ───────────────────────────
      case TripStatus.draft:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Lanjutkan pengaturan trip',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            _linkButton(
              'Lanjutkan',
              onTap: () => context.push(AppRoutes.tripPreferences(trip.id)),
            ),
          ],
        );
    }
  }

  static Widget _linkButton(String label, {VoidCallback? onTap}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D6FA5),
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 14,
          color: Color(0xFF1D6FA5),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: content,
      ),
    );
  }
}

class _BannerConfig {
  const _BannerConfig({
    required this.bgColor,
    required this.leftBadge,
    required this.rightBadge,
  });
  final Color bgColor;
  final Widget leftBadge;
  final Widget rightBadge;
}
