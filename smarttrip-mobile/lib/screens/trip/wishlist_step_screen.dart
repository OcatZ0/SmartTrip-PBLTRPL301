import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/step_progress.dart';

/// C2. Susun Wishlist (F007) - step 2 of the trip setup. The wishlist itself
/// is not built yet; this keeps the 4-step flow intact and lets the user
/// continue, since the wishlist is optional (US3).
class WishlistStepScreen extends StatelessWidget {
  const WishlistStepScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      appBar: ScreenHeader(subtitle: l10n.tripWishlistHeader),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: l10n.tripWishlistNext,
          trailingIcon: Icons.arrow_forward,
          onPressed: () => context.push(AppRoutes.tripPreferences(tripsId)),
        ),
      ),
      body: ListView(
        children: [
          StepProgress(
            step: 2,
            totalSteps: 4,
            label: l10n.tripStepLabel(2, 4, l10n.tripWishlistHeader),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 56, color: tokens.link),
                const SizedBox(height: 16),
                Text(
                  l10n.tripWishlistComingSoon,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
