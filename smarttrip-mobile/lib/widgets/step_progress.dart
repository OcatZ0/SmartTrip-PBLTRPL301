import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// "LANGKAH n DARI 4: ..." label with percentage and a rounded progress bar,
/// used at the top of every trip setup step (C1-C4).
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.label,
  });

  final int step;
  final int totalSteps;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = step / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: appText(11, FontWeight.w800, AppColors.sea600, height: 16, letterSpacing: 0.88),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(fraction * 100).round()}%',
                style: appText(11, FontWeight.w800, AppColors.inkMuted, height: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: (step - 1) / totalSteps, end: fraction),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: AppColors.sun400,
                backgroundColor: AppColors.field,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
