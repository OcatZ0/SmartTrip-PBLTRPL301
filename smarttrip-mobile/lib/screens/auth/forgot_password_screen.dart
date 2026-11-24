import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/api_failure.dart';
import '../../core/router/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'widgets/auth_layout.dart';

/// A4. Lupa Kata Sandi (F027 / UC-006): asks for the account email and has
/// the server send a reset link. The new password is set on the web page the
/// link opens, so the app only needs this one screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    final String message;
    try {
      message = await ref.read(authServiceProvider).forgotPassword(email: _emailController.text.trim());
    } on ValidationFailure catch (failure) {
      if (mounted) setState(() => _emailError = failure.firstError('email') ?? failure.message);
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error is NetworkFailure ? l10n.errorNetwork : l10n.errorGeneric)));
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF00568E)),
        title: Text(l10n.forgotSentTitle),
        content: Text('${message.isNotEmpty ? message : l10n.forgotSentFallback}\n\n${l10n.forgotSentHint}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.registerSignIn)),
        ],
      ),
    );
    if (mounted) _backToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthScaffold(
      footer: AuthFooterLink(question: l10n.forgotRemembered, action: l10n.registerSignIn, onTap: _backToLogin),
      card: GlassCard(
        title: l10n.forgotTitle,
        subtitle: l10n.forgotSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassField(
                label: l10n.registerEmailLabel,
                controller: _emailController,
                hint: l10n.registerEmailHint,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                enabled: !_sending,
                forceErrorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onFieldSubmitted: (_) => _submit(l10n),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.validationEmailRequired;
                  if (!_emailPattern.hasMatch(email)) return l10n.validationEmailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 18),
              AuthSubmitButton(label: l10n.forgotSubmit, isLoading: _sending, onPressed: () => _submit(l10n)),
            ],
          ),
        ),
      ),
    );
  }
}
