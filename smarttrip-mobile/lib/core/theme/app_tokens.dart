import 'package:flutter/material.dart';

/// Design tokens that do not fit in Material's `ColorScheme`, taken from the
/// Figma "Mockup" file (A2. Masuk, plus the trip screens C1-E1).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.screenBackground,
    required this.fieldFill,
    required this.textSecondary,
    required this.textHint,
    required this.link,
    required this.checkboxBorder,
    required this.socialButtonFill,
    required this.accent,
    required this.accentSoft,
    required this.chipFill,
    required this.badgeFill,
    required this.amberFill,
    required this.onAmber,
    required this.successFill,
    required this.onSuccess,
  });

  static const light = AppTokens(
    screenBackground: Color(0xFFF8F9FF),
    fieldFill: Color(0xFFEFF4FF),
    textSecondary: Color(0xFF414750),
    textHint: Color(0xFF717881),
    link: Color(0xFF00568E),
    checkboxBorder: Color(0xFF9CA3AF),
    socialButtonFill: Color(0xFFF2F2F7),
    accent: Color(0xFF1C6FB0),
    accentSoft: Color(0xFFDCE9FF),
    chipFill: Color(0xFFE5EEFF),
    badgeFill: Color(0xFFBCDAFE),
    amberFill: Color(0xFFFFDDB5),
    onAmber: Color(0xFF2A1800),
    successFill: Color(0xFF86F2E4),
    onSuccess: Color(0xFF006A61),
  );

  static const double radius = 12;

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  final Color screenBackground;
  final Color fieldFill;
  final Color textSecondary;
  final Color textHint;
  final Color link;
  final Color checkboxBorder;
  final Color socialButtonFill;
  final Color accent;
  final Color accentSoft;
  final Color chipFill;
  final Color badgeFill;
  final Color amberFill;
  final Color onAmber;
  final Color successFill;
  final Color onSuccess;

  @override
  AppTokens copyWith({
    Color? screenBackground,
    Color? fieldFill,
    Color? textSecondary,
    Color? textHint,
    Color? link,
    Color? checkboxBorder,
    Color? socialButtonFill,
    Color? accent,
    Color? accentSoft,
    Color? chipFill,
    Color? badgeFill,
    Color? amberFill,
    Color? onAmber,
    Color? successFill,
    Color? onSuccess,
  }) {
    return AppTokens(
      screenBackground: screenBackground ?? this.screenBackground,
      fieldFill: fieldFill ?? this.fieldFill,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      link: link ?? this.link,
      checkboxBorder: checkboxBorder ?? this.checkboxBorder,
      socialButtonFill: socialButtonFill ?? this.socialButtonFill,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      chipFill: chipFill ?? this.chipFill,
      badgeFill: badgeFill ?? this.badgeFill,
      amberFill: amberFill ?? this.amberFill,
      onAmber: onAmber ?? this.onAmber,
      successFill: successFill ?? this.successFill,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      screenBackground: Color.lerp(screenBackground, other.screenBackground, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      link: Color.lerp(link, other.link, t)!,
      checkboxBorder: Color.lerp(checkboxBorder, other.checkboxBorder, t)!,
      socialButtonFill: Color.lerp(socialButtonFill, other.socialButtonFill, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      badgeFill: Color.lerp(badgeFill, other.badgeFill, t)!,
      amberFill: Color.lerp(amberFill, other.amberFill, t)!,
      onAmber: Color.lerp(onAmber, other.onAmber, t)!,
      successFill: Color.lerp(successFill, other.successFill, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
