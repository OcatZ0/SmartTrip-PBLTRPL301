import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material motion pages for go_router. Container transform (catalog card to
/// place detail) is not a page: it wraps the card, see the catalog screen.
class PageTransitions {
  const PageTransitions._();

  static const _duration = Duration(milliseconds: 300);

  /// Direction of the last bottom bar move: 1 to a tab on the right, -1 to
  /// the left, 0 when it did not come from the bar (fade only).
  static int tabStep = 0;

  /// Bottom bar tabs: the new tab slides in from the side it sits on, a tab
  /// pushed over another moves that one out the other way.
  static Page<void> tab(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          final shift = 0.3 * tabStep;
          final inT = Curves.easeOutCubic.transform(animation.value);
          final outT = Curves.easeInCubic.transform(secondaryAnimation.value);
          // A page leaving through its own animation only fades: it may be
          // popped (back) or replaced (go), which move in opposite ways.
          final entering = animation.status != AnimationStatus.reverse;
          return FractionalTranslation(
            translation: Offset((entering ? (1 - inT) * shift : 0) - outT * shift, 0),
            child: Opacity(opacity: (inT * (1 - outT)).clamp(0.0, 1.0), child: child),
          );
        },
      ),
    );
  }

  /// Soft fade in, for the login page arriving from the splash. Pages pushed
  /// on top of it (register, forgot password) still move it out with the
  /// horizontal shared axis, matching their own way in.
  static Page<void> softFade(GoRouterState state, Widget child, {Color? fillColor}) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SharedAxisTransition(
          animation: kAlwaysCompleteAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: fillColor,
          child: child,
        ),
      ),
    );
  }

  /// Horizontal shared axis, for pages with an order (login to register,
  /// the Buat Trip steps). [fillColor] is painted behind the cross-fade
  /// (theme canvas, white, by default); dark pages pass their own background
  /// so the fade does not flash white.
  static Page<void> sharedAxis(GoRouterState state, Widget child, {Color? fillColor}) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: fillColor,
        child: child,
      ),
    );
  }
}
