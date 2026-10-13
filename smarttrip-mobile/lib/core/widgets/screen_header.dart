import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../auth/session_controller.dart';
import '../theme/app_tokens.dart';

/// Frosted 64px top bar shared by the trip screens (Figma "Header"): back
/// button, logo, app name with the screen name below it, and the user avatar.
class ScreenHeader extends ConsumerWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.subtitle, this.onBack});

  final String subtitle;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final userName = ref.watch(sessionControllerProvider).valueOrNull?.name;
    final canGoBack = onBack != null || Navigator.of(context).canPop();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.screenBackground.withValues(alpha: 0.85),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (canGoBack)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back, size: 22),
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      )
                    else
                      const SizedBox(width: 8),
                    SvgPicture.asset('assets/images/logo.svg', width: 30, height: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SmartTrip Batam',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontVariations: const [FontVariation.weight(700)],
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (userName != null && userName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: tokens.accentSoft,
                          child: Text(
                            userName.characters.first.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(color: tokens.link),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
