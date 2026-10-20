import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// White rounded card used by the trip setup forms, the same card style as
/// the catalog and Trip Tersimpan.
class SetupCard extends StatelessWidget {
  const SetupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

/// Icon tile + title + caption heading of a [SetupCard].
class SetupCardHeading extends StatelessWidget {
  const SetupCardHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.sea600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: appText(14, FontWeight.w800, AppColors.ink, height: 20)),
              const SizedBox(height: 1),
              Text(caption, style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
