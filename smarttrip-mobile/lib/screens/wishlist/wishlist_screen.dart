import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/app_bottom_bar.dart';
import 'wishlist_model.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late List<WishlistPlaceItem> _allItems;
  WishlistCategory _selectedCategory = WishlistCategory.semua;
  WishlistSort _selectedSort = WishlistSort.baruDisimpan;

  // Search state
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mode Pilih Banyak (Bulk Selection)
  bool _isSelectionMode = false;
  final Set<int> _selectedItemIds = {};

  // Theme Colors
  static const _navy900 = Color(0xFF0B1C30);
  static const _primaryBlue = Color(0xFF0284C7);
  static const _slateText = Color(0xFF475569);
  static const _slateMuted = Color(0xFF64748B);
  static const _bgLight = Color(0xFFF8F9FD);

  @override
  void initState() {
    super.initState();
    _allItems = WishlistPlaceItem.initialItems();
  }

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

  List<WishlistPlaceItem> get _filteredAndSortedItems {
    var list = _allItems.where((item) => item.isSaved).toList();

    // Filter Category
    if (_selectedCategory != WishlistCategory.semua) {
      list = list.where((item) => item.categoryGroup == _selectedCategory).toList();
    }

    // Filter Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.badge1Text.toLowerCase().contains(q) ||
            item.badge2Text.toLowerCase().contains(q);
      }).toList();
    }

    // Sorting
    switch (_selectedSort) {
      case WishlistSort.baruDisimpan:
        list.sort((a, b) => b.savedDate.compareTo(a.savedDate));
      case WishlistSort.ratingTertinggi:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case WishlistSort.namaAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
      case WishlistSort.terdekat:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return list;
  }

  int _categoryCount(WishlistCategory cat) {
    if (cat == WishlistCategory.semua) {
      return _allItems.where((e) => e.isSaved).length;
    }
    return _allItems.where((e) => e.isSaved && e.categoryGroup == cat).length;
  }

  void _toggleSaveItem(WishlistPlaceItem item) {
    final index = _allItems.indexWhere((element) => element.id == item.id);
    if (index == -1) return;

    setState(() {
      _allItems[index].isSaved = false;
      _selectedItemIds.remove(item.id);
    });

    // Also trigger Riverpod UserWishlistController if place id exists
    try {
      ref.read(userWishlistControllerProvider.notifier).toggle(item.id);
    } catch (_) {
      // Graceful fallback for mock items
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _navy900,
          content: Text(
            '${item.name} dihapus dari Wishlist',
            style: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'BATAL',
            textColor: const Color(0xFFFBBF24),
            onPressed: () {
              setState(() {
                _allItems[index].isSaved = true;
              });
              try {
                ref.read(userWishlistControllerProvider.notifier).toggle(item.id);
              } catch (_) {}
            },
          ),
        ),
      );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
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
                ...WishlistSort.values.map((sort) {
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

  void _deleteSelectedItems() {
    final count = _selectedItemIds.length;
    if (count == 0) return;

    final removedItems = <WishlistPlaceItem>[];
    setState(() {
      for (final id in _selectedItemIds) {
        final idx = _allItems.indexWhere((e) => e.id == id);
        if (idx != -1) {
          removedItems.add(_allItems[idx]);
          _allItems[idx].isSaved = false;
        }
      }
      _selectedItemIds.clear();
      _isSelectionMode = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: _navy900,
          content: Text(
            '$count destinasi dihapus dari Wishlist',
            style: const TextStyle(fontFamily: 'PlusJakartaSans'),
          ),
          action: SnackBarAction(
            label: 'BATAL',
            textColor: const Color(0xFFFBBF24),
            onPressed: () {
              setState(() {
                for (final item in removedItems) {
                  final idx = _allItems.indexWhere((e) => e.id == item.id);
                  if (idx != -1) {
                    _allItems[idx].isSaved = true;
                  }
                }
              });
            },
          ),
        ),
      );
  }

  void _createTripFromSelected() {
    if (_selectedItemIds.isEmpty) return;
    context.push(AppRoutes.newTrip);
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _filteredAndSortedItems;
    final totalSaved = _allItems.where((e) => e.isSaved).length;

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
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  image: const DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BODY ─────────────────────────────────────────────────────────────────
      body: SafeArea(
        bottom: false,
        child: Column(
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
                                          '$totalSaved Tempat Tersimpan',
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  // 2. Horizontal Category Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: WishlistCategory.values.map((cat) {
                            final isSelected = cat == _selectedCategory;
                            final count = _categoryCount(cat);

                            Color bgColor;
                            Color iconTextColor;

                            if (isSelected) {
                              bgColor = _navy900;
                              iconTextColor = Colors.white;
                            } else {
                              switch (cat) {
                                case WishlistCategory.pantai:
                                  bgColor = const Color(0xFFE0F2FE);
                                  iconTextColor = const Color(0xFF0284C7);
                                case WishlistCategory.kuliner:
                                  bgColor = const Color(0xFFFEF3C7);
                                  iconTextColor = const Color(0xFFB45309);
                                case WishlistCategory.sejarah:
                                  bgColor = const Color(0xFFF1F5F9);
                                  iconTextColor = const Color(0xFF475569);
                                case WishlistCategory.belanja:
                                  bgColor = const Color(0xFFF3E8FF);
                                  iconTextColor = const Color(0xFF7E22CE);
                                case WishlistCategory.semua:
                                  bgColor = const Color(0xFFF1F5F9);
                                  iconTextColor = _navy900;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
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
                                      Icon(cat.icon, size: 16, color: iconTextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${cat.label} ($count)',
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 3. Toolbar Row (Baru Disimpan Sort Dropdown + Pilih Banyak Action)
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
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _slateMuted),
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
                                  _selectedItemIds.clear();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSelectionMode ? Icons.close_rounded : Icons.checklist_rtl_rounded,
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
                  if (displayedItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        _isSelectionMode ? 100 : (AppBottomBar.barHeight + AppBottomBar.fabRise + 20),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = displayedItems[index];
                            final isItemSelected = _selectedItemIds.contains(item.id);

                            return _buildWishlistCard(item, isItemSelected);
                          },
                          childCount: displayedItems.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
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

  // ── WISHLIST CARD ───────────────────────────────────────────────────────────
  Widget _buildWishlistCard(WishlistPlaceItem item, bool isItemSelected) {
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
              _toggleSelection(item.id);
            } else {
              context.push(AppRoutes.place(item.id));
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
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.image_not_supported_rounded, size: 40, color: _slateMuted),
                        );
                      },
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
                    right: 64, // Leave space for heart button
                    child: Row(
                      children: [
                        // Badge 1 (Icon + Text, e.g. Kuliner Seafood / Ikon Batam)
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
                                item.badge1Icon,
                                size: 13,
                                color: item.categoryGroup == WishlistCategory.kuliner
                                    ? const Color(0xFFB45309)
                                    : _navy900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.badge1Text,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.categoryGroup == WishlistCategory.kuliner
                                      ? const Color(0xFF92400E)
                                      : _navy900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge 2 (Solid Tint Pill, e.g. Tepi Laut / Akses Gratis)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: item.badge2Color,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x24000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              item.badge2Text,
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
                            onTap: () => _toggleSelection(item.id),
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
                            onTap: () => _toggleSaveItem(item),
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

                  // Bottom Left: Location text with yellow location pin
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
                            item.location,
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

                  // Bottom Right: Distance / Highlight Dark Pill
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
                        item.highlightBadge,
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
                            item.name,
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
                                item.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${item.reviewCount})',
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Information details row (price/hours/facility)
                    Row(
                      children: [
                        if (item.priceInfo != null) ...[
                          const Icon(Icons.payments_outlined, size: 15, color: _primaryBlue),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.priceInfo!,
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
                        ] else if (item.hoursInfo != null) ...[
                          const Icon(Icons.access_time_rounded, size: 15, color: _primaryBlue),
                          const SizedBox(width: 5),
                          Text(
                            item.hoursInfo!,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                        if ((item.priceInfo != null && item.hoursInfo != null) ||
                            (item.hoursInfo != null && item.facilityInfo != null)) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              item.hoursInfo != null && item.priceInfo != null
                                  ? item.hoursInfo!
                                  : item.facilityInfo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12.5,
                                fontWeight: item.hoursInfo != null && item.priceInfo != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: item.hoursInfo != null && item.priceInfo != null
                                    ? const Color(0xFFB45309)
                                    : _slateText,
                              ),
                            ),
                          ),
                        ],
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

  // ── SELECTION MODE BOTTOM ACTION BAR ────────────────────────────────────────
  Widget _buildSelectionBottomBar() {
    final count = _selectedItemIds.length;
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
          // Buat Trip Button
          FilledButton.icon(
            onPressed: count == 0 ? null : _createTripFromSelected,
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
