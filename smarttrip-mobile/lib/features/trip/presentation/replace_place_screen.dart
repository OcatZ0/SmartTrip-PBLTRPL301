import 'package:flutter/material.dart';

import '../data/trip_models.dart';
import 'widgets/place_photo.dart';

/// Halaman Ganti Tempat Wisata (Figma Node: Ganti Tempat)
/// Memungkinkan wisatawan mengganti destinasi rekomendasi sistem
/// dengan alternatif rekomendasi pintar atau pencarian manual.
class ReplacePlaceScreen extends StatefulWidget {
  const ReplacePlaceScreen({
    super.key,
    required this.currentItem,
    this.dayNumber = 1,
    this.tripTitle = 'Eksplorasi Bahari (3H)',
  });

  final ItineraryItem currentItem;
  final int dayNumber;
  final String tripTitle;

  @override
  State<ReplacePlaceScreen> createState() => _ReplacePlaceScreenState();
}

class _ReplacePlaceScreenState extends State<ReplacePlaceScreen> {
  // Tab index: 0 = Rekomendasi Pintar, 1 = Cari Manual
  int _selectedTabIndex = 0;

  // Indeks alternatif yang dipilih dari daftar
  int _selectedAltIndex = 0;

  // Filter chip aktif
  int _selectedFilterChip = 0;

  // Controller pencarian manual
  final _searchController = TextEditingController();
  String _manualCategory = 'Semua';

  static const _navy900 = Color(0xFF0B1C30);
  static const _primaryBlue = Color(0xFF1D6FA5);
  static const _lightBlueBg = Color(0xFFF8FAFC);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _textMuted = Color(0xFF64748B);

  // Data alternatif Rekomendasi Pintar sesuai Screenshot Figma
  final List<_AlternativePlace> _smartAlternatives = [
    const _AlternativePlace(
      id: 101,
      name: 'Wey Wey Seafood Harbour Bay',
      category: 'Kuliner Seafood • Tepi Laut Waterfront',
      rating: 4.7,
      distanceKm: 2.8,
      travelTime: '8 mnt dari destinasi awal',
      priceRange: 'Rp 85.000 - 150.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400&auto=format&fit=crop&q=80',
      matchScore: 'Cocok 96%',
      primaryBadge: 'Rekomendasi Utama',
      routeBenefit:
          'Rute lebih optimal: Hemat 15 menit perjalanan ke destinasi berikutnya (Nagoya Hill Shopping Mall).',
      timeSavingsLabel: 'Hemat 15m',
      isHighlight: true,
    ),
    const _AlternativePlace(
      id: 102,
      name: 'Love Seafood Piayu Laut',
      category: 'Kuliner Khas Batam • Kelong Asli',
      rating: 4.6,
      distanceKm: 5.1,
      travelTime: '14 mnt berkendara',
      priceRange: 'Rp 70.000 - 130.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&auto=format&fit=crop&q=80',
      primaryBadge: 'Favorit Lokal',
      secondaryBadge: '850+ Ulasan',
      routeBenefit:
          'Rute bertambah ~7 menit perjalanan, jadwal sesi belanja tetap aman dan tidak terburu-buru.',
      timeSavingsLabel: '+7m perjalanan',
    ),
    const _AlternativePlace(
      id: 103,
      name: 'Anchor Cafe & Roastery',
      category: 'Kafe & Brunch • Western / Lokal',
      rating: 4.8,
      distanceKm: 3.2,
      travelTime: '10 mnt berkendara',
      priceRange: 'Rp 50.000 - 110.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&auto=format&fit=crop&q=80',
      primaryBadge: 'Kafe Estetik',
      secondaryBadge: 'Pilihan Santai',
      routeBenefit:
          'Searah persis menuju Nagoya Hill Mall, waktu santai siang bertambah fleksibel.',
      timeSavingsLabel: 'Searah rute',
    ),
  ];

