import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// "1 / 4" in the navy header of the trip setup steps.
class StepPill extends StatelessWidget {
  const StepPill({super.key, required this.step, required this.total, required this.label});

  final int step;
  final int total;

  /// Read out instead of the bare numbers, e.g. "Langkah 1 dari 4: Atur Trip".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Text('$step / $total', style: appText(12, FontWeight.w700, Colors.white)),
      ),
    );
  }
}
