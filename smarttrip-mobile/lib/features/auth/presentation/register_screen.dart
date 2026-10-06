import 'package:flutter/gestures.dart';
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
import 'register_controller.dart';
import 'widgets/password_strength_meter.dart';

/// A3. Daftar (Register) - Figma Mockup, node 122:267.
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
  String _password = '';

  @override
  void dispose() {
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
    final theme = Theme.of(context);
    final tokens = context.tokens;

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

    final linkStyle = theme.textTheme.labelLarge?.copyWith(
      color: tokens.link,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: tokens.screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 68,
                      height: 70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.registerTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        l10n.registerSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
                              label: l10n.registerNameLabel,
                              hintText: l10n.registerNameHint,
                              controller: _nameController,
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              enabled: !isLoading,
                              forceErrorText:
                                  validationFailure?.firstError('name'),
                              onChanged: (_) => _clearServerError(),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return l10n.validationNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.registerEmailLabel,
                              hintText: l10n.registerEmailHint,
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
                              label: l10n.registerPasswordLabel,
                              labelTrailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 12,
                                    color: Color(0xFF744A00),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.registerPasswordRequirement,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF744A00),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              hintText: l10n.registerPasswordHint,
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              enabled: !isLoading,
                              forceErrorText:
                                  validationFailure?.firstError('password'),
                              onChanged: (value) {
                                setState(() => _password = value);
                                _clearServerError();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.validationPasswordRequired;
                                }
                                if (value.length < 8) {
                                  return l10n.validationPasswordMinLength;
                                }
                                return null;
                              },
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
                            const SizedBox(height: 10),
                            PasswordStrengthMeter(password: _password),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: l10n.registerConfirmPasswordLabel,
                              hintText: l10n.registerConfirmPasswordHint,
                              controller: _confirmPasswordController,
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              forceErrorText: validationFailure
                                  ?.firstError('password_confirmation'),
                              onChanged: (_) => _clearServerError(),
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.validationConfirmPasswordRequired;
                                }
                                if (value != _passwordController.text) {
                                  return l10n.validationConfirmPasswordMismatch;
                                }
                                return null;
                              },
                              suffix: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? l10n.loginShowPassword
                                    : l10n.loginHidePassword,
                                padding: EdgeInsets.zero,
                                color: tokens.textSecondary,
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: isLoading
                                  ? null
                                  : () => setState(() {
                                        _agreedToTerms = !_agreedToTerms;
                                        if (_agreedToTerms) {
                                          _showTermsError = false;
                                        }
                                      }),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: FittedBox(
                                        child: Checkbox(
                                          value: _agreedToTerms,
                                          onChanged: isLoading
                                              ? null
                                              : (value) => setState(() {
                                                    _agreedToTerms =
                                                        value ?? false;
                                                    if (_agreedToTerms) {
                                                      _showTermsError = false;
                                                    }
                                                  }),
                                          side: BorderSide(
                                            color: _showTermsError
                                                ? theme.colorScheme.error
                                                : tokens.checkboxBorder,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: tokens.textSecondary,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                        children: [
                                          TextSpan(
                                              text: l10n.registerTermsPrefix),
                                          TextSpan(
                                            text: l10n.registerTerms,
                                            style: const TextStyle(
                                              color: Color(0xFF00568E),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => _showInfoDialog(
                                                    l10n.registerTerms,
                                                    'Syarat & Ketentuan SmartTrip Batam.',
                                                  ),
                                          ),
                                          TextSpan(text: l10n.registerTermsAnd),
                                          TextSpan(
                                            text: l10n.registerPrivacy,
                                            style: const TextStyle(
                                              color: Color(0xFF00568E),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => _showInfoDialog(
                                                    l10n.registerPrivacy,
                                                    'Kebijakan Privasi SmartTrip Batam.',
                                                  ),
                                          ),
                                          TextSpan(
                                              text: l10n.registerTermsSuffix),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showTermsError) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(
                                  l10n.validationTermsRequired,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            PrimaryButton(
                              label: l10n.registerSubmit,
                              trailingIcon: Icons.arrow_forward,
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.registerAlreadyHaveAccount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.login);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.registerSignIn,
                              style: linkStyle,
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: Color(0xFF00568E),
                            ),
                          ],
                        ),
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
