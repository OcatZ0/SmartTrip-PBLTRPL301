import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A category pill of the interest picker (sea blue when picked), used by the
/// profile defaults and trip step 3.
class InterestChip extends StatelessWidget {
  const InterestChip({super.key, required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.sea600 : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.sea600 : AppColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon ?? Icons.label_outline, size: 16, color: selected ? Colors.white : AppColors.sea600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(
                      13,
                      selected ? FontWeight.w700 : FontWeight.w600,
                      selected ? Colors.white : const Color(0xFF3A4757),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [InterestChip]s two per row.
class InterestChipGrid extends StatelessWidget {
  const InterestChipGrid({super.key, required this.children});

  final List<InterestChip> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final chip in children) SizedBox(width: width, child: chip)],
        );
      },
    );
  }
}
