import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/api_failure.dart';
import '../../../core/error/trip_error_message.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip.dart';
import '../../../services/trip_service.dart';
import '../../../widgets/load_error_view.dart';

/// Trips other people shared with the user (`GET /api/trips/shared`).
final sharedTripsProvider = FutureProvider.autoDispose<List<SharedTripSummary>>((ref) {
  return ref.watch(tripServiceProvider).fetchSharedTrips();
});

/// F016 Melihat Trip yang Dibagikan: the "Dibagikan" tab of Trip Tersimpan.
/// A pasted invite link joins the trip as a viewer and opens it read-only.
class SharedTripsView extends ConsumerStatefulWidget {
  const SharedTripsView({super.key});

  @override
  ConsumerState<SharedTripsView> createState() => _SharedTripsViewState();
}

class _SharedTripsViewState extends ConsumerState<SharedTripsView> {
  final _linkCtrl = TextEditingController();
  String? _linkError;
  bool _joining = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_linkCtrl.text.trim().isEmpty) {
      setState(() => _linkError = 'Tempel tautan undangan dari pemilik trip.');
      return;
    }
    setState(() {
      _linkError = null;
      _joining = true;
    });
    try {
      final tripsId = await ref.read(tripServiceProvider).joinAsViewer(_linkCtrl.text);
      if (!mounted) return;
      _linkCtrl.clear();
      ref.invalidate(sharedTripsProvider);
      context.push(AppRoutes.sharedTrip(tripsId));
    } on ServerFailure catch (failure) {
      if (!mounted) return;
      setState(() => _linkError = failure.statusCode == 404
          ? 'Tautan undangan tidak valid atau sudah dimatikan pemilik trip.'
          : tripErrorMessage(failure, AppLocalizations.of(context)));
    } catch (error) {
      if (mounted) setState(() => _linkError = tripErrorMessage(error, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sharedTripsProvider);
    final trips = state.valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JoinCard(controller: _linkCtrl, error: _linkError, joining: _joining, onJoin: _join),
          const SizedBox(height: 16),
          if (trips == null && state.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: AppColors.navy900)),
            )
          else if (trips == null && state.hasError)
            LoadErrorView(
              message: tripErrorMessage(state.error!, l10n),
              onRetry: () => ref.invalidate(sharedTripsProvider),
            )
          else if (trips == null || trips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Belum ada trip yang dibagikan kepadamu.',
                textAlign: TextAlign.center,
                style: appText(13, FontWeight.w600, AppColors.inkMuted, height: 18),
              ),
            )
          else
            for (final trip in trips) _SharedTripCard(trip: trip),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.controller, required this.error, required this.joining, required this.onJoin});

  final TextEditingController controller;
  final String? error;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Punya tautan undangan?', style: appText(14, FontWeight.w800, AppColors.ink)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !joining,
                  onSubmitted: (_) => onJoin(),
                  style: appText(13, FontWeight.w600, AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Tempel tautan di sini',
                    hintStyle: appText(13, FontWeight.w500, AppColors.inkMuted),
                    errorText: error,
                    errorMaxLines: 2,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.field,
                    prefixIcon: const Icon(Icons.link_rounded, color: AppColors.inkMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: joining ? null : onJoin,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy900,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: joining
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gabung'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharedTripCard extends StatelessWidget {
  const _SharedTripCard({required this.trip});

  final SharedTripSummary trip;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final start = trip.startDate;
    final dates = start == null
        ? '${trip.numDays} hari'
        : '${DateFormat('d MMM y', languageCode).format(start)} · ${trip.numDays} hari';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(AppRoutes.sharedTrip(trip.tripsId)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.field, shape: BoxShape.circle),
                  child: const Icon(Icons.group_rounded, color: AppColors.sea600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: appText(15, FontWeight.w800, AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(dates, style: appText(12, FontWeight.w600, AppColors.inkMuted, height: 16)),
                      if (trip.ownerName.isNotEmpty)
                        Text('Dari ${trip.ownerName}', style: appText(12, FontWeight.w600, AppColors.sea600, height: 16)),
                      if (!trip.hasItinerary)
                        Text('Itinerary belum dibuat', style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
