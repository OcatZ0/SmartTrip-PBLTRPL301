import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/api_failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../data/google_auth_service.dart';
import 'login_controller.dart';
import 'widgets/auth_layout.dart';
import 'widgets/google_sign_in_button.dart';

/// A2. Masuk (Login): the Batam harbour at dusk with a dark glass sign-in
/// card. Never scrolls, see [AuthScaffold].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _remember = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(loginControllerProvider.notifier)
        .login(email: _emailController.text, password: _passwordController.text, remember: _remember);
  }

  // Drops a server-side field error as soon as the user edits the form.
  void _clearServerError() {
    if (ref.read(loginControllerProvider).hasError) {
      ref.invalidate(loginControllerProvider);
    }
  }

  bool _isFieldError(Object error) =>
      error is ValidationFailure && (error.firstError('email') != null || error.firstError('password') != null);

  String _errorMessage(Object error, AppLocalizations l10n) {
    return switch (error) {
      NetworkFailure() => l10n.errorNetwork,
      GoogleNotConfiguredException() => l10n.errorGoogleNotConfigured,
      ValidationFailure(:final message?) => message,
      _ => l10n.errorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;
    final failure = loginState.error;
    final validationFailure = failure is ValidationFailure ? failure : null;

    ref.listen(loginControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || _isFieldError(error)) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(error, l10n))));
    });

    return AuthScaffold(
      footer: AuthFooterLink(
        question: l10n.loginNoAccount,
        action: l10n.loginRegisterNow,
        onTap: () => context.push(AppRoutes.register),
      ),
      card: GlassCard(
        title: l10n.loginTitle,
        subtitle: l10n.loginSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassField(
                label: l10n.loginEmailLabel,
                controller: _emailController,
                hint: l10n.loginEmailHint,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !isLoading,
                forceErrorText: validationFailure?.firstError('email'),
                onChanged: (_) => _clearServerError(),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.validationEmailRequired;
                  if (!_emailPattern.hasMatch(email)) return l10n.validationEmailInvalid;
                  return null;
                },
              ),
              GlassField(
                label: l10n.loginPasswordLabel,
                controller: _passwordController,
                hint: l10n.loginPasswordHint,
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !isLoading,
                forceErrorText: validationFailure?.firstError('password'),
                onChanged: (_) => _clearServerError(),
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => (value == null || value.isEmpty) ? l10n.validationPasswordRequired : null,
                suffix: GlassPasswordToggle(
                  isObscured: _obscurePassword,
                  tooltip: _obscurePassword ? l10n.loginShowPassword : l10n.loginHidePassword,
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              Row(
                children: [
                  // Takes the free space so "Lupa kata sandi?" sits at the
                  // right edge.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isLoading ? null : () => setState(() => _remember = !_remember),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GlassCheckbox(
                                value: _remember,
                                onChanged: isLoading ? null : (value) => setState(() => _remember = value),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.loginRememberMe,
                                  overflow: TextOverflow.ellipsis,
                                  style: authText(13, FontWeight.w400, Colors.white.withValues(alpha: 0.9)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: AuthColors.sun400,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(l10n.loginForgotPassword, style: authText(13, FontWeight.w600, AuthColors.sun400)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AuthSubmitButton(label: l10n.loginSubmit, isLoading: isLoading, onPressed: _submit),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.loginOrSignInWith,
                      style: authText(12, FontWeight.w500, Colors.white.withValues(alpha: 0.75)),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                ],
              ),
              const SizedBox(height: 14),
              GoogleSignInButton(
                label: l10n.loginWithGoogle,
                onPressed: isLoading
                    ? null
                    : () => ref.read(loginControllerProvider.notifier).loginWithGoogle(remember: _remember),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
