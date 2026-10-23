import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/trip_error_message.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip.dart';
import '../../../services/trip_service.dart';

/// Trips offered by "Tambah ke Trip" (place detail, wishlist).
final myTripsProvider = FutureProvider.autoDispose<List<TripSummary>>((ref) {
  return ref.watch(tripServiceProvider).fetchMyTrips();
});

/// The user's own trips to put places into, with a button for a new trip.
class TripPickerSheet extends ConsumerWidget {
  const TripPickerSheet({super.key});

  /// Pops with the picked trip, or null when dismissed.
  static Future<TripSummary?> show(BuildContext context) {
    return showModalBottomSheet<TripSummary>(
      context: context,
      backgroundColor: AppColors.navy900,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const TripPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final trips = ref.watch(myTripsProvider);
    final muted = Colors.white.withValues(alpha: 0.7);

    final newTripButton = OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.newTrip);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sun400,
        side: const BorderSide(color: AppColors.sun400),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.add),
      label: Text(l10n.detailNewTrip, style: appText(14, FontWeight.w700, AppColors.sun400)),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.detailChooseTrip, style: appText(18, FontWeight.w700, Colors.white, height: 24)),
              const SizedBox(height: 12),
              Flexible(
                child: trips.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.sun400)),
                  ),
                  error: (error, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tripErrorMessage(error, l10n), style: appText(14, FontWeight.w500, muted)),
                      TextButton(
                        onPressed: () => ref.invalidate(myTripsProvider),
                        child: Text(l10n.actionRetry, style: appText(14, FontWeight.w700, AppColors.sun400)),
                      ),
                    ],
                  ),
                  data: (list) => list.isEmpty
                      ? Text(l10n.detailNoTrips, style: appText(14, FontWeight.w500, muted, height: 20))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                          itemBuilder: (context, index) {
                            final trip = list[index];
                            final date = trip.startDate;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.of(context).pop(trip),
                              leading: const Icon(Icons.luggage_outlined, color: AppColors.sun400),
                              title: Text(trip.title, style: appText(15, FontWeight.w700, Colors.white)),
                              subtitle: Text(
                                l10n.detailTripMeta(
                                  trip.numDays,
                                  date == null ? '-' : DateFormat.yMMMd(languageCode).format(date),
                                ),
                                style: appText(12, FontWeight.w500, muted),
                              ),
                              trailing: Icon(Icons.chevron_right, color: muted),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              newTripButton,
            ],
          ),
        ),
      ),
    );
  }
}
