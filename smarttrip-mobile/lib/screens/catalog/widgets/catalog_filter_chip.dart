import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A pill of the catalog chip bar (navy when picked), also used by trip step 2.
class CatalogFilterChip extends StatelessWidget {
  const CatalogFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.navy900 : Colors.white,
        shape: StadiumBorder(
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: EdgeInsets.only(
              left: leading == null ? 16 : 12,
              right: trailing == null ? 16 : 10,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Icon(
                    leading,
                    size: 16,
                    color: selected
                        ? AppColors.sun400
                        : AppColors.sea600,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: appText(
                    13,
                    selected ? FontWeight.w700 : FontWeight.w600,
                    selected ? Colors.white : AppColors.ink,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    trailing,
                    size: 18,
                    color: selected ? Colors.white : AppColors.inkMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