  // Data mock tempat untuk tab "Cari Manual" (didesain khusus untuk melengkapi tab Cari Manual)
  final List<_AlternativePlace> _manualPlaces = [
    const _AlternativePlace(
      id: 201,
      name: 'Harbour Bay Seafood Restaurant',
      category: 'Kuliner Seafood',
      rating: 4.6,
      distanceKm: 3.0,
      travelTime: '9 mnt berkendara',
      priceRange: 'Rp 90.000 - 170.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=400&auto=format&fit=crop&q=80',
      primaryBadge: 'Waterfront Dining',
      routeBenefit: 'Pemandangan laut lepas dan dekat dengan terminal feri.',
      timeSavingsLabel: 'Hemat 10m',
    ),
    const _AlternativePlace(
      id: 202,
      name: 'Nagoya Food Court Central',
      category: 'Pusat Jajanan & Kuliner',
      rating: 4.5,
      distanceKm: 2.2,
      travelTime: '6 mnt berkendara',
      priceRange: 'Rp 35.000 - 75.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&auto=format&fit=crop&q=80',
      primaryBadge: 'Paling Terjangkau',
      secondaryBadge: 'Banyak Pilihan',
      routeBenefit: 'Lokasi strategis di pusat kota Nagoya, tepat sebelum sesi belanja.',
      timeSavingsLabel: 'Hemat 12m',
    ),
    const _AlternativePlace(
      id: 203,
      name: 'Morning Bakery Windsor',
      category: 'Kafe & Sarapan Santai',
      rating: 4.7,
      distanceKm: 2.5,
      travelTime: '7 mnt berkendara',
      priceRange: 'Rp 25.000 - 50.000 / org',
      photoUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
      primaryBadge: 'Legendaris Batam',
      routeBenefit: 'Pilihan tepat untuk makan santai dan kudapan khas Batam.',
      timeSavingsLabel: 'Searah rute',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyReplacement() {
    final selectedPlace = _selectedTabIndex == 0
        ? _smartAlternatives[_selectedAltIndex]
        : _manualPlaces[_selectedAltIndex.clamp(0, _manualPlaces.length - 1)];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _navy900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Destinasi diganti menjadi "${selectedPlace.name}"',
                style: const TextStyle(fontFamily: 'PlusJakartaSans'),
              ),
            ),
          ],
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlace = widget.currentItem.place;
    final currentPlaceName = currentPlace?.name ?? 'Golden Prawn 933 Seafood';
    final currentPlaceCategory = currentPlace?.type.isNotEmpty == true
        ? '${currentPlace!.type} • ${currentPlace.kecamatan ?? 'Batam'}'
        : 'Kuliner Seafood • Bengkong Laut';

    final selectedPlace = _selectedTabIndex == 0
        ? _smartAlternatives[_selectedAltIndex]
        : _manualPlaces[_selectedAltIndex.clamp(0, _manualPlaces.length - 1)];

    return Scaffold(
      backgroundColor: _lightBlueBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. HEADER HALAMAN (Back Button + Judul + Trip Badge) ──
            _buildPageHeader(),

            // ── 2. BODY KONTEN (SCROLLABLE) ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  // Kartu Tempat Saat Ini Ditukar
                  _buildCurrentPlaceCard(currentPlaceName, currentPlaceCategory),
                  const SizedBox(height: 16),

                  // Segmented Tab (Rekomendasi Pintar vs Cari Manual)
                  _buildSegmentedTab(),
                  const SizedBox(height: 14),

                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 12),

                  // Filter Chips
                  _buildFilterChips(),
                  const SizedBox(height: 14),

                  // Konten Berdasarkan Tab yang Dipilih
                  if (_selectedTabIndex == 0) ...[
                    // Banner Smart Alternative Engine
                    _buildAiEngineBanner(),
                    const SizedBox(height: 16),

                    // Section Title
                    _buildSectionTitle(
                      title: 'Pilihan Alternatif Terbaik',
                      actionLabel: 'Diurutkan: Paling Pas',
                    ),
                    const SizedBox(height: 12),

                    // Daftar Kartu Alternatif Rekomendasi Pintar
                    for (int i = 0; i < _smartAlternatives.length; i++)
                      _buildAlternativeCard(
                        place: _smartAlternatives[i],
                        isSelected: _selectedAltIndex == i,
                        onTap: () => setState(() => _selectedAltIndex = i),
                      ),
                  ] else ...[
                    // TAMPILAN KHUSUS TAB "CARI MANUAL"
                    _buildManualSearchContent(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // ── 3. BOTTOM ACTION BAR (STICKY DI BAWAH) ──
      bottomNavigationBar: _buildBottomActionBar(currentPlaceName, selectedPlace),
    );
  }

