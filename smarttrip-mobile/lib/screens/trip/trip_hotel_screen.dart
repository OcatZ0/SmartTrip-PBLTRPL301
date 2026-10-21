import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/place_photo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_pill.dart';
import '../catalog/widgets/catalog_filter_chip.dart';
import '../catalog/widgets/catalog_search_field.dart';
import 'map_pin_picker_screen.dart';
import 'widgets/setup_card.dart';

/// C4. Pilih Hotel (Section 13 step 5) - step 4 of the trip setup, in the
/// catalog look of step 2: search field, chips for the top-3 recommended
/// hotels or every lodging place, and a pin on the map for a hotel outside
/// the catalog.
class TripHotelScreen extends ConsumerStatefulWidget {
  const TripHotelScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<TripHotelScreen> createState() => _TripHotelScreenState();
}

class _TripHotelScreenState extends ConsumerState<TripHotelScreen> {
  static const _searchDebounce = Duration(milliseconds: 400);

  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearchTab = false;
  String _query = '';
  HotelChoice? _choice;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _isSearchTab = true;
      });
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _isSearchTab = false;
    });
  }

  Future<void> _addManualHotel() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const MapPinPickerScreen()),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _choice = CustomHotelChoice(name: picked.name, lat: picked.lat, lng: picked.lng);
    });
  }

  bool _isChosen(TripPlace place) {
    final choice = _choice;
    return choice is CatalogHotelChoice && choice.place.placesId == place.placesId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submitState = ref.watch(tripHotelControllerProvider);
    final choice = _choice;

    ref.listen(tripHotelControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;

      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(tripErrorMessage(next.error!, l10n))));
        return;
      }

      if (next.valueOrNull == true) context.push(AppRoutes.tripGenerate(widget.tripsId));
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ScreenHeader(
        subtitle: l10n.tripHotelHeader,
        trailing: StepPill(step: 4, total: 4, label: l10n.tripStepLabel(4, 4, l10n.tripHotelHeader)),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(
                    choice is CustomHotelChoice ? Icons.push_pin_rounded : Icons.hotel_rounded,
                    size: 16,
                    color: choice == null ? AppColors.inkMuted : AppColors.sea600,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.tripHotelSelectedLabel, style: appText(12, FontWeight.w600, AppColors.inkMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      choice?.name ?? l10n.tripHotelNoneSelected,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(13, FontWeight.w800, choice == null ? AppColors.inkMuted : AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l10n.tripGenerateButton,
              trailingIcon: Icons.auto_awesome_rounded,
              isLoading: submitState.isLoading,
              onPressed: choice == null
                  ? null
                  : () => ref.read(tripHotelControllerProvider.notifier).submit(widget.tripsId, choice),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tripGenerateHint,
              textAlign: TextAlign.center,
              style: appText(11, FontWeight.w500, AppColors.inkMuted, height: 15),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tripHotelBadge.toUpperCase(),
                  style: appText(11, FontWeight.w800, AppColors.sea600, height: 16, letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tripHotelTitle,
                  style: appText(22, FontWeight.w800, AppColors.ink, height: 28, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(l10n.tripHotelSubtitle, style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 19)),
                const SizedBox(height: 14),
                CatalogSearchField(
                  controller: _searchController,
                  hintText: l10n.tripHotelSearchHint,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                CatalogFilterChip(
                  label: l10n.tripHotelTabRecommended,
                  leading: Icons.auto_awesome_outlined,
                  selected: !_isSearchTab,
                  onTap: () => setState(() => _isSearchTab = false),
                ),
                const SizedBox(width: 8),
                CatalogFilterChip(
                  label: l10n.tripHotelTabSearch,
                  leading: Icons.manage_search_rounded,
                  selected: _isSearchTab,
                  onTap: () => setState(() => _isSearchTab = true),
                ),
                const SizedBox(width: 8),
                Center(child: Container(width: 1, height: 24, color: AppColors.line)),
                const SizedBox(width: 8),
                CatalogFilterChip(
                  label: l10n.tripWishlistPin,
                  leading: Icons.add_location_alt_outlined,
                  selected: choice is CustomHotelChoice,
                  onTap: _addManualHotel,
                ),
              ],
            ),
          ),
          if (choice is CustomHotelChoice)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _CustomHotelSummary(choice: choice, onChange: _addManualHotel),
            ),
          if (_isSearchTab) _buildSearchResults(l10n) else _buildRecommendations(l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Center(
              child: TextButton.icon(
                onPressed: _addManualHotel,
                style: TextButton.styleFrom(foregroundColor: AppColors.link),
                icon: const Icon(Icons.add_location_alt_outlined, size: 17),
                label: Text(
                  l10n.tripHotelManual,
                  textAlign: TextAlign.center,
                  style: appText(12.5, FontWeight.w700, AppColors.link, height: 17),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SetupCard(
              child: SetupCardHeading(
                icon: Icons.route_outlined,
                title: l10n.tripHotelInfoTitle,
                caption: l10n.tripHotelInfoBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(AppLocalizations l10n) {
    final options = ref.watch(hotelOptionsProvider(widget.tripsId));

    return options.when(
      loading: () => const _Loading(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(hotelOptionsProvider(widget.tripsId)),
        ),
      ),
      data: (options) {
        if (options.isEmpty) return _EmptyMessage(text: l10n.tripHotelNoRecommendation);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.tripHotelRecommendedTitle(options.length),
                      style: appText(16, FontWeight.w800, AppColors.ink, height: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 11, color: AppColors.sun400),
                        const SizedBox(width: 4),
                        Text(
                          l10n.tripHotelRecommendedBadge,
                          style: appText(10.5, FontWeight.w800, Colors.white, height: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(l10n.tripHotelRecommendedHint, style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16)),
              for (final option in options) ...[
                const SizedBox(height: 14),
                _HotelCard(
                  place: option.place,
                  rankLabel: l10n.tripHotelRank(option.rank),
                  isChosen: _isChosen(option.place),
                  onChoose: () => setState(() => _choice = CatalogHotelChoice(option.place)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    final results = ref.watch(hotelSearchProvider(_query));

    return results.when(
      loading: () => const _Loading(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LoadErrorView(
          message: tripErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(hotelSearchProvider(_query)),
        ),
      ),
      data: (places) {
        if (places.isEmpty) return _EmptyMessage(text: l10n.tripHotelNoResult);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final place in places) ...[
                const SizedBox(height: 14),
                _HotelCard(
                  place: place,
                  isChosen: _isChosen(place),
                  onChoose: () => setState(() => _choice = CatalogHotelChoice(place)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A hotel with its photo: a sea blue frame and check once chosen; the
/// recommended ones carry their rank in a sun badge.
class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.place,
    required this.isChosen,
    required this.onChoose,
    this.rankLabel,
  });

  final TripPlace place;
  final bool isChosen;
  final VoidCallback onChoose;
  final String? rankLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final area = place.kecamatan ?? place.address;

    return Semantics(
      button: true,
      selected: isChosen,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isChosen ? AppColors.sea600 : Colors.transparent, width: 2),
        ),
        child: InkWell(
          onTap: onChoose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlacePhoto(url: place.photoUrl, icon: Icons.hotel),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x990A2440), Color(0x000A2440), Color(0x330A2440)],
                        ),
                      ),
                    ),
                    if (rankLabel != null)
                      Positioned(
                        left: 10,
                        top: 10,
                        right: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                            decoration: BoxDecoration(
                              color: AppColors.sun400,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 12, color: AppColors.navy900),
                                const SizedBox(width: 4),
                                Text(rankLabel!, style: appText(11, FontWeight.w800, AppColors.navy900, height: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isChosen ? AppColors.sea600 : Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isChosen ? Icons.check_rounded : Icons.radio_button_unchecked,
                          size: 16,
                          color: isChosen ? Colors.white : AppColors.inkMuted,
                        ),
                      ),
                    ),
                    if (place.rating != null)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.navy900.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.sun400),
                              const SizedBox(width: 3),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: appText(11, FontWeight.w700, Colors.white, height: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: appText(15, FontWeight.w800, AppColors.ink, height: 20),
                          ),
                          if (area != null && area.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 13, color: AppColors.inkMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    area,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isChosen ? AppColors.sea600 : AppColors.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isChosen) ...[
                            const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isChosen ? l10n.tripHotelSelected : l10n.tripHotelSelect,
                            style: appText(12, FontWeight.w800, isChosen ? Colors.white : AppColors.sea600),
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
}

/// The hotel pinned on the map, with a button to move the pin.
class _CustomHotelSummary extends StatelessWidget {
  const _CustomHotelSummary({required this.choice, required this.onChange});

  final CustomHotelChoice choice;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.sea600, width: 2),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onChange,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.push_pin_rounded, size: 19, color: AppColors.sea600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(14, FontWeight.w800, AppColors.ink, height: 20),
                    ),
                    Text(
                      '${choice.lat.toStringAsFixed(5)}, ${choice.lng.toStringAsFixed(5)}',
                      style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.sea600),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: AppColors.sea600)),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
      child: Text(text, textAlign: TextAlign.center, style: appText(13, FontWeight.w600, AppColors.inkMuted)),
    );
  }
}

/// Top-3 TOPSIS hotels for the trip (design spec Section 7).
final hotelOptionsProvider =
    FutureProvider.autoDispose.family<List<HotelOption>, int>((ref, tripsId) {
  return ref.watch(tripServiceProvider).fetchHotelOptions(tripsId);
});

/// "Cari Semua Hotel": every catalog place of type lodging matching the query.
final hotelSearchProvider =
    FutureProvider.autoDispose.family<List<TripPlace>, String>((ref, query) {
  return ref.watch(tripServiceProvider).searchHotels(query);
});

/// The hotel picked in step 4: a catalog place or a custom map pin.
sealed class HotelChoice {
  const HotelChoice();

  String get name;
}

class CatalogHotelChoice extends HotelChoice {
  const CatalogHotelChoice(this.place);

  final TripPlace place;

  @override
  String get name => place.name;
}

class CustomHotelChoice extends HotelChoice {
  const CustomHotelChoice({required this.name, required this.lat, required this.lng});

  @override
  final String name;
  final double lat;
  final double lng;
}

/// Step 4 (C4) submission: saves the hotel as every day's start/end point.
class TripHotelController extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(int tripsId, HotelChoice choice) async {
    final repository = ref.read(tripServiceProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      switch (choice) {
        case CatalogHotelChoice(:final place):
          await repository.setCatalogHotel(tripsId, place.placesId!);
        case CustomHotelChoice(:final name, :final lat, :final lng):
          await repository.setCustomHotel(tripsId, name: name, lat: lat, lng: lng);
      }
      return true;
    });
  }
}

final tripHotelControllerProvider =
    AsyncNotifierProvider.autoDispose<TripHotelController, bool>(
  TripHotelController.new,
);
