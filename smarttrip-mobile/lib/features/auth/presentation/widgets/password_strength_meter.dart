import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'auth_layout.dart';

/// Evaluates password strength (0 to 4).
int calculatePasswordStrength(String password) {
  if (password.isEmpty) return 0;

  int score = 0;
  if (password.length >= 8) score++;
  if (password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'))) {
    score++;
  }
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[^a-zA-Z0-9]')) || password.length >= 12) {
    score++;
  }

  return score;
}

/// Password strength indicator for the dark glass register card. Colors are
/// light tints so every level stays readable on navy.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = calculatePasswordStrength(password);

    final (String label, Color color) = switch (score) {
      1 => (l10n.registerPasswordWeak, AuthColors.error),
      2 => (l10n.registerPasswordMedium, AuthColors.sun400),
      3 => (l10n.registerPasswordStrong, const Color(0xFF8CC8F2)),
      4 => (l10n.registerPasswordVeryStrong, const Color(0xFF7EE0B5)),
      _ => ('-', Colors.white.withValues(alpha: 0.5)),
    };

    final inactiveColor = Colors.white.withValues(alpha: 0.16);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.registerPasswordStrength,
                style: authText(11, FontWeight.w600, Colors.white.withValues(alpha: 0.75)),
              ),
              if (password.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: authText(11, FontWeight.w600, color),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < score;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < 3 ? 6.0 : 0.0,
                  ),
                  decoration: BoxDecoration(
                    color: isFilled ? color : inactiveColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
