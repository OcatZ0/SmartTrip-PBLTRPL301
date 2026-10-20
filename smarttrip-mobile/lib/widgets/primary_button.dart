import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

/// Full-width 48px primary action button from the Figma design, with an
/// optional trailing icon and a loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        boxShadow: AppTokens.softShadow,
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            disabledBackgroundColor: theme.colorScheme.primary,
            disabledForegroundColor: theme.colorScheme.onPrimary,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 5),
                      Icon(trailingIcon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
