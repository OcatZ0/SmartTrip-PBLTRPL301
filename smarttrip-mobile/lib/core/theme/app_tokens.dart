import 'package:flutter/material.dart';

/// Design tokens that do not fit in Material's `ColorScheme`, taken from the
/// Figma "Mockup" file (A2. Masuk).
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
  });

  static const light = AppTokens(
    screenBackground: Color(0xFFF8F9FF),
    fieldFill: Color(0xFFEFF4FF),
    textSecondary: Color(0xFF414750),
    textHint: Color(0xFF717881),
    link: Color(0xFF00568E),
    checkboxBorder: Color(0xFF9CA3AF),
    socialButtonFill: Color(0xFFF2F2F7),
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

  @override
  AppTokens copyWith({
    Color? screenBackground,
    Color? fieldFill,
    Color? textSecondary,
    Color? textHint,
    Color? link,
    Color? checkboxBorder,
    Color? socialButtonFill,
  }) {
    return AppTokens(
      screenBackground: screenBackground ?? this.screenBackground,
      fieldFill: fieldFill ?? this.fieldFill,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      link: link ?? this.link,
      checkboxBorder: checkboxBorder ?? this.checkboxBorder,
      socialButtonFill: socialButtonFill ?? this.socialButtonFill,
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
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
