import 'package:flutter/material.dart';

/// Dark frosted 56px top bar from the "Layout - TopBar" reference: back
/// button and title. Meant to sit fixed over a dark
/// screen, so content scrolls behind its blur.
class GlassTopBar extends StatelessWidget {
  const GlassTopBar({super.key, required this.title, this.showBack = true, this.onBack});

  static const height = 56.0;

  static const _navy = Color(0xFF0A2440);

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.92),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Colors.white),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: showBack ? 0 : 8),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontVariations: [FontVariation.weight(700)],
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
