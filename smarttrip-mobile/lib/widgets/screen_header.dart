import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Navy 56px top bar shared by the trip screens, the same look as the place
/// detail's [GlassTopBar]: back button and the screen name.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.subtitle, this.onBack, this.trailing});

  static const height = 56.0;

  /// The screen name, e.g. "Atur Trip".
  final String subtitle;
  final VoidCallback? onBack;

  /// Shown at the end of the bar, e.g. a log-in button for a guest.
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final canGoBack = onBack != null || Navigator.of(context).canPop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.navy900,
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (canGoBack)
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Colors.white),
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: canGoBack ? 0 : 8),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(16, FontWeight.w700, Colors.white),
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
