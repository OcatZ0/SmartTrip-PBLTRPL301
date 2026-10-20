import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/trip_error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip.dart';
import '../../../services/trip_service.dart';
import '../../../widgets/load_error_view.dart';
import '../../../widgets/place_photo.dart';

final _swapCandidatesProvider = FutureProvider.autoDispose.family<List<TripPlace>, int>((ref, itineraryItemsId) {
  return ref.read(tripServiceProvider).fetchSwapCandidates(itineraryItemsId);
});

final _swapSearchProvider = FutureProvider.autoDispose.family<List<TripPlace>, String>((ref, query) {
  return ref.read(tripServiceProvider).searchPlaces(query);
});

/// D2. Ganti Tempat (F010): pick a replacement for one stop, either from the
/// ranked recommendations or by searching the whole catalog. Pops with the
/// chosen [TripPlace], or null on cancel. [preferIndoor] (rain on that day,
/// F025) lists indoor places first and marks them.
class SwapPlaceSheet extends StatefulWidget {
  const SwapPlaceSheet({super.key, required this.item, this.preferIndoor = false});

  final ItineraryItem item;
  final bool preferIndoor;

  static Future<TripPlace?> show(BuildContext context, ItineraryItem item, {bool preferIndoor = false}) {
    return showModalBottomSheet<TripPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SwapPlaceSheet(item: item, preferIndoor: preferIndoor),
      ),
    );
  }

  @override
  State<SwapPlaceSheet> createState() => _SwapPlaceSheetState();
}

class _SwapPlaceSheetState extends State<SwapPlaceSheet> {
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
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final currentName = widget.item.place?.name ?? l10n.itineraryUnknownPlace;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(l10n.swapTitle, style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              widget.preferIndoor ? l10n.swapRainSubtitle(currentName) : l10n.swapSubtitle(currentName),
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ),
          TabBar(
            labelColor: tokens.link,
            indicatorColor: tokens.link,
            tabs: [Tab(text: l10n.swapTabRecommended), Tab(text: l10n.swapTabSearch)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CandidateList(
                  provider: _swapCandidatesProvider(widget.item.itineraryItemsId),
                  preferIndoor: widget.preferIndoor,
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.swapSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: tokens.fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _CandidateList(provider: _swapSearchProvider(_query), preferIndoor: widget.preferIndoor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(l10n.actionCancel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateList extends ConsumerWidget {
  const _CandidateList({required this.provider, required this.preferIndoor});

  final ProviderListenable<AsyncValue<List<TripPlace>>> provider;
  final bool preferIndoor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return ref.watch(provider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => LoadErrorView(
            message: tripErrorMessage(error, l10n),
            onRetry: () {
              ref.invalidate(_swapCandidatesProvider);
              ref.invalidate(_swapSearchProvider);
            },
          ),
          data: (found) {
            // A stable sort keeps the server's ranking inside each group.
            final places = preferIndoor
                ? [...found.where((place) => !place.isOutdoor), ...found.where((place) => place.isOutdoor)]
                : found;
            if (places.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.swapEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                final rating = place.rating;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 56, height: 56, child: PlacePhoto(url: place.photoUrl)),
                  ),
                  title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (preferIndoor) place.isOutdoor ? l10n.swapOutdoor : l10n.swapIndoor,
                      if (place.kecamatan != null) place.kecamatan!,
                      if (rating != null) '★ ${rating.toStringAsFixed(1)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.swap_horiz, color: tokens.link),
                  onTap: () => Navigator.of(context).pop(place),
                );
              },
            );
          },
        );
  }
}
