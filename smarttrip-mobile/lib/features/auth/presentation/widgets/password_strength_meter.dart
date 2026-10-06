import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';

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

/// Password strength indicator card matching Figma node 122:324.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final score = calculatePasswordStrength(password);

    final (String label, Color color) = switch (score) {
      1 => (l10n.registerPasswordWeak, const Color(0xFFE53E3E)),
      2 => (l10n.registerPasswordMedium, const Color(0xFFDD6B20)),
      3 => (l10n.registerPasswordStrong, const Color(0xFF1C6FB0)),
      4 => (l10n.registerPasswordVeryStrong, const Color(0xFF00568E)),
      _ => ('-', tokens.textHint),
    };

    const inactiveColor = Color(0xFFDCE4F0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x99EFF4FF),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
