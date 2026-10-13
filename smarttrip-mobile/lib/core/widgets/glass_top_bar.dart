import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';

/// Dark frosted 56px top bar from the "Layout - TopBar" reference: back
/// button, title and the user's avatar. Meant to sit fixed over a dark
/// screen, so content scrolls behind its blur.
class GlassTopBar extends ConsumerWidget {
  const GlassTopBar({super.key, required this.title, this.showBack = true, this.onBack});

  static const height = 56.0;

  static const _navy = Color(0xFF0A2440);
  static const _avatarFill = Color(0xFF2B6FAB);

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(sessionControllerProvider).valueOrNull?.name;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.72),
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
                    if (userName != null && userName.isNotEmpty)
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _avatarFill,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                            ),
                            child: Text(
                              userName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontVariations: [FontVariation.weight(800)],
                                color: Colors.white,
                              ),
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
