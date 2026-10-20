import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_tokens.dart';

/// Becomes true once the splash animation has played through. The router
/// keeps the app on the splash until both this and session restore are done,
/// so a fast session restore never cuts the animation short.
final splashFinishedProvider = StateProvider<bool>((ref) => false);

/// A1. Splash - Figma Mockup, 5 frames: the logo pulses (shrinks and fades,
/// then returns), shrinks and rises, then "SmartTrip" appears below it.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2100);
  static const _logoSize = 136.0;
  static const _riseDistance = 95.0;
  static const _loginAssets = [
    'assets/images/login_panorama.svg',
    'assets/images/google_g.svg',
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  // Frames 1 -> 2 -> 3: pulse down to 80% / 50% opacity and back.
  late final Animation<double> _pulseScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.8, end: 1), weight: 1),
  ]).animate(_interval(0.0, 0.40, Curves.easeInOut));

  late final Animation<double> _pulseOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.5, end: 1), weight: 1),
  ]).animate(_interval(0.0, 0.40, Curves.easeInOut));

  // Frame 3 -> 4: shrink to 70% and rise.
  late final Animation<double> _settle = _interval(
    0.45,
    0.70,
    Curves.easeOutCubic,
  );

  // Frame 4 -> 5: the wordmark fades and slides up into place.
  late final Animation<double> _wordmark = _interval(
    0.70,
    0.90,
    Curves.easeOut,
  );

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        ref.read(splashFinishedProvider.notifier).state = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;

    // Parse the login page SVGs while the animation plays, so the login page
    // does not stutter on its first frame.
    for (final asset in _loginAssets) {
      SvgAssetLoader(asset).loadBytes(context);
    }

    // Respect the system "remove animations" setting.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(splashFinishedProvider.notifier).state = true;
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final wordmarkStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: tokens.accent,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.2,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final settle = _settle.value;
          final logoScale = _pulseScale.value * (1 - 0.3 * settle);

          // SizedBox.expand: a plain Stack only takes its children's size
          // and would sit in the top-left corner instead of the center.
          return SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -_riseDistance * settle),
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: Transform.scale(
                      scale: logoScale,
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: _logoSize,
                        height: _logoSize * 293 / 288,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _wordmark.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _wordmark.value)),
                    child: Text('SmartTrip', style: wordmarkStyle),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
