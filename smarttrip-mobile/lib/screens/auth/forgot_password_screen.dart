import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Forgot password - placeholder until the screen is implemented.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginForgotPassword)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}
