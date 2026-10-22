import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A full-screen wait for server work the user has to sit through (saving
/// day points, swapping a place, recomputing routes): the page dimmed like
/// behind a sheet, with a card that says what is happening. Taps and the
/// back button are blocked meanwhile.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.title, required this.message});

  final String title;
  final String message;

  /// Shows the overlay over the whole app while [task] runs, then removes it,
  /// whether [task] succeeded or threw (the error is rethrown).
  static Future<T> run<T>(
    BuildContext context, {
    required String title,
    required String message,
    required Future<T> Function() task,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => BusyOverlay(title: title, message: message),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    );
    unawaited(navigator.push(route));
    try {
      return await task();
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Semantics(
        liveRegion: true,
        label: '$title. $message',
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.navy900.withValues(alpha: 0.5)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                // The white rounded card of the trip screens (SetupCard), with
                // the app's one loading indicator: a plain sea blue spinner.
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(color: AppColors.sea600, strokeCap: StrokeCap.round),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: appText(16, FontWeight.w800, AppColors.ink, height: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 19),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
