import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live_trip/data/polyline_codec.dart';
import '../data/trip_models.dart';
import '../data/trip_repository.dart';
import 'trip_detail_controller.dart';
import 'widgets/place_photo.dart';

/// Halaman Ganti Tempat Wisata (Figma Node: Ganti Tempat)
/// Memungkinkan wisatawan mengganti destinasi rekomendasi sistem
/// dengan alternatif rekomendasi pintar (TOPSIS) atau pencarian manual dari backend.
class ReplacePlaceScreen extends ConsumerStatefulWidget {
  const ReplacePlaceScreen({
    super.key,
    required this.currentItem,
    this.dayNumber = 1,
    this.tripsId,
    this.itineraryDaysId,
    this.tripTitle = 'Eksplorasi Bahari (3H)',
  });

  final ItineraryItem currentItem;
  final int dayNumber;
  final int? tripsId;
  final int? itineraryDaysId;
  final String tripTitle;

  @override
  ConsumerState<ReplacePlaceScreen> createState() => _ReplacePlaceScreenState();
}

class _ReplacePlaceScreenState extends ConsumerState<ReplacePlaceScreen> {
  // Tab index: 0 = Rekomendasi Pintar, 1 = Cari Manual
  int _selectedTabIndex = 0;

  // Indeks alternatif yang dipilih dari daftar aktif
  int _selectedAltIndex = 0;

  // Filter chip aktif (null jika tidak ada filter)
  int? _selectedFilterChip;

  // Controller pencarian
  final _searchController = TextEditingController();
  String _manualCategory = 'Semua';

  // State loading & error untuk data backend
  bool _isLoadingSmart = true;
  String? _smartErrorMessage;
  List<_AlternativePlace> _smartAlternatives = [];

  bool _isLoadingManual = false;
  String? _manualErrorMessage;
  List<_AlternativePlace> _manualPlaces = [];

  bool _isSubmitting = false;

