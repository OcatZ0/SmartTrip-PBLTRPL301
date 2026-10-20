import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/auth/session_controller.dart';
import '../core/theme/app_colors.dart';

/// Frosted 64px top bar shared by the trip screens (Figma "Header"): back
/// button, logo, app name with the screen name below it, and the user avatar.
class ScreenHeader extends ConsumerWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.subtitle, this.onBack, this.trailing});

  final String subtitle;
  final VoidCallback? onBack;

  /// Shown before the avatar, e.g. a log-in button for a guest.
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(sessionControllerProvider).valueOrNull?.name;
    final canGoBack = onBack != null || Navigator.of(context).canPop();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
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
                        icon: const Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.ink),
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
                          Text('SmartTrip', style: appText(17, FontWeight.w800, AppColors.ink, height: 22)),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(11, FontWeight.w600, AppColors.inkMuted, height: 14),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                    if (userName != null && userName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.navy900,
                          child: Text(
                            userName.characters.first.toUpperCase(),
                            style: appText(13, FontWeight.w800, AppColors.sun400),
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
