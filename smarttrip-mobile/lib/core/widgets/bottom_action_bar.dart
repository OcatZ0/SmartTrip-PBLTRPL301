import 'package:flutter/material.dart';

/// White sticky bottom bar with the soft upward shadow from the Figma trip
/// screens ("Sticky Bottom Action Bar").
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        boxShadow: [
          BoxShadow(color: Color(0x140B2E4A), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}