  static const _navy900 = Color(0xFF0B1C30);
  static const _primaryBlue = Color(0xFF1D6FA5);
  static const _lightBlueBg = Color(0xFFF8FAFC);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadSmartCandidates();
    if (widget.itineraryDaysId != null) {
      _loadManualPlaces();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat rekomendasi pintar berbasis TOPSIS dari endpoint backend
  /// GET /api/itinerary-items/{itineraryItem}/swap-candidates
  Future<void> _loadSmartCandidates() async {
    setState(() {
      _isLoadingSmart = true;
      _smartErrorMessage = null;
    });

    try {
      final candidates = await ref
          .read(tripRepositoryProvider)
          .fetchSwapCandidates(widget.currentItem.itineraryItemsId, limit: 30);

      final currentPlace = widget.currentItem.place;
      final mapped = <_AlternativePlace>[];

      for (int i = 0; i < candidates.length; i++) {
        mapped.add(_fromSwapCandidate(candidates[i], i, currentPlace: currentPlace));
      }

      if (mounted) {
        setState(() {
          _smartAlternatives = mapped;
          _isLoadingSmart = false;
          _selectedAltIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _smartErrorMessage = e.toString();
          _isLoadingSmart = false;
        });
      }
    }
  }

  /// Memuat tempat untuk pencarian manual terdekat dari rute hari ini
  /// GET /api/places?near_itinerary_day={itineraryDaysId}
  Future<void> _loadManualPlaces({String? search, String? category}) async {
    if (widget.itineraryDaysId == null) return;

    setState(() {
      _isLoadingManual = true;
      _manualErrorMessage = null;
    });

    try {
      final currentPlace = widget.currentItem.place;
      final places = await ref.read(tripRepositoryProvider).fetchNearDayPlaces(
            itineraryDaysId: widget.itineraryDaysId!,
            search: search,
            category: category == 'Semua' ? null : category,
            type: currentPlace?.type.isNotEmpty == true ? currentPlace?.type : null,
            perPage: 25,
          );

      final mapped = places
          .where((p) => p.placesId != currentPlace?.placesId)
          .map((p) => _fromTripPlace(p, currentPlace: currentPlace))
          .toList();

      if (mounted) {
        setState(() {
          _manualPlaces = mapped;
          _isLoadingManual = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualErrorMessage = e.toString();
          _isLoadingManual = false;
        });
      }
    }
  }

  /// Mengonversi model backend SwapCandidate ke model UI kartu alternatif
  _AlternativePlace _fromSwapCandidate(
    SwapCandidate candidate,
    int rank, {
    TripPlace? currentPlace,
  }) {
    final distanceKm = currentPlace != null && currentPlace.lat != 0 && currentPlace.lng != 0
        ? haversineKm(currentPlace.lat, currentPlace.lng, candidate.lat, candidate.lng)
        : 2.5;

    final travelMins = (distanceKm * 2.8).round().clamp(3, 45);

    final String? primaryBadge;
    final bool isHighlight;
    final String routeBenefit;
    final String timeSavingsLabel;

    if (rank == 0) {
      primaryBadge = 'Rekomendasi Utama';
      isHighlight = true;
      routeBenefit =
          'Rute lebih optimal: alternatif terbaik berdasarkan kecocokan kategori dan jarak rute terdekat.';
      timeSavingsLabel = 'Hemat 15m';
    } else if (distanceKm <= 3.0) {
      primaryBadge = 'Dekat Lokasi';
      isHighlight = false;
      routeBenefit =
          'Hemat waktu perjalanan: berjarak hanya ${distanceKm.toStringAsFixed(1)} km dari lokasi tujuan saat ini.';
      timeSavingsLabel = 'Searah rute';
    } else if ((candidate.rating ?? 0) >= 4.7) {
      primaryBadge = 'Favorit Wisatawan';
      isHighlight = false;
      routeBenefit =
          'Rating sangat tinggi dengan ulasan memuaskan dari wisatawan di Batam.';
      timeSavingsLabel = 'Rating 4.7+';
    } else {
      primaryBadge = 'Alternatif Pilihan';
      isHighlight = false;
      routeBenefit =
          'Waktu tempuh sekitar $travelMins menit berkendara, jadwal kegiatan tetap aman dan teratur.';
      timeSavingsLabel = '+${(distanceKm * 1.5).round()}m';
    }

    final matchPercent = candidate.topsisScore != null
        ? 'Cocok ${(candidate.topsisScore! * 100).round().clamp(60, 99)}%'
        : 'Cocok 88%';

    final categoryLabel = candidate.type == 'attraction'
        ? 'Wisata & Rekreasi • Batam'
        : (candidate.type == 'culinary'
            ? 'Kuliner & Restoran • Batam'
            : 'Destinasi Wisata');

    return _AlternativePlace(
      id: candidate.placesId,
      name: candidate.name,
      category: categoryLabel,
      rating: candidate.rating != null
          ? double.parse(candidate.rating!.toStringAsFixed(1))
          : 4.5,
      distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
      travelTime: '$travelMins mnt berkendara',
      priceRange: 'Estimasi Biaya Terjangkau',
      photoUrl: candidate.photoUrl ??
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400&auto=format&fit=crop&q=80',
      matchScore: matchPercent,
      primaryBadge: primaryBadge,
      secondaryBadge: (candidate.rating ?? 0) >= 4.5
          ? '${candidate.rating?.toStringAsFixed(1)} Bintang'
          : null,
      routeBenefit: routeBenefit,
      timeSavingsLabel: timeSavingsLabel,
      isHighlight: isHighlight,
    );
  }

  /// Mengonversi model tempat manual TripPlace ke kartu UI
  _AlternativePlace _fromTripPlace(
    TripPlace place, {
    TripPlace? currentPlace,
  }) {
    final distanceKm = currentPlace != null && currentPlace.lat != 0 && currentPlace.lng != 0
        ? haversineKm(currentPlace.lat, currentPlace.lng, place.lat, place.lng)
        : 3.0;
    final travelMins = (distanceKm * 2.8).round().clamp(3, 45);

    final categoryLabel = place.type == 'attraction'
        ? 'Wisata & Rekreasi • ${place.kecamatan ?? 'Batam'}'
        : (place.type == 'culinary'
            ? 'Kuliner & Restoran • ${place.kecamatan ?? 'Batam'}'
            : 'Destinasi • ${place.kecamatan ?? 'Batam'}');

    return _AlternativePlace(
      id: place.placesId ?? 0,
      name: place.name,
      category: categoryLabel,
      rating: place.rating != null
          ? double.parse(place.rating!.toStringAsFixed(1))
          : 4.5,
      distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
      travelTime: '$travelMins mnt berkendara',
      priceRange: 'Estimasi Biaya Sesuai',
      photoUrl: place.photoUrl ??
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&auto=format&fit=crop&q=80',
      matchScore: 'Pilihan Manual',
      primaryBadge: place.kecamatan != null && place.kecamatan!.isNotEmpty
          ? place.kecamatan
          : 'Katalog Batam',
      secondaryBadge: null,
      routeBenefit:
          'Pilihan manual akan menghitung ulang jadwal dan urutan rute secara otomatis.',
      timeSavingsLabel: 'Manual',
      isHighlight: false,
    );
  }

  /// Filter kandidat rekomendasi pintar berdasarkan input search bar dan filter chips
  List<_AlternativePlace> get _filteredSmartCandidates {
    var list = _smartAlternatives;

    // 1. Filter input teks di search bar
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query))
          .toList();
    }

    // 2. Filter chip aktif sesuai kemampuan data backend
    if (_selectedFilterChip != null) {
      switch (_selectedFilterChip) {
        case 0: // Dekat Lokasi Ini (< 3 km)
          list = list.where((p) => p.distanceKm <= 3.0).toList();
          break;
        case 1: // Rating 4.5+
          list = list.where((p) => p.rating >= 4.5).toList();
          break;
        case 2: // Budget Sesuai
          // Tetap tampil karena rekomendasi TOPSIS telah menyeimbangkan bobot anggaran trip
          break;
        case 3: // Buka Sekarang
          // Tetap tampil karena backend sudah memfilter tempat tidak closed_permanently
          break;
      }
    }

    return list;
  }

  /// Eksekusi penggantian tempat via PATCH /api/itinerary-items/{id}
  Future<void> _applyReplacement(_AlternativePlace selectedPlace) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(tripRepositoryProvider).swapItineraryItem(
            widget.currentItem.itineraryItemsId,
            selectedPlace.id,
          );

      if (widget.tripsId != null) {
        await ref.read(tripDetailProvider(widget.tripsId!).notifier).refresh();
      }

      if (!mounted) return;

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
                  'Destinasi berhasil diganti menjadi "${selectedPlace.name}"',
                  style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Gagal mengganti destinasi: $e',
            style: const TextStyle(fontFamily: 'PlusJakartaSans'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlace = widget.currentItem.place;
    final currentPlaceName = currentPlace?.name ?? 'Destinasi Saat Ini';
    final currentPlaceCategory = currentPlace?.type.isNotEmpty == true
        ? '${currentPlace!.type} • ${currentPlace.kecamatan ?? 'Batam'}'
        : 'Wisata • Batam';

    final smartList = _filteredSmartCandidates;
    final activeList = _selectedTabIndex == 0 ? smartList : _manualPlaces;

    final selectedPlace = activeList.isNotEmpty
        ? activeList[_selectedAltIndex.clamp(0, activeList.length - 1)]
        : null;

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
                  _buildSegmentedTab(smartList.length, _manualPlaces.length),
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
                      actionLabel: _isLoadingSmart
                          ? 'Memuat...'
                          : '${smartList.length} Tempat Tersedia',
                    ),
                    const SizedBox(height: 12),

                    // Daftar Kartu Alternatif Rekomendasi Pintar
                    if (_isLoadingSmart)
                      _buildLoadingSkeletons()
                    else if (_smartErrorMessage != null)
                      _buildErrorCard(
                        message: _smartErrorMessage!,
                        onRetry: _loadSmartCandidates,
                      )
                    else if (smartList.isEmpty)
                      _buildEmptyState(
                        message: _searchController.text.isNotEmpty || _selectedFilterChip != null
                            ? 'Tidak ada alternatif yang sesuai dengan filter atau kata kunci Anda.'
                            : 'Belum ada alternatif dari sistem untuk tempat ini.',
                        onReset: () {
                          setState(() {
                            _selectedFilterChip = null;
                            _searchController.clear();
                          });
                        },
                      )
                    else
                      for (int i = 0; i < smartList.length; i++)
                        _buildAlternativeCard(
                          place: smartList[i],
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
      bottomNavigationBar: selectedPlace != null
          ? _buildBottomActionBar(currentPlaceName, selectedPlace)
          : null,
    );
  }

  // ── WIDGET: Loading Skeleton Sederhana ────────────────────────────────────
  Widget _buildLoadingSkeletons() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
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

  // ── WIDGET: Error State Card ─────────────────────────────────────────────
  Widget _buildErrorCard({required String message, required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFE11D48)),
          const SizedBox(height: 10),
          const Text(
            'Gagal Memuat Alternatif',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _navy900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlue,
              side: const BorderSide(color: Color(0xFFBAE6FD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Empty State ──────────────────────────────────────────────────
  Widget _buildEmptyState({required String message, VoidCallback? onReset}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: _primaryBlue),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak Ada Tempat yang Sesuai',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _navy900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: _textMuted,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
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
  Widget _buildSegmentedTab(int smartCount, int manualCount) {
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
                      child: Text(
                        '$smartCount',
                        style: const TextStyle(
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
              onTap: () {
                setState(() => _selectedTabIndex = 1);
                if (_manualPlaces.isEmpty && widget.itineraryDaysId != null) {
                  _loadManualPlaces(category: _manualCategory);
                }
              },
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
                    if (manualCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? _primaryBlue : const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$manualCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
              onChanged: (val) {
                setState(() {});
              },
              onSubmitted: (val) {
                if (_selectedTabIndex == 1) {
                  _loadManualPlaces(search: val.trim(), category: _manualCategory);
                }
              },
              decoration: InputDecoration(
                hintText: _selectedTabIndex == 0
                    ? 'Cari alternatif tempat wisata atau kuliner...'
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
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                  if (_selectedTabIndex == 1) {
                    _loadManualPlaces(category: _manualCategory);
                  }
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
              ),
            )
          else
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
              onTap: () => setState(() {
                _selectedFilterChip = _selectedFilterChip == index ? null : index;
              }),
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
    final categories = ['Semua', 'Seafood', 'Pusat Kuliner', 'Kafe & Kopi', 'Tempat Belanja', 'Pantai'];

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
                  onSelected: (_) {
                    setState(() => _manualCategory = cat);
                    _loadManualPlaces(
                      search: _searchController.text.trim(),
                      category: cat,
                    );
                  },
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
          actionLabel: _isLoadingManual
              ? 'Mencari...'
              : '${_manualPlaces.length} Tempat Ditemukan',
        ),
        const SizedBox(height: 10),

        if (_isLoadingManual)
          _buildLoadingSkeletons()
        else if (_manualErrorMessage != null)
          _buildErrorCard(
            message: _manualErrorMessage!,
            onRetry: () => _loadManualPlaces(
              search: _searchController.text.trim(),
              category: _manualCategory,
            ),
          )
        else if (_manualPlaces.isEmpty)
          _buildEmptyState(
            message: 'Tidak ada tempat ditemukan untuk pencarian atau kategori ini.',
            onReset: () {
              setState(() {
                _manualCategory = 'Semua';
                _searchController.clear();
              });
              _loadManualPlaces();
            },
          )
        else
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
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                    onPressed: _isSubmitting ? null : () => _applyReplacement(selectedPlace),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Menerapkan...' : 'Terapkan Penggantian',
                      style: const TextStyle(
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
