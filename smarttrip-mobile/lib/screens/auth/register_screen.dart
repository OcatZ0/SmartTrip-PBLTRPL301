import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/api_failure.dart';
import '../../core/router/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'widgets/auth_layout.dart';
import 'widgets/password_strength_meter.dart';

/// A3. Daftar (Register): same night-harbour glass layout as the login
/// screen (see [AuthScaffold]), with a shorter gap so the longer form fits.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTermsError = false;

  // Fields, not created in build: a recognizer has to be disposed.
  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => _showInfoDialog(AppLocalizations.of(context).registerTerms, 'Syarat & Ketentuan SmartTrip.');
  late final _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => _showInfoDialog(AppLocalizations.of(context).registerPrivacy, 'Kebijakan Privasi SmartTrip.');

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _showTermsError = !_agreedToTerms;
    });

    if (!_formKey.currentState!.validate() || !_agreedToTerms) return;

    ref.read(registerControllerProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );
  }

  void _clearServerError() {
    if (ref.read(registerControllerProvider).hasError) {
      ref.invalidate(registerControllerProvider);
    }
  }

  bool _isFieldError(Object error) =>
      error is ValidationFailure &&
      (error.firstError('name') != null ||
          error.firstError('email') != null ||
          error.firstError('password') != null ||
          error.firstError('password_confirmation') != null);

  String _errorMessage(Object error, AppLocalizations l10n) {
    return switch (error) {
      NetworkFailure() => l10n.errorNetwork,
      ValidationFailure(:final message?) => message,
      _ => l10n.errorGeneric,
    };
  }

  void _showInfoDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;
    final failure = registerState.error;
    final validationFailure = failure is ValidationFailure ? failure : null;

    ref.listen(registerControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error;
        if (error == null || _isFieldError(error)) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_errorMessage(error, l10n))));
      } else if (next.hasValue && next.value != null) {
        final message = next.value!;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: Color(0xFF00568E),
            ),
            title: Text(l10n.registerTitle),
            content: Text(
              message.isNotEmpty
                  ? message
                  : l10n.registerSuccessVerificationSent,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppRoutes.login);
                },
                child: Text(l10n.registerSignIn),
              ),
            ],
          ),
        );
      }
    });

    final linkStyle = authText(12, FontWeight.w600, AuthColors.sun400).copyWith(decoration: TextDecoration.underline);

    return AuthScaffold(
      panoramaGap: 56,
      footer: AuthFooterLink(
        question: l10n.registerAlreadyHaveAccount,
        action: l10n.registerSignIn,
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.login);
          }
        },
      ),
      card: GlassCard(
        title: l10n.registerTitle,
        subtitle: l10n.registerSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassField(
                label: l10n.registerNameLabel,
                controller: _nameController,
                hint: l10n.registerNameHint,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !isLoading,
                forceErrorText: validationFailure?.firstError('name'),
                onChanged: (_) => _clearServerError(),
                validator: (value) => (value?.trim() ?? '').isEmpty ? l10n.validationNameRequired : null,
              ),
              GlassField(
                label: l10n.registerEmailLabel,
                controller: _emailController,
                hint: l10n.registerEmailHint,
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
                label: l10n.registerPasswordLabel,
                labelTrailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.registerPasswordRequirement,
                      style: authText(11, FontWeight.w600, Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                controller: _passwordController,
                hint: l10n.registerPasswordHint,
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !isLoading,
                forceErrorText: validationFailure?.firstError('password'),
                onChanged: (_) => _clearServerError(),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
                  if (value.length < 8) return l10n.validationPasswordMinLength;
                  return null;
                },
                suffix: GlassPasswordToggle(
                  isObscured: _obscurePassword,
                  tooltip: _obscurePassword ? l10n.loginShowPassword : l10n.loginHidePassword,
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              // Only the meter rebuilds while typing, not the whole page.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (context, value, _) => PasswordStrengthMeter(password: value.text),
              ),
              const SizedBox(height: 14),
              GlassField(
                label: l10n.registerConfirmPasswordLabel,
                controller: _confirmPasswordController,
                hint: l10n.registerConfirmPasswordHint,
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
                forceErrorText: validationFailure?.firstError('password_confirmation'),
                onChanged: (_) => _clearServerError(),
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.validationConfirmPasswordRequired;
                  if (value != _passwordController.text) return l10n.validationConfirmPasswordMismatch;
                  return null;
                },
                suffix: GlassPasswordToggle(
                  isObscured: _obscureConfirmPassword,
                  tooltip: _obscureConfirmPassword ? l10n.loginShowPassword : l10n.loginHidePassword,
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isLoading
                    ? null
                    : () => setState(() {
                          _agreedToTerms = !_agreedToTerms;
                          if (_agreedToTerms) _showTermsError = false;
                        }),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: GlassCheckbox(
                        value: _agreedToTerms,
                        hasError: _showTermsError,
                        onChanged: isLoading
                            ? null
                            : (value) => setState(() {
                                  _agreedToTerms = value;
                                  if (_agreedToTerms) _showTermsError = false;
                                }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: authText(12, FontWeight.w400, Colors.white.withValues(alpha: 0.85), height: 1.4),
                          children: [
                            TextSpan(text: l10n.registerTermsPrefix),
                            TextSpan(
                              text: l10n.registerTerms,
                              style: linkStyle,
                              recognizer: _termsRecognizer,
                            ),
                            TextSpan(text: l10n.registerTermsAnd),
                            TextSpan(
                              text: l10n.registerPrivacy,
                              style: linkStyle,
                              recognizer: _privacyRecognizer,
                            ),
                            TextSpan(text: l10n.registerTermsSuffix),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Space kept even when hidden, so the card height never changes.
              Visibility.maintain(
                visible: _showTermsError,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(l10n.validationTermsRequired, style: authText(12, FontWeight.w400, AuthColors.error)),
                ),
              ),
              const SizedBox(height: 18),
              AuthSubmitButton(label: l10n.registerSubmit, isLoading: isLoading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drives the registration form: the state is the in-flight or completed result
/// of the last registration submission (returning the success message from server).
class RegisterController extends AutoDisposeAsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authServiceProvider).register(
            name: name.trim(),
            email: email.trim(),
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
    });
  }
}

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, String?>(
  RegisterController.new,
);
