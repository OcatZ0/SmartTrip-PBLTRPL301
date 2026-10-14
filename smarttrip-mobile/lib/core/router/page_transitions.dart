import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material motion pages for go_router. Container transform (catalog card to
/// place detail) is not a page: it wraps the card, see the catalog screen.
class PageTransitions {
  const PageTransitions._();

  static const _duration = Duration(milliseconds: 300);

  /// Fade through, for switching between top-level destinations (bottom
  /// bar tabs, splash to login).
  static Page<void> fadeThrough(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeThroughTransition(animation: animation, secondaryAnimation: secondaryAnimation, child: child),
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
