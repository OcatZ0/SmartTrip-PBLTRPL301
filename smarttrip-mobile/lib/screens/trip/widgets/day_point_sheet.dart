import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/trip_error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/catalog_search_field.dart';
import '../map_pin_picker_screen.dart';
import '../trip_hotel_screen.dart';

/// What was picked for one end of a day: the default (the main hotel for a
/// start, the day's own start for an end) or a hotel / map pin.
sealed class DayPointPick {
  const DayPointPick();
}

class DefaultDayPoint extends DayPointPick {
  const DefaultDayPoint();
}

class ChosenDayPoint extends DayPointPick {
  const ChosenDayPoint(this.choice);

  final HotelChoice choice;
}

/// Picks where a day starts or ends: the default, a catalog hotel found by
/// name, or a pin on the map. Pops with a [DayPointPick], or null on cancel.
class DayPointSheet extends ConsumerStatefulWidget {
  const DayPointSheet({
    super.key,
    required this.title,
    required this.defaultLabel,
    required this.defaultCaption,
    required this.isDefault,
  });

  final String title;

  /// "Hotel utama" for a start, "Sama dengan titik awal" for an end.
  final String defaultLabel;
  final String defaultCaption;

  /// The day uses the default now, so that option shows as picked.
  final bool isDefault;

  static Future<DayPointPick?> show(
    BuildContext context, {
    required String title,
    required String defaultLabel,
    required String defaultCaption,
    required bool isDefault,
  }) {
    return showModalBottomSheet<DayPointPick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: DayPointSheet(
          title: title,
          defaultLabel: defaultLabel,
          defaultCaption: defaultCaption,
          isDefault: isDefault,
        ),
      ),
    );
  }

  @override
  ConsumerState<DayPointSheet> createState() => _DayPointSheetState();
}

class _DayPointSheetState extends ConsumerState<DayPointSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _pinOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const MapPinPickerScreen()),
    );
    if (picked == null || !mounted) return;
    Navigator.of(context).pop(ChosenDayPoint(CustomHotelChoice(name: picked.name, lat: picked.lat, lng: picked.lng)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(hotelSearchProvider(_query));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: appText(18, FontWeight.w800, AppColors.ink, height: 24)),
          const SizedBox(height: 12),
          _OptionRow(
            icon: Icons.hotel_rounded,
            title: widget.defaultLabel,
            caption: widget.defaultCaption,
            selected: widget.isDefault,
            onTap: () => Navigator.of(context).pop(const DefaultDayPoint()),
          ),
          const SizedBox(height: 8),
          _OptionRow(
            icon: Icons.add_location_alt_outlined,
            title: l10n.dayPointPinOnMap,
            caption: l10n.dayPointPinOnMapHint,
            selected: false,
            onTap: _pinOnMap,
          ),
          const SizedBox(height: 14),
          Text(l10n.dayPointSearchTitle, style: appText(13, FontWeight.w700, AppColors.ink)),
          const SizedBox(height: 8),
          CatalogSearchField(
            controller: _searchController,
            hintText: l10n.tripHotelSearchHint,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 6),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sea600)),
              error: (error, _) => Center(
                child: Text(tripErrorMessage(error, l10n), textAlign: TextAlign.center),
              ),
              data: (places) => places.isEmpty
                  ? Center(
                      child: Text(
                        l10n.tripHotelNoResult,
                        style: appText(13, FontWeight.w600, AppColors.inkMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        final area = place.kecamatan ?? place.address;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: const Icon(Icons.hotel_outlined, color: AppColors.sea600),
                          title: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(14, FontWeight.w700, AppColors.ink),
                          ),
                          subtitle: area == null || area.isEmpty
                              ? null
                              : Text(
                                  area,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(12, FontWeight.w500, AppColors.inkMuted),
                                ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                          onTap: () => Navigator.of(context).pop(ChosenDayPoint(CatalogHotelChoice(place))),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.field : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.sea600 : AppColors.line, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.sea600),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: appText(14, FontWeight.w700, AppColors.ink)),
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.sea600),
            ],
          ),
        ),
      ),
    );
  }
}
