import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// A3. Daftar (Register) - placeholder until the screen is implemented.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginRegisterNow)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}
