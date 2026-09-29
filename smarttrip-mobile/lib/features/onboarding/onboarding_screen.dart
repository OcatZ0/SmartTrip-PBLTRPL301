import 'package:flutter/material.dart';

/// Onboarding "Pilih Minat" gate (PRD Section 8 - mandatory, min 1 category).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Onboarding: Pilih Minat'),
      ),
    );
  }
}