  // ── WIDGET: Header Halaman ───────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Tombol Kembali Bulat
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _navy900, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Judul & Jadwal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ganti Tempat',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Jadwal Hari ${widget.dayNumber} • 11:30 WIB',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // ── WIDGET: Kartu Tempat Saat Ini Ditukar ──────────────────────────────────
  Widget _buildCurrentPlaceCard(String name, String category) {
    final photoUrl = widget.currentItem.place?.photoUrl ??
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&auto=format&fit=crop&q=80';
    final slotNumber = widget.currentItem.visitOrder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: Badge Oranye & Durasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'TEMPAT SAAT INI DITUKAR',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: _textMuted),
                  SizedBox(width: 4),
                  Text(
                    '1j 30m',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Tempat Saat Ini
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      Positioned.fill(child: PlacePhoto(url: photoUrl)),
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 11, color: Color(0xFFFBBF24)),
                              SizedBox(width: 2),
                              Text(
                                '4.4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: _textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                '11:30 - 13:00',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alokasi Slot #$slotNumber',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11.5,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Segmented Tab (Rekomendasi Pintar vs Cari Manual) ─────────────
  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Tab 1: Rekomendasi Pintar
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 0
                      ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: _selectedTabIndex == 0 ? _primaryBlue : _textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Rekomendasi Pintar',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w600,
                          color: _selectedTabIndex == 0 ? _primaryBlue : _textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0 ? _primaryBlue : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 2: Cari Manual
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTabIndex == 1
                      ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.travel_explore_rounded,
                      size: 15,
                      color: _selectedTabIndex == 1 ? _primaryBlue : _textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cari Manual',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w600,
                        color: _selectedTabIndex == 1 ? _primaryBlue : _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Search Bar ────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: _navy900),
              decoration: InputDecoration(
                hintText: _selectedTabIndex == 0
                    ? 'Cari alternatif resto atau kuliner...'
                    : 'Cari destinasi wisata Batam secara manual...',
                hintStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Icon(Icons.mic_none_rounded, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }

  // ── WIDGET: Filter Chips Carousel ─────────────────────────────────────────
  Widget _buildFilterChips() {
    final chips = [
      (label: 'Dekat Lokasi Ini (< 3 km)', icon: Icons.near_me_outlined),
      (label: 'Rating 4.5+', icon: Icons.star_rounded),
      (label: 'Budget Sesuai', icon: Icons.payments_outlined),
      (label: 'Buka Sekarang', icon: Icons.schedule_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(chips.length, (index) {
          final isSelected = _selectedFilterChip == index;
          final chip = chips[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterChip = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryBlue : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── WIDGET: Banner Smart Alternative Engine ──────────────────────────────
  Widget _buildAiEngineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF1D6FA5), size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Alternative Engine',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Memilih tempat yang searah dengan Nagoya Hill Mall (Slot #4) agar waktu liburanmu tetap efisien.',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11.5,
                    color: Color(0xFF3B82F6),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Section Title ────────────────────────────────────────────────
  Widget _buildSectionTitle({required String title, required String actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _navy900,
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primaryBlue,
          ),
        ),
      ],
    );
  }

  // ── WIDGET: Kartu Alternatif Rekomendasi Pintar ───────────────────────────
  Widget _buildAlternativeCard({
    required _AlternativePlace place,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryBlue : _cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryBlue.withValues(alpha: 0.12)
                  : const Color(0x06000000),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Garis Aksen Biru di Sisi Kiri (Hanya Jika Terpilih)
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(color: _primaryBlue),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card: Badge-badge & Radio Button
                    Row(
                      children: [
                        if (place.matchScore != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  place.matchScore!,
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (place.primaryBadge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFED7AA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              place.primaryBadge!,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9A3412),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (place.secondaryBadge != null)
                          Text(
                            place.secondaryBadge!,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Spacer(),

                        // Radio Button Kanan Atas
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? _primaryBlue : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? _primaryBlue : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Baris Gambar & Detail Info Tempat
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: Stack(
                              children: [
                                Positioned.fill(child: PlacePhoto(url: place.photoUrl)),
                                Positioned(
                                  left: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFBBF24)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${place.rating}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: _navy900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.category,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11.5,
                                  color: _textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.navigation_outlined, size: 12, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${place.distanceKm} km',
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('•', style: TextStyle(color: _textMuted)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      place.travelTime,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 11.5,
                                        color: _textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                place.priceRange,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Kotak Sorotan Rute / Benefit Efisiensi (Light Blue Box)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.alt_route_rounded, size: 15, color: Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.routeBenefit,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                color: Color(0xFF166534),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET: Konten Tambahan Khusus Tab "Cari Manual" ──────────────────────
  Widget _buildManualSearchContent() {
    final categories = ['Semua', 'Seafood', 'Pusat Kuliner', 'Kafe & Kopi', 'Tempat Belanja'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Kategori Cepat
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isCatSelected = _manualCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isCatSelected,
                  labelStyle: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: isCatSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isCatSelected ? Colors.white : _navy900,
                  ),
                  selectedColor: _primaryBlue,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isCatSelected ? _primaryBlue : const Color(0xFFCBD5E1),
                  ),
                  onSelected: (_) => setState(() => _manualCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Banner Penjelasan Cari Manual
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _primaryBlue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilihan tempat manual akan secara otomatis menghitung ulang durasi rute ke destinasi jadwal berikutnya.',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildSectionTitle(
          title: 'Hasil Pencarian Manual',
          actionLabel: '${_manualPlaces.length} Tempat Ditemukan',
        ),
        const SizedBox(height: 10),

        // Daftar Tempat Manual
        for (int i = 0; i < _manualPlaces.length; i++)
          _buildAlternativeCard(
            place: _manualPlaces[i],
            isSelected: _selectedAltIndex == i,
            onTap: () => setState(() => _selectedAltIndex = i),
          ),
      ],
    );
  }

  // ── WIDGET: Sticky Bottom Action Bar ─────────────────────────────────────
  Widget _buildBottomActionBar(String currentPlaceName, _AlternativePlace selectedPlace) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), offset: Offset(0, -4), blurRadius: 16),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Baris Ringkasan Penggantian (Pill Light Blue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_alt_rounded, size: 15, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Ganti: ', style: TextStyle(color: _textMuted)),
                          TextSpan(
                            text: currentPlaceName.length > 15
                                ? '${currentPlaceName.substring(0, 14)}...'
                                : currentPlaceName,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: _navy900),
                          ),
                          const TextSpan(text: ' ➔ ', style: TextStyle(color: Color(0xFF0284C7))),
                          TextSpan(
                            text: selectedPlace.name.length > 15
                                ? '${selectedPlace.name.substring(0, 14)}...'
                                : selectedPlace.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: _primaryBlue),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedPlace.timeSavingsLabel,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Batal & Terapkan Penggantian
            Row(
              children: [
                // Tombol Batal
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tombol Terapkan Penggantian
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _applyReplacement,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Terapkan Penggantian',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

// ── DATA MODEL LOKAL ALTERNATIF ─────────────────────────────────────────────
class _AlternativePlace {
  const _AlternativePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.travelTime,
    required this.priceRange,
    required this.photoUrl,
    required this.routeBenefit,
    required this.timeSavingsLabel,
    this.matchScore,
    this.primaryBadge,
    this.secondaryBadge,
    this.isHighlight = false,
  });

  final int id;
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final String travelTime;
  final String priceRange;
  final String photoUrl;
  final String routeBenefit;
  final String timeSavingsLabel;
  final String? matchScore;
  final String? primaryBadge;
  final String? secondaryBadge;
  final bool isHighlight;
}
