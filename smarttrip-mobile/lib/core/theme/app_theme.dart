import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static const _fontFamily = 'PlusJakartaSans';
  static const _primary = Color(0xFF3584C2);
  static const _textPrimary = Color(0xFF0B1C30);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: _primary).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: _textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppTokens.light.screenBackground,
      textTheme: _textTheme,
      extensions: const [AppTokens.light],
    );
  }

  // The font is a variable font, so the weight axis is set explicitly.
  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      letterSpacing: letterSpacing,
      color: _textPrimary,
    );
  }

  static final TextTheme _textTheme = TextTheme(
    headlineSmall: _style(26, 34, FontWeight.w700, letterSpacing: -0.65),
    bodyMedium: _style(14, 20, FontWeight.w400),
    labelLarge: _style(14, 20, FontWeight.w600, letterSpacing: 0.14),
    labelMedium: _style(12, 16, FontWeight.w600, letterSpacing: 0.24),
    labelSmall: _style(11, 14, FontWeight.w600, letterSpacing: 0.33),
  );
}
