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
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Invalid email format';

  @override
  String get validationPasswordRequired => 'Password is required';

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
