import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/api_failure.dart';
import '../../core/router/app_routes.dart';
import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/trip_service.dart';
import 'widgets/shared_trips_view.dart';

/// Opened by an invite link (https://smarttrips.my.id/undangan/{token}, F016):
/// joins the trip as a viewer, then shows it read-only.
class JoinInviteScreen extends ConsumerStatefulWidget {
  const JoinInviteScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends ConsumerState<JoinInviteScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      final tripsId = await ref.read(tripServiceProvider).joinAsViewer(widget.token);
      if (!mounted) return;
      ref.invalidate(sharedTripsProvider);
      context.go(AppRoutes.sharedTrip(tripsId));
    } on ServerFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.statusCode == 404
          ? 'Tautan undangan tidak valid atau sudah dimatikan pemilik trip.'
          : tripErrorMessage(failure, AppLocalizations.of(context)));
    } catch (error) {
      if (mounted) setState(() => _error = tripErrorMessage(error, AppLocalizations.of(context)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: error == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Membuka undangan trip...', style: appText(14, FontWeight.w600, AppColors.ink)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_off, size: 48, color: AppColors.inkMuted),
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center, style: appText(14, FontWeight.w600, AppColors.ink)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.trips),
                      child: const Text('Ke Trip Tersimpan'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
