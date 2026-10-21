import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One of the four route weights (0-10; the backend turns them into TOPSIS
/// weights), used by the profile defaults and trip step 3.
class WeightSlider extends StatelessWidget {
  const WeightSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.icon,
    this.valueLabel,
    this.hint,
    this.minLabel,
    this.maxLabel,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Shown before the label.
  final IconData? icon;

  /// Pill at the end of the label row, e.g. "7/10 (Prioritas)".
  final String? valueLabel;

  /// Caption under the slider.
  final String? hint;

  /// What 0 and 10 mean, under both ends of the slider.
  final String? minLabel;
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final captionStyle = appText(11, FontWeight.w500, AppColors.inkMuted, height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.sea600),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(label, style: appText(14, FontWeight.w600, AppColors.ink))),
            if (valueLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(999)),
                child: Text(valueLabel!, style: appText(11.5, FontWeight.w700, AppColors.sea600, height: 16)),
              ),
          ],
        ),
        if (valueLabel != null) const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.sea600,
            inactiveTrackColor: AppColors.field,
            thumbColor: AppColors.sea600,
            overlayColor: AppColors.sea600.withValues(alpha: 0.12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            padding: EdgeInsets.zero,
          ),
          child: SizedBox(
            height: 28,
            child: Slider(
              value: value,
              max: 10,
              divisions: 10,
              label: value.round().toString(),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
        if (hint != null) Text(hint!, style: captionStyle),
        if (minLabel != null || maxLabel != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(minLabel ?? '', style: captionStyle)),
              const SizedBox(width: 12),
              Flexible(child: Text(maxLabel ?? '', style: captionStyle, textAlign: TextAlign.end)),
            ],
          ),
      ],
    );
  }
}
