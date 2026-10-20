import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/trip_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';

/// Runs `POST /api/trips/{id}/generate` every time the screen opens.
final generateItineraryProvider =
    FutureProvider.autoDispose.family<GenerateResult, int>((ref, tripsId) {
  return ref.watch(tripServiceProvider).generate(tripsId);
});

/// C5. Sedang Membuat Itinerary - Figma Mockup, node 85:3475. The checklist
/// only animates while the single generate request runs; it is not real
/// server progress.
class GenerateItineraryScreen extends ConsumerStatefulWidget {
  const GenerateItineraryScreen({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<GenerateItineraryScreen> createState() => _GenerateItineraryScreenState();
}

class _GenerateItineraryScreenState extends ConsumerState<GenerateItineraryScreen>
    with TickerProviderStateMixin {
  static const _stepDuration = Duration(seconds: 4);

  late final AnimationController _spinController =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _pulseController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat(reverse: true);
  late final Timer _stepTimer;
  int _activeStep = 0;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(_stepDuration, (_) {
      if (_activeStep < 2) setState(() => _activeStep++);
    });
  }

  @override
  void dispose() {
    _stepTimer.cancel();
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final generation = ref.watch(generateItineraryProvider(widget.tripsId));

    ref.listen(generateItineraryProvider(widget.tripsId), (_, next) {
      final result = next.valueOrNull;
      if (result == null) return;

      ref.read(generatedFlagsProvider(widget.tripsId).notifier).state = result;
      ref.invalidate(tripDetailProvider(widget.tripsId));
      context.go(AppRoutes.trip(widget.tripsId));
    });

    final steps = [
      (l10n.generateStepCandidates, l10n.generateStepCandidatesHint),
      (l10n.generateStepRoute, l10n.generateStepRouteHint),
      (l10n.generateStepSchedule, l10n.generateStepScheduleHint),
    ];
    final error = generation.error;

    return PopScope(
      canPop: error != null,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B2E4A), Color(0xFF00568E), Color(0xFF1C6FB0)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 24),
                Center(child: _LogoSpinner(spin: _spinController, pulse: _pulseController)),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    text: error == null ? l10n.generateTitle : l10n.generateFailedTitle,
                    children: [
                      if (error == null)
                        const TextSpan(text: '...', style: TextStyle(color: Color(0xFFFFB956))),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (error != null)
                  _GenerateError(
                    message: tripErrorMessage(error, l10n),
                    onRetry: () => ref.invalidate(generateItineraryProvider(widget.tripsId)),
                    onBack: () => context.pop(),
                  )
                else ...[
                  for (var i = 0; i < steps.length; i++) ...[
                    _ChecklistStep(
                      title: steps[i].$1,
                      subtitle: steps[i].$2,
                      state: i < _activeStep
                          ? _StepState.done
                          : i == _activeStep
                              ? _StepState.active
                              : _StepState.pending,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 40),
                  Text(
                    l10n.generateStage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xCCD3E4FE),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      color: tokens.amberFill,
                      backgroundColor: const Color(0x66213145),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSpinner extends StatelessWidget {
  const _LogoSpinner({required this.spin, required this.pulse});

  final Animation<double> spin;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 256,
      height: 256,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.1, end: 0.3).animate(pulse),
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFFFDDB5), shape: BoxShape.circle),
            ),
          ),
          RotationTransition(
            turns: spin,
            child: const SizedBox(
              width: 224,
              height: 224,
              child: CircularProgressIndicator(
                value: 0.25,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                color: Color(0xFFFFB956),
              ),
            ),
          ),
          ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.03).animate(pulse),
            child: Container(
              width: 144,
              height: 144,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xF2FFFFFF),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25))],
              ),
              child: SvgPicture.asset('assets/images/logo.svg'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _ChecklistStep extends StatelessWidget {
  const _ChecklistStep({required this.title, required this.subtitle, required this.state});

  final String title;
  final String subtitle;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = state == _StepState.active;

    final (Color background, Widget icon, Color titleColor) = switch (state) {
      _StepState.done => (
          const Color(0x33109B81),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF6EE7B7)),
          Colors.white,
        ),
      _StepState.active => (
          const Color(0x4D956000),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB956)),
          ),
          const Color(0xFFFFDDB5),
        ),
      _StepState.pending => (
          const Color(0x1ADCE9FF),
          const Icon(Icons.radio_button_unchecked, size: 16, color: Color(0xFFD3E4FE)),
          const Color(0xFFD3E4FE),
        ),
    };

    return Opacity(
      opacity: state == _StepState.pending ? 0.75 : 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Color(isActive ? 0x80213145 : 0x59213145),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isActive) Container(width: 4, color: const Color(0xFFFFB956)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                        child: icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.labelLarge?.copyWith(color: titleColor)),
                            Text(
                              subtitle,
                              style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xCCD3E4FE)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateError extends StatelessWidget {
  const _GenerateError({required this.message, required this.onRetry, required this.onBack});

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x59213145),
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: context.tokens.amberFill,
            foregroundColor: context.tokens.onAmber,
          ),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.actionRetry),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          child: Text(l10n.actionBack),
        ),
      ],
    );
  }
}
