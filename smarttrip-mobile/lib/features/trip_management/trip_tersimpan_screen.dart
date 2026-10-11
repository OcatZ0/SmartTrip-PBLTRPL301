import 'package:flutter/material.dart';

import 'trip_model.dart';
import 'trip_card.dart';

/// D3. Halaman "Trip Tersimpan" — 4 tab: Berlangsung / Akan Datang / Selesai / Draft
/// Sesuai screenshot Figma dari anggota tim. Murni frontend, data statis.
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
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: trips.length,
                      itemBuilder: (_, i) => TripCard(trip: trips[i]),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB (+) ──────────────────────────────────────────────────────────
      floatingActionButton: SizedBox(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          heroTag: 'tripFab',
          backgroundColor: const Color(0xFF1D6FA5),
          shape: const CircleBorder(),
          elevation: 3,
          onPressed: () {
            // Placeholder: navigasi ke halaman buat trip
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Buat Trip — segera hadir!')),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNavBar(),
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

  // ── Bottom Navigation Bar (Home / Wishlist / Trip Saya / Profil) ──────────
  Widget _buildBottomNavBar() {
    const activeColor = Color(0xFF1D6FA5);
    const inactiveColor = Color(0xFF8A94A6);

    final items = [
      (icon: Icons.home_outlined, filled: Icons.home_rounded, label: 'Home'),
      (icon: Icons.favorite_border_rounded, filled: Icons.favorite_rounded, label: 'Wishlist'),
      (icon: Icons.explore_outlined, filled: Icons.explore_rounded, label: 'Trip Saya'),
      (icon: Icons.person_outline_rounded, filled: Icons.person_rounded, label: 'Profil'),
    ];
    // index 2 = Trip Saya (halaman ini aktif)
    const int currentIndex = 2;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Navigasi tab lain ditambahkan jika sudah ada route-nya
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // garis atas indikator aktif
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isSelected ? 22 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isSelected ? item.filled : item.icon,
                        size: 22,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
