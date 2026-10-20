import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const navy900 = Color(0xFF0A2440);
  static const navy700 = Color(0xFF16476D);
  static const sea600 = Color(0xFF2B6FAB);
  static const sun400 = Color(0xFFF6B03C);
  static const surface = Color(0xFFF5F7FB);
  static const field = Color(0xFFEEF2F8);
  static const line = Color(0xFFDBE2EC);
  static const ink = Color(0xFF14212F);
  static const inkMuted = Color(0xFF5D6B7C);
  static const link = Color(0xFF1F5F99);

  // Profile screen palette.
  static const primary = Color(0xFF1B6CB0);
  static const background = Color(0xFFF4F6FC);
  static const textDark = Color(0xFF14284B);
  static const textGrey = Color(0xFF6B7A90);
  static const border = Color(0xFFD6DEEA);
  static const danger = Color(0xFFD32F2F);

  static const cardShadow = [BoxShadow(color: Color(0x0F0A2440), offset: Offset(0, 4), blurRadius: 16)];
  static const floatShadow = [BoxShadow(color: Color(0x590A2440), offset: Offset(0, 18), blurRadius: 40, spreadRadius: -12)];
}

TextStyle appText(double size, FontWeight weight, Color color, {double? height, double letterSpacing = 0}) {
  return TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height == null ? null : height / size,
    letterSpacing: letterSpacing,
  );
}
