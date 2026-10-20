import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_trip.dart';
import '../../widgets/app_bottom_bar.dart';
import 'widgets/trip_card.dart';

class TripTersimpanScreen extends StatefulWidget {
  const TripTersimpanScreen({super.key});

  @override
  State<TripTersimpanScreen> createState() => _TripTersimpanScreenState();
}

class _TripTersimpanScreenState extends State<TripTersimpanScreen> {
  TripStatus _activeTab = TripStatus.berlangsung;

  static const _tabIcons = {
    TripStatus.berlangsung: Icons.near_me_rounded,
    TripStatus.akanDatang: Icons.event_rounded,
    TripStatus.selesai: Icons.task_alt_rounded,
    TripStatus.draft: Icons.edit_note_rounded,
  };

  static const _tabs = [
    TripStatus.berlangsung,
    TripStatus.akanDatang,
    TripStatus.selesai,
    TripStatus.draft,
  ];

  // Peta tab -> halaman utama agar dapat dipanggil otomatis.
  void _selectTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go(AppRoutes.catalog);
      case AppTab.wishlist:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Wishlist — segera hadir!')),
          );
      case AppTab.trips:
        break; // Sudah berada di halaman Trip Saya.
      case AppTab.profile:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = TripData.byStatus(_activeTab);
    final bottomSpace = AppBottomBar.barHeight + AppBottomBar.fabRise + 16 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(tabs: _buildTabBar())),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          if (trips.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottomSpace),
              sliver: SliverList.builder(
                itemCount: trips.length,
                itemBuilder: (_, i) => TripCard(trip: trips[i]),
              ),
            ),
        ],
      ),

      // ── Bottom Navigation Bar (shared AppBottomBar) ─────────────────────────
      bottomNavigationBar: AppBottomBar(
        current: AppTab.trips,
        onSelect: _selectTab,
        onCreateTrip: () => context.push(AppRoutes.newTrip),
      ),
    );
  }

  // ── Status tabs: four equal segments on a white bar over the header ─────
  // An icon with the count as a small badge above a short label, so all
  // four fit on a phone without scrolling.
  Widget _buildTabBar() {
    return Container(
      height: 62,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.floatShadow,
      ),
      child: Row(
        children: [
          for (final status in _tabs)
            Expanded(
              child: _StatusTab(
                icon: _tabIcons[status]!,
                label: status.label,
                count: TripData.byStatus(status).length,
                isActive: status == _activeTab,
                onTap: () => setState(() => _activeTab = status),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.field, shape: BoxShape.circle),
            child: const Icon(Icons.luggage_outlined, size: 44, color: AppColors.sea600),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada trip ${_activeTab.label.toLowerCase()}',
            textAlign: TextAlign.center,
            style: appText(16, FontWeight.w800, AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Trip pertamamu tinggal 1 tap lagi!',
            textAlign: TextAlign.center,
            style: appText(13, FontWeight.w500, AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Barelang panorama with the page title, like the catalog, and the status
/// tabs floating over its bottom edge.
class _Header extends StatelessWidget {
  const _Header({required this.tabs});

  final Widget tabs;

  static const _panoramaHeight = 132.0;
  static const _tabOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topInset + _panoramaHeight + _tabOverlap,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + _panoramaHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset('assets/images/login_panorama.svg', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8C0A2440), Color(0x000A2440)],
                      stops: [0, 0.75],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 18,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERJALANANMU',
                  style: appText(11, FontWeight.w700, AppColors.sun400, height: 16, letterSpacing: 0.88),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trip Tersimpan',
                  style: appText(24, FontWeight.w800, Colors.white, height: 30, letterSpacing: -0.48),
                ),
              ],
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 0, child: tabs),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? Colors.white : AppColors.inkMuted;

    return Semantics(
      selected: isActive,
      button: true,
      label: '$label, $count trip',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isActive ? AppColors.navy900 : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 20, color: isActive ? AppColors.sun400 : AppColors.inkMuted),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -9,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 15),
                            height: 15,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.sun400 : AppColors.field,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: isActive ? AppColors.navy900 : Colors.white, width: 1.5),
                            ),
                            child: Text(
                              '$count',
                              style: appText(9, FontWeight.w800, isActive ? AppColors.navy900 : AppColors.inkMuted),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(11, FontWeight.w700, foreground, height: 14),
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
