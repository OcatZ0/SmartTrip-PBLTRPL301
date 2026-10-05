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
  /// **'Masuk ke Akun'**
  String get loginSubmit;

  /// No description provided for @loginOrSignInWith.
  ///
  /// In id, this message translates to:
  /// **'atau masuk dengan'**
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

  /// No description provided for @loginSecurityNote.
  ///
  /// In id, this message translates to:
  /// **'Enkripsi 256-bit berstandar pariwisata aman'**
  String get loginSecurityNote;

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
