import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang Kembali'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Akses rencana perjalanan bahari & wishlist wisatamu di Batam'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In id, this message translates to:
  /// **'nama@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get loginPasswordHint;

  /// No description provided for @loginShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan kata sandi'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan kata sandi'**
  String get loginHidePassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In id, this message translates to:
  /// **'Ingat Saya'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa Kata Sandi?'**
  String get loginForgotPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginSubmit;

  /// No description provided for @loginOrSignInWith.
  ///
  /// In id, this message translates to:
  /// **'atau'**
  String get loginOrSignInWith;

  /// No description provided for @loginWithGoogle.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get loginWithGoogle;

  /// No description provided for @loginBrowseWithoutLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk tanpa Login'**
  String get loginBrowseWithoutLogin;

  /// No description provided for @loginNoAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterNow.
  ///
  /// In id, this message translates to:
  /// **'Daftar Sekarang'**
  String get loginRegisterNow;

  /// No description provided for @registerTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat Akun Baru'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai petualangan cerdas wisatamu di Batam\ndengan mudah & aman.'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Lengkap'**
  String get registerNameLabel;

  /// No description provided for @registerNameHint.
  ///
  /// In id, this message translates to:
  /// **'cth. Dian Pratama'**
  String get registerNameHint;

  /// No description provided for @registerEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat Email'**
  String get registerEmailLabel;

  /// No description provided for @registerEmailHint.
  ///
  /// In id, this message translates to:
  /// **'dian@example.com'**
  String get registerEmailHint;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi'**
  String get registerPasswordLabel;

  /// No description provided for @registerPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get registerPasswordHint;

  /// No description provided for @registerPasswordRequirement.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get registerPasswordRequirement;

  /// No description provided for @registerPasswordStrength.
  ///
  /// In id, this message translates to:
  /// **'Kekuatan Sandi'**
  String get registerPasswordStrength;

  /// No description provided for @registerPasswordWeak.
  ///
  /// In id, this message translates to:
  /// **'Lemah'**
  String get registerPasswordWeak;

  /// No description provided for @registerPasswordMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get registerPasswordMedium;

  /// No description provided for @registerPasswordStrong.
  ///
  /// In id, this message translates to:
  /// **'Kuat'**
  String get registerPasswordStrong;

  /// No description provided for @registerPasswordVeryStrong.
  ///
  /// In id, this message translates to:
  /// **'Sangat Kuat'**
  String get registerPasswordVeryStrong;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Kata Sandi'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan ulang kata sandi'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerTermsPrefix.
  ///
  /// In id, this message translates to:
  /// **'Saya menyetujui '**
  String get registerTermsPrefix;

  /// No description provided for @registerTerms.
  ///
  /// In id, this message translates to:
  /// **'Syarat & Ketentuan'**
  String get registerTerms;

  /// No description provided for @registerTermsAnd.
  ///
  /// In id, this message translates to:
  /// **' serta '**
  String get registerTermsAnd;

  /// No description provided for @registerPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Kebijakan Privasi'**
  String get registerPrivacy;

  /// No description provided for @registerTermsSuffix.
  ///
  /// In id, this message translates to:
  /// **' SmartTrip Batam.'**
  String get registerTermsSuffix;

  /// No description provided for @registerSubmit.
  ///
  /// In id, this message translates to:
  /// **'Daftar Akun'**
  String get registerSubmit;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get registerSignIn;

  /// No description provided for @registerSuccessVerificationSent.
  ///
  /// In id, this message translates to:
  /// **'Silakan cek email Anda untuk verifikasi akun.'**
  String get registerSuccessVerificationSent;

  /// No description provided for @validationNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap wajib diisi'**
  String get validationNameRequired;

  /// No description provided for @validationEmailRequired.
  ///
  /// In id, this message translates to:
  /// **'Email wajib diisi'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi wajib diisi'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi minimal 8 karakter'**
  String get validationPasswordMinLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi wajib diisi'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationConfirmPasswordMismatch.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi tidak cocok'**
  String get validationConfirmPasswordMismatch;

  /// No description provided for @validationTermsRequired.
  ///
  /// In id, this message translates to:
  /// **'Anda harus menyetujui Syarat & Ketentuan'**
  String get validationTermsRequired;

  /// No description provided for @errorNetwork.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat terhubung ke server. Periksa koneksi internetmu.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan. Coba lagi.'**
  String get errorGeneric;

  /// No description provided for @errorGoogleNotConfigured.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google belum dikonfigurasi pada build ini.'**
  String get errorGoogleNotConfigured;

  /// No description provided for @comingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera hadir'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
