import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Judul Halaman ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'Trip Tersimpan',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1C30),
                  letterSpacing: -0.4,
                ),
              ),
            ),

            // ── Tab Bar Filter ────────────────────────────────────────────
            _buildTabBar(),
            const SizedBox(height: 6),

            // ── Daftar Kartu Trip ─────────────────────────────────────────
            Expanded(
              child: trips.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom:
                            AppBottomBar.barHeight +
                            AppBottomBar.fabRise +
                            16 +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: trips.length,
                      itemBuilder: (_, i) => TripCard(trip: trips[i]),
                    ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation Bar (shared AppBottomBar) ─────────────────────────
      bottomNavigationBar: AppBottomBar(
        current: AppTab.trips,
        onSelect: _selectTab,
        onCreateTrip: () => context.push(AppRoutes.newTrip),
      ),
    );
  }

  // ── Tab Pills (Berlangsung, Akan Datang, Selesai, Draft) ──────────────────
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _tabs.map((status) {
          final isActive = status == _activeTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1D6FA5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF1D6FA5)
                        : const Color(0xFFD0D7DE),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1D6FA5).withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 44,
                color: Color(0xFF1D6FA5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada trip ${_activeTab.label.toLowerCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trip pertamamu tinggal 1 tap lagi!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
