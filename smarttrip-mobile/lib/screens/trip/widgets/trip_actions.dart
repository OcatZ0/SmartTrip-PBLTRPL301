import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/trip_error_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/trip_service.dart';
import '../../saved_trip/trip_tersimpan_screen.dart';

/// F011 Hapus Trip, shared by the itinerary menu and the Trip Tersimpan
/// card: asks first, then deletes (soft delete on the server). Returns true
/// once the trip is gone.
Future<bool> confirmDeleteTrip(
  BuildContext context,
  WidgetRef ref, {
  required int tripsId,
  required String title,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus trip?'),
      content: Text('"$title" beserta itinerary-nya akan hilang dari daftar trip. Viewer juga tidak dapat membukanya lagi.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await ref.read(tripServiceProvider).deleteTrip(tripsId);
    ref.invalidate(savedTripsProvider);
    messenger.showSnackBar(SnackBar(content: Text('Trip "$title" dihapus')));
    return true;
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(tripErrorMessage(error, l10n))));
    return false;
  }
}
