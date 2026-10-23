import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/router/app_routes.dart';
import '../../models/place.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/app_bottom_bar.dart';
import '../catalog/widgets/catalog_photo.dart';

enum WishlistSortOption {
  baruDisimpan('Baru Disimpan'),
  ratingTertinggi('Rating Tertinggi'),
  namaAZ('Nama (A-Z)'),
  biayaTerendah('Biaya Terendah');

  const WishlistSortOption(this.label);
  final String label;
}

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  // Filter & Search states
  String _selectedCategorySlug = '';
  WishlistSortOption _selectedSort = WishlistSortOption.baruDisimpan;

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mode Pilih Banyak (Bulk Selection)
  bool _isSelectionMode = false;
  final Set<int> _selectedPlaceIds = {};

  // Theme Colors
  static const _navy900 = Color(0xFF0B1C30);
  static const _primaryBlue = Color(0xFF0284C7);
  static const _slateText = Color(0xFF475569);
  static const _slateMuted = Color(0xFF64748B);
  static const _bgLight = Color(0xFFF8F9FD);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        context.go(AppRoutes.catalog);
      case AppTab.wishlist:
        break; // Current screen
      case AppTab.trips:
        context.go(AppRoutes.trips);
      case AppTab.profile:
        context.go(AppRoutes.profile);
    }
  }

  List<CatalogPlace> _filterAndSort(List<CatalogPlace> places) {
    var list = [...places];

    // Filter Kategori
    if (_selectedCategorySlug.isNotEmpty) {
      list = list.where((p) {
        return p.categories.any((c) => c.slug == _selectedCategorySlug || c.nameId == _selectedCategorySlug);
      }).toList();
    }

    // Filter Pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesKecamatan = (p.kecamatan ?? '').toLowerCase().contains(q);
        final matchesCat = p.categories.any((c) => c.nameId.toLowerCase().contains(q));
        return matchesName || matchesKecamatan || matchesCat;
      }).toList();
    }

    // Sorting
    switch (_selectedSort) {
      case WishlistSortOption.baruDisimpan:
        // Default dari API GET /wishlist sudah terurutkan orderByPivot('added_at', 'desc')
        break;
      case WishlistSortOption.ratingTertinggi:
        list.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      case WishlistSortOption.namaAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case WishlistSortOption.biayaTerendah:
        list.sort((a, b) => (a.estimatedCostIdr ?? 999999999).compareTo(b.estimatedCostIdr ?? 999999999));
    }

    return list;
  }

  Future<void> _removeItem(CatalogPlace place) async {
    // 1. Optimistic remove in places list controller
    ref.read(userWishlistPlacesControllerProvider.notifier).removeLocally(place.placesId);
    setState(() {
      _selectedPlaceIds.remove(place.placesId);
    });

    // 2. Call backend DELETE /wishlist/{placesId}
    try {
      await ref.read(userWishlistControllerProvider.notifier).toggle(place.placesId);
    } catch (_) {
      // Revert if error
      ref.invalidate(userWishlistPlacesControllerProvider);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _navy900,
          content: Text(
            '${place.name} dihapus dari Wishlist',
            style: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'BATAL',
            textColor: const Color(0xFFFBBF24),
            onPressed: () async {
              try {
                await ref.read(userWishlistControllerProvider.notifier).toggle(place.placesId);
                await ref.read(userWishlistPlacesControllerProvider.notifier).refresh();
              } catch (_) {}
            },
          ),
        ),
      );
  }

  void _toggleSelection(int placesId) {
    setState(() {
      if (_selectedPlaceIds.contains(placesId)) {
        _selectedPlaceIds.remove(placesId);
      } else {
        _selectedPlaceIds.add(placesId);
      }
    });
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Urutkan Wishlist',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _navy900,
                    ),
                  ),
                ),
                const Divider(),
                ...WishlistSortOption.values.map((sort) {
                  final isSelected = sort == _selectedSort;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? _primaryBlue : _slateMuted,
                    ),
                    title: Text(
                      sort.label,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _primaryBlue : _navy900,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSort = sort;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedItems() async {
    final count = _selectedPlaceIds.length;
    if (count == 0) return;

    final idsToDelete = [..._selectedPlaceIds];
    setState(() {
      _selectedPlaceIds.clear();
      _isSelectionMode = false;
    });

    final wishlistService = ref.read(wishlistServiceProvider);
    for (final id in idsToDelete) {
      ref.read(userWishlistPlacesControllerProvider.notifier).removeLocally(id);
    }

    try {
      for (final id in idsToDelete) {
        await wishlistService.remove(id);
      }
      ref.invalidate(userWishlistControllerProvider);
    } catch (_) {
      ref.invalidate(userWishlistPlacesControllerProvider);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _navy900,
          content: Text(
            '$count destinasi berhasil dihapus dari Wishlist',
            style: const TextStyle(fontFamily: 'PlusJakartaSans'),
          ),
        ),
      );
  }

  Future<void> _handleAddToTrip() async {
    if (_selectedPlaceIds.isEmpty) return;

    final tripService = ref.read(tripServiceProvider);

    // Fetch existing user trips
    List<TripSummary> myTrips = [];
    try {
      myTrips = await tripService.fetchMyTrips();
    } catch (_) {
      // If fails to fetch trips, fallback to new trip
    }

    if (!mounted) return;

    if (myTrips.isEmpty) {
      // Langsung buat trip baru
      context.push(AppRoutes.newTrip);
      return;
    }

    // Modal pilih trip untuk ditambahkan
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Pilih Trip Tujuan',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _navy900,
                    ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: myTrips.length,
                    itemBuilder: (_, index) {
                      final trip = myTrips[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.explore_rounded, color: _primaryBlue),
                        ),
                        title: Text(
                          trip.title,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w700,
                            color: _navy900,
                          ),
                        ),
                        subtitle: Text(
                          '${trip.numDays} Hari • ${_formatDate(trip.startDate)}',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            color: _slateMuted,
                          ),
                        ),
                        trailing: const Icon(Icons.add_circle_outline_rounded, color: _primaryBlue),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final placeIds = [..._selectedPlaceIds];
                          int addedCount = 0;

                          for (final pId in placeIds) {
                            try {
                              final added = await tripService.addPlaceToTripWishlist(trip.tripsId, pId);
                              if (added) addedCount++;
                            } catch (_) {}
                          }

                          if (!mounted) return;
                          setState(() {
                            _isSelectionMode = false;
                            _selectedPlaceIds.clear();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _navy900,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Text(
                                addedCount > 0
                                    ? '$addedCount tempat dimasukkan ke wishlist trip "${trip.title}"'
                                    : 'Tempat sudah ada di trip tersebut',
                                style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(AppRoutes.newTrip);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Buat Trip Baru'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: const BorderSide(color: _primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Tanggal belum ditentukan';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final isLoggedIn = session != null;

    final wishlistAsync = ref.watch(userWishlistPlacesControllerProvider);

    return Scaffold(
      backgroundColor: _bgLight,
      // ── TOP APP BAR ─────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _navy900),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.catalog);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 18,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Daftar Wishlist',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _navy900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with Red Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: _navy900, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada notifikasi baru'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              Positioned(
                top: 13,
                right: 13,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // User Avatar Profile
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 2),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: ClipOval(
                  child: isLoggedIn
                      ? Center(
                          child: Text(
                            session.name.isNotEmpty ? session.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontWeight: FontWeight.w800,
                              color: _navy900,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : const Icon(Icons.person_rounded, color: _slateMuted, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BODY ─────────────────────────────────────────────────────────────────
      body: SafeArea(
        bottom: false,
        child: !isLoggedIn
            ? _buildGuestPrompt()
            : wishlistAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryBlue),
                ),
                error: (error, _) => _buildErrorState(error),
                data: (places) {
                  final filteredPlaces = _filterAndSort(places);

                  // Extract dynamic categories from actual backend places
                  final categoryMap = <String, ({String name, int count})>{};
                  for (final p in places) {
                    for (final c in p.categories) {
                      final current = categoryMap[c.slug];
                      categoryMap[c.slug] = (
                        name: c.nameId,
                        count: (current?.count ?? 0) + 1,
                      );
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // 1. Title + Subtitle + Search Icon
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Wishlist Saya',
                                                style: TextStyle(
                                                  fontFamily: 'PlusJakartaSans',
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: _navy900,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.bookmark_rounded,
                                                    size: 16,
                                                    color: _primaryBlue,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    '${places.length} Tempat Tersimpan',
                                                    style: const TextStyle(
                                                      fontFamily: 'PlusJakartaSans',
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: _primaryBlue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Circular Search Button
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isSearchOpen = !_isSearchOpen;
                                              if (!_isSearchOpen) {
                                                _searchController.clear();
                                                _searchQuery = '';
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(22),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _isSearchOpen
                                                  ? const Color(0xFFE0F2FE)
                                                  : const Color(0xFFF1F5F9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                                              size: 22,
                                              color: _isSearchOpen ? _primaryBlue : _navy900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Expandable Search Bar
                                    if (_isSearchOpen) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: 'Cari tempat dalam wishlist...',
                                          hintStyle: const TextStyle(
                                            fontFamily: 'PlusJakartaSans',
                                            color: _slateMuted,
                                            fontSize: 14,
                                          ),
                                          prefixIcon: const Icon(Icons.search_rounded, color: _primaryBlue),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() => _searchQuery = '');
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() => _searchQuery = val);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // 2. Horizontal Category Filter Chips (Dynamic from backend data)
                            if (places.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        // "Semua" Chip
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: _buildCategoryChip(
                                            label: 'Semua',
                                            count: places.length,
                                            icon: Icons.explore_outlined,
                                            isSelected: _selectedCategorySlug.isEmpty,
                                            onTap: () {
                                              setState(() => _selectedCategorySlug = '');
                                            },
                                          ),
                                        ),
                                        // Dynamic Category Chips
                                        ...categoryMap.entries.map((entry) {
                                          final slug = entry.key;
                                          final info = entry.value;
                                          final isSelected = _selectedCategorySlug == slug;

                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: _buildCategoryChip(
                                              label: info.name,
                                              count: info.count,
                                              icon: _getCategoryIcon(slug),
                                              isSelected: isSelected,
                                              onTap: () {
                                                setState(() {
                                                  _selectedCategorySlug = isSelected ? '' : slug;
                                                });
                                              },
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // 3. Toolbar Row (Baru Disimpan Sort Dropdown + Pilih Banyak Action)
                            if (places.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Sort Pill Button
                                      GestureDetector(
                                        onTap: _showSortSheet,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.sort_rounded, size: 16, color: _slateMuted),
                                              const SizedBox(width: 6),
                                              Text(
                                                _selectedSort.label,
                                                style: const TextStyle(
                                                  fontFamily: 'PlusJakartaSans',
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.keyboard_arrow_down_rounded,
                                                  size: 18, color: _slateMuted),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Action "Pilih Banyak"
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isSelectionMode = !_isSelectionMode;
                                            if (!_isSelectionMode) {
                                              _selectedPlaceIds.clear();
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _isSelectionMode
                                                    ? Icons.close_rounded
                                                    : Icons.checklist_rtl_rounded,
                                                size: 18,
                                                color: _primaryBlue,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                _isSelectionMode ? 'Selesai' : 'Pilih Banyak',
                                                style: const TextStyle(
                                                  fontFamily: 'PlusJakartaSans',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: _primaryBlue,
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

                            // 4. List of Wishlist Cards
                            if (places.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(),
                              )
                            else if (filteredPlaces.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildNoMatchesState(),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  _isSelectionMode
                                      ? 110
                                      : (AppBottomBar.barHeight + AppBottomBar.fabRise + 20),
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final place = filteredPlaces[index];
                                      final isItemSelected = _selectedPlaceIds.contains(place.placesId);

                                      return _buildPlaceCard(place, isItemSelected);
                                    },
                                    childCount: filteredPlaces.length,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),

      // ── BOTTOM SHEET FOR SELECTION MODE OR SHARED BOTTOM BAR ───────────────
      bottomNavigationBar: _isSelectionMode
          ? _buildSelectionBottomBar()
          : AppBottomBar(
              current: AppTab.wishlist,
              onSelect: _selectTab,
              onCreateTrip: () => context.push(AppRoutes.newTrip),
              labels: const {
                AppTab.home: 'Home',
                AppTab.wishlist: 'Wishlist',
                AppTab.trips: 'Trip Saya',
                AppTab.profile: 'Profil',
              },
            ),
    );
  }

  // ── CATEGORY FILTER CHIP ────────────────────────────────────────────────────
  Widget _buildCategoryChip({
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color iconTextColor;

    if (isSelected) {
      bgColor = _navy900;
      iconTextColor = Colors.white;
    } else {
      bgColor = const Color(0xFFF1F5F9);
      iconTextColor = _navy900;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _navy900.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconTextColor),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: iconTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('pantai') || s.contains('bahari')) return Icons.waves_rounded;
    if (s.contains('kuliner') || s.contains('makan')) return Icons.restaurant_rounded;
    if (s.contains('belanja') || s.contains('mall')) return Icons.shopping_bag_outlined;
    if (s.contains('sejarah') || s.contains('budaya')) return Icons.account_balance_rounded;
    if (s.contains('alam') || s.contains('outdoor')) return Icons.forest_rounded;
    return Icons.place_rounded;
  }

  // ── PLACE CARD (MATCHING THE SCREENSHOT) ───────────────────────────────────
  Widget _buildPlaceCard(CatalogPlace place, bool isItemSelected) {
    final category1 = place.categories.isNotEmpty ? place.categories.first.nameId : (place.isLodging ? 'Penginapan' : 'Destinasi');
    final category2 = place.estimatedCostIdr == 0
        ? 'Akses Gratis'
        : (place.categories.length > 1 ? place.categories[1].nameId : (place.isLodging ? 'Akomodasi' : 'Wisata Batam'));

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0A2440),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(place.placesId);
            } else {
              context.push(AppRoutes.place(place.placesId));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGE SECTION WITH FLOATING BADGES ─────────────────────────
              Stack(
                children: [
                  // Photo with Gradient Overlay
                  AspectRatio(
                    aspectRatio: 16 / 9.5,
                    child: place.photoUrl != null
                        ? CatalogPhoto.network(
                            place.photoUrl!,
                            placeholder: Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.image_outlined, size: 40, color: _slateMuted),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.explore_rounded, size: 40, color: _slateMuted),
                          ),
                  ),

                  // Bottom Gradient for legible location and highlight text
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Left Badges (Row)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 64, // Space for heart button
                    child: Row(
                      children: [
                        // Badge 1 (Icon + Text)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category1),
                                size: 13,
                                color: _navy900,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  category1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _navy900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge 2 (Solid Tint Pill)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: place.estimatedCostIdr == 0
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x24000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              category2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top Right Action: Heart Button or Selection Checkbox
                  Positioned(
                    top: 10,
                    right: 12,
                    child: _isSelectionMode
                        ? GestureDetector(
                            onTap: () => _toggleSelection(place.placesId),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isItemSelected ? _primaryBlue : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isItemSelected ? _primaryBlue : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: isItemSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                  : null,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _removeItem(place),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x2E000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                            ),
                          ),
                  ),

                  // Bottom Left: Location text with yellow pin
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 130,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.kecamatan != null && place.kecamatan!.isNotEmpty
                                ? '${place.kecamatan}, Batam'
                                : 'Batam, Kepulauan Riau',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Right: Highlight Dark Pill
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.rating != null && place.rating! >= 4.5
                            ? 'Pilihan Favorit'
                            : (place.estimatedCostIdr == 0 ? 'Akses Gratis' : 'Destinasi Batam'),
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── CARD BODY SECTION ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Rating Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _navy900,
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Rating Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                place.rating?.toStringAsFixed(1) ?? 'Baru',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              if (place.reviewCount > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '(${place.reviewCount})',
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Information details row (price/type)
                    Row(
                      children: [
                        if (place.estimatedCostIdr != null) ...[
                          const Icon(Icons.payments_outlined, size: 15, color: _primaryBlue),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              place.estimatedCostIdr == 0
                                  ? 'Tiket Masuk Gratis'
                                  : 'Rp ${_formatCurrency(place.estimatedCostIdr!)} / orang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _slateText,
                              ),
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.info_outline_rounded, size: 15, color: _primaryBlue),
                          const SizedBox(width: 5),
                          const Text(
                            'Informasi tiket di lokasi',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12.5,
                              color: _slateText,
                            ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            place.isLodging ? 'Akomodasi & Hotel' : 'Tempat Wisata',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _slateText,
                            ),
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
      ),
    );
  }

  // ── GUEST PROMPT STATE (WHEN USER IS LOGGED OUT) ────────────────────────────
  Widget _buildGuestPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Masuk untuk Mengakses Wishlist',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _navy900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masuk ke akun SmartTrip Anda untuk melihat, menyimpan, dan mengelola daftar destinasi favorit Anda di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13.5,
                color: _slateMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.login),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'Masuk Sekarang',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _navy900,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Wishlist Masih Kosong',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _navy900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simpan destinasi favoritmu dengan menekan ikon hati di katalog untuk mengumpulkannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13.5,
                color: _slateMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.catalog),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Jelajahi Katalog',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _navy900,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NO MATCHES FOUND FILTER/SEARCH STATE ────────────────────────────────────
  Widget _buildNoMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 52, color: _slateMuted),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Hasil yang Cocok',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _navy900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata kunci pencarian atau ganti filter kategori.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: _slateMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCategorySlug = '';
                });
              },
              child: const Text('Reset Filter'),
            ),
          ],
        ),
      ),
    );
  }

  // ── ERROR STATE ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Wishlist',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _navy900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terjadi kendala saat menghubungkan ke server. Silakan coba kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: _slateMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ref.read(userWishlistPlacesControllerProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  // ── SELECTION MODE BOTTOM ACTION BAR ────────────────────────────────────────
  Widget _buildSelectionBottomBar() {
    final count = _selectedPlaceIds.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0A2440),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Terpilih',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _navy900,
                  ),
                ),
                Text(
                  count == 0 ? 'Pilih tempat untuk kelola' : 'Siap untuk dikelola',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: _slateMuted,
                  ),
                ),
              ],
            ),
          ),
          // Hapus Button
          OutlinedButton.icon(
            onPressed: count == 0 ? null : _deleteSelectedItems,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
            label: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          // Buat Trip / Tambah ke Trip Button
          FilledButton.icon(
            onPressed: count == 0 ? null : _handleAddToTrip,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Buat Trip',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
