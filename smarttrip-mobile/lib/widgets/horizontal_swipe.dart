import 'package:flutter/material.dart';

/// Calls [onSwipe] with 1 when the user flicks left (to the next page) and
/// -1 when they flick right (to the previous one). Horizontal lists inside
/// [child] keep their own drags.
class HorizontalSwipe extends StatelessWidget {
  const HorizontalSwipe({super.key, required this.onSwipe, required this.child});

  final ValueChanged<int>? onSwipe;
  final Widget child;

  static const _minVelocity = 300.0;

  @override
  Widget build(BuildContext context) {
    final onSwipe = this.onSwipe;
    if (onSwipe == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() >= _minVelocity) onSwipe(velocity < 0 ? 1 : -1);
      },
      child: child,
    );
  }
}
