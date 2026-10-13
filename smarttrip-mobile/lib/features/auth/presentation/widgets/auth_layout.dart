import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';

/// Night-harbour palette of the auth screens (dark glass over the Barelang
/// panorama), from the design reference given on 2026-10-13.
class AuthColors {
  const AuthColors._();

  static const navy900 = Color(0xFF0A2440);
  static const sun400 = Color(0xFFF6B03C);
  static const error = Color(0xFFFFB4A8);
}

/// Plus Jakarta Sans is bundled as a variable font, so the weight axis must
/// be set explicitly next to [FontWeight].
TextStyle authText(double size, FontWeight weight, Color color, {double? height, double letterSpacing = 0}) {
  return TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Shared frame of the login and register screens: the Barelang dusk
/// panorama, the logo bar with "Lewati", a glass [card] and a [footer].
///
/// It never scrolls. The gap over the panorama plus the card are laid out at
/// a comfortable width and scaled down together when the screen is too short
/// or narrow. When the keyboard opens the page keeps its size and slides up
/// just far enough for the focused field to stay visible (like Android's
/// adjustPan).
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.card,
    required this.footer,
    this.panoramaGap = 128,
  });

  final Widget card;
  final Widget footer;

  /// Space between the top bar and the card where the panorama shows.
  final double panoramaGap;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> {
  static const _panoramaHeight = 300.0;
  static const _minCardWidth = 320.0;
  static const _maxCardWidth = 440.0;

  /// Space kept between the focused text line and the keyboard; it also
  /// covers the field's own bottom padding and border.
  static const _keyboardClearance = 28.0;

  double _lift = 0;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// How far to slide the page up for the focused field. The field's position
  /// is read from the last layout and corrected by the lift applied then, so
  /// the result does not feed back on itself.
  double _liftFor(double keyboardHeight) {
    if (keyboardHeight == 0) return 0;

    final focused = FocusManager.instance.primaryFocus?.context?.findRenderObject();
    if (focused is! RenderBox || !focused.attached || !focused.hasSize) return _lift;

    final unshiftedBottom = focused.localToGlobal(Offset(0, focused.size.height)).dy + _lift;
    final visibleBottom = MediaQuery.sizeOf(context).height - keyboardHeight;
    return math.max(0, unshiftedBottom + _keyboardClearance - visibleBottom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    _lift = _liftFor(MediaQuery.viewInsetsOf(context).bottom);

    return Scaffold(
      backgroundColor: AuthColors.navy900,
      resizeToAvoidBottomInset: false,
      body: Transform.translate(
        offset: Offset(0, -_lift),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _panoramaHeight + topInset,
              child: SvgPicture.asset(
                'assets/images/login_panorama.svg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(skipLabel: l10n.loginBrowseWithoutLogin),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Align(
                          alignment: Alignment.topCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth.clamp(_minCardWidth, _maxCardWidth),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: widget.panoramaGap),
                                  widget.card,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    widget.footer,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.skipLabel});

  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: SvgPicture.asset('assets/images/logo.svg'),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'SmartTrip Batam',
            overflow: TextOverflow.ellipsis,
            style: authText(16, FontWeight.w700, Colors.white),
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.28))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.go(AppRoutes.catalog),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(skipLabel, style: authText(12, FontWeight.w600, Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Blurred dark glass panel holding an auth form.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: AuthColors.navy900.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: authText(26, FontWeight.w800, Colors.white, height: 32 / 26, letterSpacing: -0.52)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: authText(14, FontWeight.w400, Colors.white.withValues(alpha: 0.8), height: 20 / 14),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Label plus translucent text field for the glass card.
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    required this.onChanged,
    this.labelTrailing,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.forceErrorText,
    this.onFieldSubmitted,
  });

  final String label;
  final Widget? labelTrailing;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final String? forceErrorText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    final labelText = Text(
      label,
      style: authText(13, FontWeight.w600, Colors.white.withValues(alpha: 0.9), height: 18 / 13),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: labelTrailing == null
              ? labelText
              : Row(
                  children: [
                    Expanded(child: labelText),
                    labelTrailing!,
                  ],
                ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          forceErrorText: forceErrorText,
          cursorColor: AuthColors.sun400,
          style: authText(14, FontWeight.w400, Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: authText(14, FontWeight.w400, Colors.white.withValues(alpha: 0.62)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.10),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
            suffixIcon: suffix,
            errorStyle: authText(12, FontWeight.w400, AuthColors.error),
            enabledBorder: border(Colors.white.withValues(alpha: 0.24)),
            disabledBorder: border(Colors.white.withValues(alpha: 0.12)),
            focusedBorder: border(AuthColors.sun400, 1.5),
            errorBorder: border(AuthColors.error),
            focusedErrorBorder: border(AuthColors.error, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Eye toggle for a [GlassField] holding a password.
class GlassPasswordToggle extends StatelessWidget {
  const GlassPasswordToggle({super.key, required this.isObscured, required this.tooltip, required this.onPressed});

  final bool isObscured;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.white.withValues(alpha: 0.8),
        size: 20,
      ),
    );
  }
}

/// Amber checkbox for the glass card.
class GlassCheckbox extends StatelessWidget {
  const GlassCheckbox({super.key, required this.value, required this.onChanged, this.hasError = false});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged == null ? null : (checked) => onChanged!(checked ?? false),
        activeColor: AuthColors.sun400,
        checkColor: AuthColors.navy900,
        side: BorderSide(
          color: hasError ? AuthColors.error : Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// The amber primary action of an auth form.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({super.key, required this.label, required this.isLoading, required this.onPressed});

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.sun400,
          foregroundColor: AuthColors.navy900,
          disabledBackgroundColor: AuthColors.sun400.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AuthColors.navy900),
              )
            : Text(label, style: authText(15, FontWeight.w700, AuthColors.navy900)),
      ),
    );
  }
}

/// "Question? Action" line under the card, the action in amber.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(question, style: authText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.85))),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: authText(13, FontWeight.w700, AuthColors.sun400)),
        ),
      ],
    );
  }
}
