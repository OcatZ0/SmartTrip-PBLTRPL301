import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/api_failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/google_auth_service.dart';
import 'login_controller.dart';
import 'widgets/google_sign_in_button.dart';

/// A2. Masuk (Login) - Figma Mockup, node 122:180.
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

    ref.read(loginControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
          remember: _remember,
        );
  }

  // Drops a server-side field error as soon as the user edits the form.
  void _clearServerError() {
    if (ref.read(loginControllerProvider).hasError) {
      ref.invalidate(loginControllerProvider);
    }
  }

  bool _isFieldError(Object error) =>
      error is ValidationFailure &&
      (error.firstError('email') != null ||
          error.firstError('password') != null);

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
    final theme = Theme.of(context);
    final tokens = context.tokens;

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

    final linkStyle = theme.textTheme.labelLarge?.copyWith(
      color: tokens.link,
      fontSize: 16,
      letterSpacing: 0.14,
    );

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 41),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 80,
                      height: 82,
                    ),
                  ),
                  const SizedBox(height: 37),
                  Text(
                    l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: l10n.loginEmailLabel,
                              hintText: l10n.loginEmailHint,
                              controller: _emailController,
                              prefixIcon: Icons.mail_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled: !isLoading,
                              forceErrorText:
                                  validationFailure?.firstError('email'),
                              onChanged: (_) => _clearServerError(),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return l10n.validationEmailRequired;
                                }
                                if (!_emailPattern.hasMatch(email)) {
                                  return l10n.validationEmailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.loginPasswordLabel,
                              hintText: l10n.loginPasswordHint,
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled: !isLoading,
                              forceErrorText:
                                  validationFailure?.firstError('password'),
                              onChanged: (_) => _clearServerError(),
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? l10n.validationPasswordRequired
                                      : null,
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? l10n.loginShowPassword
                                    : l10n.loginHidePassword,
                                padding: EdgeInsets.zero,
                                color: tokens.textSecondary,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(5),
                                    onTap: isLoading
                                        ? null
                                        : () => setState(
                                              () => _remember = !_remember,
                                            ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: FittedBox(
                                            child: Checkbox(
                                              value: _remember,
                                              onChanged: isLoading
                                                  ? null
                                                  : (value) => setState(
                                                        () => _remember =
                                                            value ?? false,
                                                      ),
                                              side: BorderSide(
                                                color: tokens.checkboxBorder,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.loginRememberMe,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    child: Text(
                                      l10n.loginForgotPassword,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: tokens.link,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: PrimaryButton(
                                label: l10n.loginSubmit,
                                trailingIcon: Icons.arrow_forward,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              l10n.loginOrSignInWith,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                            const SizedBox(height: 7),
                            GoogleSignInButton(
                              label: l10n.loginWithGoogle,
                              onPressed: isLoading
                                  ? null
                                  : () => ref
                                      .read(loginControllerProvider.notifier)
                                      .loginWithGoogle(remember: _remember),
                            ),
                            const SizedBox(height: 36),
                            InkWell(
                              onTap: () => context.go(AppRoutes.catalog),
                              child: Text(
                                l10n.loginBrowseWithoutLogin,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: tokens.link,
                                  fontSize: 15,
                                  letterSpacing: 0.24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 39),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 52),
                  Text(
                    l10n.loginNoAccount,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 11),
                  InkWell(
                    onTap: () => context.push(AppRoutes.register),
                    child: Text(
                      l10n.loginRegisterNow,
                      textAlign: TextAlign.center,
                      style: linkStyle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 12, color: tokens.textHint),
                      const SizedBox(width: 6),
                      Text(
                        l10n.loginSecurityNote,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: tokens.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
