// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Access your marine travel plans & wishlist in Batam';

  @override
  String get loginEmailLabel => 'Email Address';

  @override
  String get loginEmailHint => 'name@email.com';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => 'Minimum 8 characters';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginRememberMe => 'Remember Me';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginSubmit => 'Sign In';

  @override
  String get loginOrSignInWith => 'or ';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginBrowseWithoutLogin => 'Continue without logging in';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegisterNow => 'Register Now';

  @override
  String get registerTitle => 'Create New Account';

  @override
  String get registerSubtitle =>
      'Start your smart travel adventure in Batam\neasily & securely.';

  @override
  String get registerNameLabel => 'Full Name';

  @override
  String get registerNameHint => 'e.g. Dian Pratama';

  @override
  String get registerEmailLabel => 'Email Address';

  @override
  String get registerEmailHint => 'dian@example.com';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordHint => 'Minimum 8 characters';

  @override
  String get registerPasswordRequirement => 'Minimum 8 characters';

  @override
  String get registerPasswordStrength => 'Password Strength';

  @override
  String get registerPasswordWeak => 'Weak';

  @override
  String get registerPasswordMedium => 'Medium';

  @override
  String get registerPasswordStrong => 'Strong';

  @override
  String get registerPasswordVeryStrong => 'Very Strong';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerConfirmPasswordHint => 'Re-enter password';

  @override
  String get registerTermsPrefix => 'I agree to the ';

  @override
  String get registerTerms => 'Terms & Conditions';

  @override
  String get registerTermsAnd => ' and ';

  @override
  String get registerPrivacy => 'Privacy Policy';

  @override
  String get registerTermsSuffix => ' of SmartTrip Batam.';

  @override
  String get registerSubmit => 'Register Account';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account?';

  @override
  String get registerSignIn => 'Sign In';

  @override
  String get registerSuccessVerificationSent =>
      'Please check your email to verify your account.';

  @override
  String get validationNameRequired => 'Full name is required';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Invalid email format';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get validationConfirmPasswordRequired =>
      'Confirm password is required';

  @override
  String get validationConfirmPasswordMismatch => 'Passwords do not match';

  @override
  String get validationTermsRequired =>
      'You must agree to the Terms & Conditions';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your internet connection.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorGoogleNotConfigured =>
      'Google sign-in is not configured in this build.';

  @override
  String get comingSoon => 'Coming soon';
}
