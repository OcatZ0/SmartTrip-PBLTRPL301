import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../data/trip_models.dart';
import 'map_pin_picker_screen.dart';
import 'trip_error_message.dart';
import 'trip_hotel_controller.dart';
import 'widgets/load_error_view.dart';
import 'widgets/place_photo.dart';

/// C4. Pilih Hotel - Figma Mockup, node 85:3196 (Section 13 step 5): top-3
/// recommended hotels, a search over every lodging place, or a custom pin.
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
    final theme = Theme.of(context);
    final tokens = context.tokens;
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
      backgroundColor: tokens.screenBackground,
      appBar: ScreenHeader(subtitle: l10n.tripHotelHeader),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: tokens.link, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.tripHotelSelectedLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    choice?.name ?? l10n.tripHotelNoneSelected,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(color: tokens.link),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _GenerateButton(
              label: l10n.tripGenerateButton,
              isLoading: submitState.isLoading,
              onPressed: choice == null
                  ? null
                  : () => ref
                      .read(tripHotelControllerProvider.notifier)
                      .submit(widget.tripsId, choice),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tripGenerateHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ColoredBox(
            color: tokens.fieldFill,
            child: StepProgress(
              step: 4,
              totalSteps: 4,
              label: l10n.tripStepLabel(4, 4, l10n.tripHotelHeader),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.badgeFill,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hotel_outlined, size: 14, color: Color(0xFF001D34)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tripHotelBadge,
                        style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF001D34)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.tripHotelTitle, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  l10n.tripHotelSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.tripHotelSearchHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.textHint),
                prefixIcon: Icon(Icons.search, color: tokens.textSecondary),
                filled: true,
                fillColor: tokens.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _TabSwitcher(
              isSecondSelected: _isSearchTab,
              firstLabel: l10n.tripHotelTabRecommended,
              firstIcon: Icons.auto_awesome,
              secondLabel: l10n.tripHotelTabSearch,
              secondIcon: Icons.manage_search,
              onChanged: (isSearch) => setState(() => _isSearchTab = isSearch),
            ),
          ),
          if (_isSearchTab) _buildSearchResults(l10n) else _buildRecommendations(l10n, theme, tokens),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Center(
              child: TextButton.icon(
                onPressed: _addManualHotel,
                style: TextButton.styleFrom(
                  backgroundColor: tokens.chipFill,
                  foregroundColor: tokens.link,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(l10n.tripHotelManual, textAlign: TextAlign.center),
              ),
            ),
          ),
          if (choice is CustomHotelChoice)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _CustomHotelSummary(choice: choice),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.fieldFill,
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: tokens.link.withValues(alpha: 0.1),
                    child: Icon(Icons.route_outlined, size: 20, color: tokens.link),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.tripHotelInfoTitle, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          l10n.tripHotelInfoBody,
                          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(AppLocalizations l10n, ThemeData theme, AppTokens tokens) {
    final options = ref.watch(hotelOptionsProvider(widget.tripsId));

    return options.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => LoadErrorView(
        message: tripErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(hotelOptionsProvider(widget.tripsId)),
      ),
      data: (options) {
        if (options.isEmpty) return _EmptyMessage(text: l10n.tripHotelNoRecommendation);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(l10n.tripHotelRecommendedTitle(options.length), style: theme.textTheme.titleSmall),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0E4FF),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(l10n.tripHotelRecommendedBadge, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
              Text(
                l10n.tripHotelRecommendedHint,
                style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
              ),
              for (final option in options) ...[
                const SizedBox(height: 16),
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
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => LoadErrorView(
        message: tripErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(hotelSearchProvider(_query)),
      ),
      data: (places) {
        if (places.isEmpty) return _EmptyMessage(text: l10n.tripHotelNoResult);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            children: [
              for (final place in places) ...[
                const SizedBox(height: 16),
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

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.isSecondSelected,
    required this.firstLabel,
    required this.firstIcon,
    required this.secondLabel,
    required this.secondIcon,
    required this.onChanged,
  });

  final bool isSecondSelected;
  final String firstLabel;
  final IconData firstIcon;
  final String secondLabel;
  final IconData secondIcon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget tab({required bool isSelected, required String label, required IconData icon, required VoidCallback onTap}) {
      final color = isSelected ? tokens.link : const Color(0xFF43617F);
      return Expanded(
        child: Material(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Row(
        children: [
          tab(isSelected: !isSecondSelected, label: firstLabel, icon: firstIcon, onTap: () => onChanged(false)),
          const SizedBox(width: 4),
          tab(isSelected: isSecondSelected, label: secondLabel, icon: secondIcon, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final area = place.kecamatan ?? place.address;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        boxShadow: isChosen ? AppTokens.softShadow : const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlacePhoto(url: place.photoUrl, icon: Icons.hotel),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC0B1C30), Color(0x000B1C30), Color(0x4D000000)],
                    ),
                  ),
                ),
                if (isChosen)
                  Positioned(left: 0, right: 0, top: 0, child: Container(height: 6, color: tokens.accent)),
                if (rankLabel != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 52,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tokens.badgeFill.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF001D34)),
                            const SizedBox(width: 4),
                            Text(
                              rankLabel!,
                              style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF001D34)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isChosen ? tokens.link : Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Icon(
                      isChosen ? Icons.check : Icons.radio_button_unchecked,
                      size: 16,
                      color: isChosen ? Colors.white : tokens.textSecondary,
                    ),
                  ),
                ),
                if (place.rating != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB956)),
                          const SizedBox(width: 4),
                          Text(place.rating!.toStringAsFixed(1), style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: theme.textTheme.titleSmall),
                      if (area != null && area.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(Icons.place_outlined, size: 13, color: tokens.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                area,
                                style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: onChoose,
                    style: FilledButton.styleFrom(
                      backgroundColor: isChosen ? tokens.accent : tokens.accentSoft,
                      foregroundColor: isChosen ? Colors.white : tokens.link,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
                    ),
                    icon: isChosen ? const Icon(Icons.check_circle_outline, size: 16) : const SizedBox.shrink(),
                    label: Text(isChosen ? l10n.tripHotelSelected : l10n.tripHotelSelect),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomHotelSummary extends StatelessWidget {
  const _CustomHotelSummary({required this.choice});

  final CustomHotelChoice choice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tokens.accent, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, color: tokens.link),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choice.name, style: theme.textTheme.labelLarge),
                Text(
                  '${choice.lat.toStringAsFixed(5)}, ${choice.lng.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: tokens.accent),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.tokens.textSecondary),
      ),
    );
  }
}

/// The amber "Buat Itinerary" call to action from the Figma C4 bottom bar.
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.label, required this.isLoading, required this.onPressed});

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: tokens.amberFill,
          foregroundColor: tokens.onAmber,
          disabledBackgroundColor: tokens.amberFill.withValues(alpha: isLoading ? 1 : 0.5),
          disabledForegroundColor: tokens.onAmber.withValues(alpha: isLoading ? 1 : 0.5),
          elevation: isEnabled ? 4 : 0,
          shadowColor: const Color(0x59E8A33D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: tokens.onAmber),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}
