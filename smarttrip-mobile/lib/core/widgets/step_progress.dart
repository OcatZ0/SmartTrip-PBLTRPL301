import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

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
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final fraction = step / totalSteps;
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      color: tokens.link,
      letterSpacing: 0.8,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label.toUpperCase(), style: labelStyle)),
              const SizedBox(width: 12),
              Text('${(fraction * 100).round()}%', style: labelStyle),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: tokens.accent,
              backgroundColor: tokens.accentSoft,
            ),
          ),
        ],
      ),
    );
  }
}
