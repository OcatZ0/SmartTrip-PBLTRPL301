import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Full-width primary action of the trip flow: sea blue, rounded, with an
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
    final isDisabled = onPressed == null && !isLoading;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.sea600,
          foregroundColor: Colors.white,
          // While loading the button keeps its colour; only a real "not yet" greys it.
          disabledBackgroundColor: isDisabled ? AppColors.line : AppColors.sea600,
          disabledForegroundColor: isDisabled ? AppColors.inkMuted : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(15, FontWeight.w700, isDisabled ? AppColors.inkMuted : Colors.white),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
