import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_bottom_bar.dart';
import 'shared_trip_model.dart';

class ShareTripReadonlyScreen extends StatefulWidget {
  const ShareTripReadonlyScreen({super.key});

  @override
  State<ShareTripReadonlyScreen> createState() =>
      _ShareTripReadonlyScreenState();
}

class _ShareTripReadonlyScreenState extends State<ShareTripReadonlyScreen> {
  int _selectedDayIndex = 0;

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
        context.go(AppRoutes.trips);
      case AppTab.profile:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColorPrimary = Color(0xFF0B1C30);
    const textColorSecondary = Color(0xFF64748B);

    final currentSchedule = SharedTripData.schedules[_selectedDayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // ── TOP APP BAR ────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 20,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SmartTrip',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textColorPrimary,
                  ),
                ),
                Text(
                  'Trip Saya',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColorSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF475569),
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFCBD5E1),
              child: ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER JUDUL ITINERARY & BADGE SHARE ────────────────────────
            const Text(
              SharedTripData.tripTitle,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColorPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: textColorSecondary,
                ),
                const SizedBox(width: 5),
                const Text(
                  SharedTripData.dateRange,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColorSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    SharedTripData.sharedBy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D6FA5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── PILIHAN HARI (PILLS) ────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  SharedTripData.schedules.length,
                  (index) {
                    final isSelected = index == _selectedDayIndex;
                    final schedule = SharedTripData.schedules[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1D6FA5)
                                : const Color(0xFFEBF1F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                schedule.dateLabel,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── KARTU CUACA & PREDIKSI HUJAN ─────────────────────────────────
            _buildWeatherCard(currentSchedule),
            const SizedBox(height: 24),

            // ── TIMELINE JADWAL DESTINASI PER HARI ───────────────────────────
            _buildTimelineSchedule(currentSchedule.destinations),
            const SizedBox(height: 24),

            // ── TOMBOL BUKA RUTE PETA LIVE ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF1D6FA5),
                      content: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mode Viewer: Membuka navigasi rute (Read-Only)',
                              style: TextStyle(fontFamily: 'PlusJakartaSans'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text(
                  'Buka Rute Peta Live',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D6FA5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── BOTTOM NAVIGATION BAR (shared AppBottomBar) ────────────────────────
      bottomNavigationBar: AppBottomBar(
        current: AppTab.trips,
        onSelect: _selectTab,
        onCreateTrip: () => context.push(AppRoutes.newTrip),
      ),
    );
  }

  // ── WIDGET KARTU CUACA ─────────────────────────────────────────────────────
  Widget _buildWeatherCard(DaySchedule schedule) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Cuaca
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  size: 24,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              // Suhu & Kondisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          schedule.weatherTemp,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            schedule.weatherLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.weatherCondition,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D6FA5),
                      ),
                    ),
                  ],
                ),
              ),
              // Kelembapan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Kelembapan',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    schedule.humidity,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Banner Prediksi Hujan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.beach_access_rounded,
                  size: 18,
                  color: Color(0xFF9A3412),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    schedule.rainPrediction,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C2D12),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET TIMELINE JADWAL DESTINASI ───────────────────────────────────────
  Widget _buildTimelineSchedule(List<SharedDestinationItem> destinations) {
    return Column(
      children: List.generate(destinations.length, (index) {
        final item = destinations[index];
        final isLast = index == destinations.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sisi Kiri: Angka Urutan + Jam + Garis Penghubung
            SizedBox(
              width: 46,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.orderNumber}',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D6FA5),
                    ),
                  ),
                  if (!isLast) ...[
                    Container(
                      width: 1.5,
                      height: item.transitInfo != null ? 120 : 60,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Sisi Kanan: Kartu Destinasi + Estimasi Transit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Destinasi
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.imageUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 58,
                              height: 58,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.image_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Konten Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: _buildCategoryBadge(item),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.more_horiz_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          duration: Duration(seconds: 1),
                                          content: Text(
                                            'Mode Viewer: Itinerary hanya dapat dilihat',
                                            style: TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B1C30),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.duration,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.highlightText,
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: item.badgeCategory ==
                                                BadgeCategory.goldenHour
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF1D6FA5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

                  // Estimasi Waktu Tempuh Antar Destinasi
                  if (item.transitInfo != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.transitInfo!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── BADGE KATEGORI DESTINASI ───────────────────────────────────────────────
  Widget _buildCategoryBadge(SharedDestinationItem item) {
    Color bg;
    Color fg;

    switch (item.badgeCategory) {
      case BadgeCategory.rekomendasi:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case BadgeCategory.wishlist:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      case BadgeCategory.indoorRain:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case BadgeCategory.goldenHour:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.badgeText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
