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
  /// **'Masuk untuk lanjut merencanakan tripmu.'**
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
  /// **'Ingat saya'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
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
  /// **'Lanjut dengan Google'**
  String get loginWithGoogle;

  /// No description provided for @loginBrowseWithoutLogin.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get loginBrowseWithoutLogin;

  /// No description provided for @loginNoAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterNow.
  ///
  /// In id, this message translates to:
  /// **'Daftar sekarang'**
  String get loginRegisterNow;

  /// No description provided for @registerTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat Akun Baru'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar untuk mulai merencanakan tripmu di Batam.'**
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

  /// No description provided for @actionRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get actionBack;

  /// No description provided for @actionCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get actionSave;

  /// No description provided for @catalogCreateTrip.
  ///
  /// In id, this message translates to:
  /// **'Buat Trip'**
  String get catalogCreateTrip;

  /// No description provided for @catalogHeaderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get catalogHeaderSubtitle;

  /// No description provided for @catalogLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get catalogLogin;

  /// No description provided for @catalogEyebrow.
  ///
  /// In id, this message translates to:
  /// **'PANDUAN WISATA BATAM'**
  String get catalogEyebrow;

  /// No description provided for @catalogGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, mau ke mana hari ini?'**
  String get catalogGreeting;

  /// No description provided for @catalogTagline.
  ///
  /// In id, this message translates to:
  /// **'Temukan surga bahari & kuliner di Batam'**
  String get catalogTagline;

  /// No description provided for @catalogSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari pantai, jembatan barelang, seafood...'**
  String get catalogSearchHint;

  /// No description provided for @catalogClearSearch.
  ///
  /// In id, this message translates to:
  /// **'Hapus pencarian'**
  String get catalogClearSearch;

  /// No description provided for @catalogFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get catalogFilterAll;

  /// No description provided for @catalogFilterLodging.
  ///
  /// In id, this message translates to:
  /// **'Hotel'**
  String get catalogFilterLodging;

  /// No description provided for @catalogSectionAll.
  ///
  /// In id, this message translates to:
  /// **'Destinasi di Batam'**
  String get catalogSectionAll;

  /// No description provided for @catalogSectionTopRated.
  ///
  /// In id, this message translates to:
  /// **'Rating tertinggi'**
  String get catalogSectionTopRated;

  /// No description provided for @catalogSectionSearch.
  ///
  /// In id, this message translates to:
  /// **'Hasil untuk \"{query}\"'**
  String catalogSectionSearch(String query);

  /// No description provided for @catalogFavoriteCount.
  ///
  /// In id, this message translates to:
  /// **'{count} Favorit'**
  String catalogFavoriteCount(int count);

  /// No description provided for @catalogNoReviews.
  ///
  /// In id, this message translates to:
  /// **'Belum ada ulasan'**
  String get catalogNoReviews;

  /// No description provided for @catalogPriceFreeLabel.
  ///
  /// In id, this message translates to:
  /// **'Tiket Masuk'**
  String get catalogPriceFreeLabel;

  /// No description provided for @catalogPriceFree.
  ///
  /// In id, this message translates to:
  /// **'Gratis'**
  String get catalogPriceFree;

  /// No description provided for @catalogPriceFromLabel.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari'**
  String get catalogPriceFromLabel;

  /// No description provided for @catalogPriceUnknownLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get catalogPriceUnknownLabel;

  /// No description provided for @catalogPriceUnknown.
  ///
  /// In id, this message translates to:
  /// **'Belum ada info'**
  String get catalogPriceUnknown;

  /// No description provided for @catalogTypeAttraction.
  ///
  /// In id, this message translates to:
  /// **'Wisata'**
  String get catalogTypeAttraction;

  /// No description provided for @catalogTypeCulinary.
  ///
  /// In id, this message translates to:
  /// **'Kuliner'**
  String get catalogTypeCulinary;

  /// No description provided for @catalogTypeLodging.
  ///
  /// In id, this message translates to:
  /// **'Hotel'**
  String get catalogTypeLodging;

  /// No description provided for @catalogSaveToWishlist.
  ///
  /// In id, this message translates to:
  /// **'Simpan ke wishlist'**
  String get catalogSaveToWishlist;

  /// No description provided for @catalogRemoveFromWishlist.
  ///
  /// In id, this message translates to:
  /// **'Hapus dari wishlist'**
  String get catalogRemoveFromWishlist;

  /// No description provided for @catalogWishlistFailed.
  ///
  /// In id, this message translates to:
  /// **'Wishlist gagal diperbarui. Coba lagi.'**
  String get catalogWishlistFailed;

  /// No description provided for @catalogEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tempat di katalog.'**
  String get catalogEmpty;

  /// No description provided for @catalogNoResults.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tempat yang cocok. Coba kata kunci atau kategori lain.'**
  String get catalogNoResults;

  /// No description provided for @tripStepLabel.
  ///
  /// In id, this message translates to:
  /// **'Langkah {step} dari {total}: {name}'**
  String tripStepLabel(int step, int total, String name);

  /// No description provided for @tripSetupHeader.
  ///
  /// In id, this message translates to:
  /// **'Atur Trip'**
  String get tripSetupHeader;

  /// No description provided for @tripSetupTitle.
  ///
  /// In id, this message translates to:
  /// **'Rencanakan Trip-mu'**
  String get tripSetupTitle;

  /// No description provided for @tripSetupSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Beri tahu preferensimu, kami susunkan itinerary terbaik.'**
  String get tripSetupSubtitle;

  /// No description provided for @tripDurationLabel.
  ///
  /// In id, this message translates to:
  /// **'Durasi Perjalanan'**
  String get tripDurationLabel;

  /// No description provided for @tripDurationHint.
  ///
  /// In id, this message translates to:
  /// **'Berapa lama liburan di Batam?'**
  String get tripDurationHint;

  /// No description provided for @tripDurationDecrease.
  ///
  /// In id, this message translates to:
  /// **'Kurangi durasi'**
  String get tripDurationDecrease;

  /// No description provided for @tripDurationIncrease.
  ///
  /// In id, this message translates to:
  /// **'Tambah durasi'**
  String get tripDurationIncrease;

  /// No description provided for @tripDays.
  ///
  /// In id, this message translates to:
  /// **'{count} Hari'**
  String tripDays(int count);

  /// No description provided for @tripNights.
  ///
  /// In id, this message translates to:
  /// **'{count} Malam'**
  String tripNights(int count);

  /// No description provided for @tripDurationLongWarning.
  ///
  /// In id, this message translates to:
  /// **'Lebih dari 7 hari boleh, tapi pilihan tempat di Batam bisa mulai terasa berulang.'**
  String get tripDurationLongWarning;

  /// No description provided for @tripBudgetLabel.
  ///
  /// In id, this message translates to:
  /// **'Estimasi Anggaran per Orang'**
  String get tripBudgetLabel;

  /// No description provided for @tripBudgetHint.
  ///
  /// In id, this message translates to:
  /// **'Eksklusi tiket penerbangan utama'**
  String get tripBudgetHint;

  /// No description provided for @tripBudgetEconomy.
  ///
  /// In id, this message translates to:
  /// **'Ekonomis'**
  String get tripBudgetEconomy;

  /// No description provided for @tripBudgetEconomyRange.
  ///
  /// In id, this message translates to:
  /// **'< 1 Jt'**
  String get tripBudgetEconomyRange;

  /// No description provided for @tripBudgetStandard.
  ///
  /// In id, this message translates to:
  /// **'Standar'**
  String get tripBudgetStandard;

  /// No description provided for @tripBudgetStandardRange.
  ///
  /// In id, this message translates to:
  /// **'1 - 2.5 Jt'**
  String get tripBudgetStandardRange;

  /// No description provided for @tripBudgetPremium.
  ///
  /// In id, this message translates to:
  /// **'Premium'**
  String get tripBudgetPremium;

  /// No description provided for @tripBudgetPremiumRange.
  ///
  /// In id, this message translates to:
  /// **'> 2.5 Jt'**
  String get tripBudgetPremiumRange;

  /// No description provided for @validationBudgetRequired.
  ///
  /// In id, this message translates to:
  /// **'Anggaran harus lebih dari 0'**
  String get validationBudgetRequired;

  /// No description provided for @tripDateLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Mulai & Selesai'**
  String get tripDateLabel;

  /// No description provided for @tripDateHint.
  ///
  /// In id, this message translates to:
  /// **'Waktu pelesiran di pulau'**
  String get tripDateHint;

  /// No description provided for @tripStartTimeLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam Mulai'**
  String get tripStartTimeLabel;

  /// No description provided for @tripEndTimeLabel.
  ///
  /// In id, this message translates to:
  /// **'Jam Selesai'**
  String get tripEndTimeLabel;

  /// No description provided for @tripTimeZone.
  ///
  /// In id, this message translates to:
  /// **'WIB'**
  String get tripTimeZone;

  /// No description provided for @validationEndTimeAfterStart.
  ///
  /// In id, this message translates to:
  /// **'Jam selesai harus setelah jam mulai'**
  String get validationEndTimeAfterStart;

  /// No description provided for @tripTipTitle.
  ///
  /// In id, this message translates to:
  /// **'Tips SmartTrip:'**
  String get tripTipTitle;

  /// No description provided for @tripTipBody.
  ///
  /// In id, this message translates to:
  /// **' Waktu terbaik tiba di Batam Centre adalah sebelum jam 10:00 WIB agar itinerary maksimal.'**
  String get tripTipBody;

  /// No description provided for @tripSetupNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut ke Wishlist (2/4)'**
  String get tripSetupNext;

  /// No description provided for @tripCancelTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan pembuatan trip?'**
  String get tripCancelTitle;

  /// No description provided for @tripCancelBody.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan yang belum disimpan akan hilang.'**
  String get tripCancelBody;

  /// No description provided for @tripCancelStay.
  ///
  /// In id, this message translates to:
  /// **'Lanjut Mengisi'**
  String get tripCancelStay;

  /// No description provided for @tripCancelConfirm.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get tripCancelConfirm;

  /// No description provided for @tripWishlistHeader.
  ///
  /// In id, this message translates to:
  /// **'Susun Wishlist'**
  String get tripWishlistHeader;

  /// No description provided for @tripWishlistComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Penyusunan wishlist sedang disiapkan. Kamu tetap bisa lanjut, sistem akan memilihkan tempat terbaik untukmu.'**
  String get tripWishlistComingSoon;

  /// No description provided for @tripWishlistNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut ke Minat & Prioritas (3/4)'**
  String get tripWishlistNext;

  /// No description provided for @tripPreferencesHeader.
  ///
  /// In id, this message translates to:
  /// **'Pilih Minat dan Prioritas'**
  String get tripPreferencesHeader;

  /// No description provided for @tripPreferencesStepName.
  ///
  /// In id, this message translates to:
  /// **'Preferensi & Prioritas'**
  String get tripPreferencesStepName;

  /// No description provided for @tripPreferencesTitle.
  ///
  /// In id, this message translates to:
  /// **'Sesuaikan Karakter Trip-mu'**
  String get tripPreferencesTitle;

  /// No description provided for @tripPreferencesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Algoritma cerdas kami akan mengoptimalkan rute sesuai bobot preferensimu.'**
  String get tripPreferencesSubtitle;

  /// No description provided for @tripInterestTitle.
  ///
  /// In id, this message translates to:
  /// **'Minat untuk Trip Ini'**
  String get tripInterestTitle;

  /// No description provided for @tripInterestHint.
  ///
  /// In id, this message translates to:
  /// **'Kategori yang diprioritaskan dalam trip ini:'**
  String get tripInterestHint;

  /// No description provided for @validationInterestRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal 1 kategori'**
  String get validationInterestRequired;

  /// No description provided for @tripPriorityTitle.
  ///
  /// In id, this message translates to:
  /// **'Apa yang Paling Penting Buatmu?'**
  String get tripPriorityTitle;

  /// No description provided for @tripPriorityHint.
  ///
  /// In id, this message translates to:
  /// **'Geser slider untuk mengatur prioritas komputasi rute.'**
  String get tripPriorityHint;

  /// No description provided for @tripPriorityInterest.
  ///
  /// In id, this message translates to:
  /// **'Kesesuaian Minat Wisata'**
  String get tripPriorityInterest;

  /// No description provided for @tripPriorityInterestMin.
  ///
  /// In id, this message translates to:
  /// **'Eksplorasi Acak'**
  String get tripPriorityInterestMin;

  /// No description provided for @tripPriorityInterestMax.
  ///
  /// In id, this message translates to:
  /// **'Fokus Minat 100%'**
  String get tripPriorityInterestMax;

  /// No description provided for @tripPriorityDistance.
  ///
  /// In id, this message translates to:
  /// **'Jarak / Waktu Perjalanan'**
  String get tripPriorityDistance;

  /// No description provided for @tripPriorityDistanceMin.
  ///
  /// In id, this message translates to:
  /// **'Bebas Keliling'**
  String get tripPriorityDistanceMin;

  /// No description provided for @tripPriorityDistanceMax.
  ///
  /// In id, this message translates to:
  /// **'Paling Cepat'**
  String get tripPriorityDistanceMax;

  /// No description provided for @tripPriorityBudget.
  ///
  /// In id, this message translates to:
  /// **'Kepatuhan Anggaran'**
  String get tripPriorityBudget;

  /// No description provided for @tripPriorityBudgetMin.
  ///
  /// In id, this message translates to:
  /// **'Fleksibel Pengeluaran'**
  String get tripPriorityBudgetMin;

  /// No description provided for @tripPriorityBudgetMax.
  ///
  /// In id, this message translates to:
  /// **'Ketat di Bawah Plafon'**
  String get tripPriorityBudgetMax;

  /// No description provided for @tripPriorityRating.
  ///
  /// In id, this message translates to:
  /// **'Rating & Ulasan Terbaik'**
  String get tripPriorityRating;

  /// No description provided for @tripPriorityRatingMin.
  ///
  /// In id, this message translates to:
  /// **'Spot Hidden Gem'**
  String get tripPriorityRatingMin;

  /// No description provided for @tripPriorityRatingMax.
  ///
  /// In id, this message translates to:
  /// **'Top Verified Only'**
  String get tripPriorityRatingMax;

  /// No description provided for @tripPriorityValue.
  ///
  /// In id, this message translates to:
  /// **'{value}/10 ({level})'**
  String tripPriorityValue(int value, String level);

  /// No description provided for @tripPriorityLevelLow.
  ///
  /// In id, this message translates to:
  /// **'Rendah'**
  String get tripPriorityLevelLow;

  /// No description provided for @tripPriorityLevelMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get tripPriorityLevelMedium;

  /// No description provided for @tripPriorityLevelHigh.
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get tripPriorityLevelHigh;

  /// No description provided for @tripPriorityLevelVeryHigh.
  ///
  /// In id, this message translates to:
  /// **'Sangat Prioritas'**
  String get tripPriorityLevelVeryHigh;

  /// No description provided for @tripSaveDefaultTitle.
  ///
  /// In id, this message translates to:
  /// **'Simpan sebagai preferensi default profil saya'**
  String get tripSaveDefaultTitle;

  /// No description provided for @tripSaveDefaultHint.
  ///
  /// In id, this message translates to:
  /// **'Diterapkan otomatis untuk perencanaan rute berikutnya'**
  String get tripSaveDefaultHint;

  /// No description provided for @tripPreferencesNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut ke Pilih Hotel (4/4)'**
  String get tripPreferencesNext;

  /// No description provided for @tripHotelHeader.
  ///
  /// In id, this message translates to:
  /// **'Pilih Hotel'**
  String get tripHotelHeader;

  /// No description provided for @tripHotelBadge.
  ///
  /// In id, this message translates to:
  /// **'Penentu Titik Berangkat & Pulang'**
  String get tripHotelBadge;

  /// No description provided for @tripHotelTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Titik Menginap / Hotel'**
  String get tripHotelTitle;

  /// No description provided for @tripHotelSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Titik hotel menjadi acuan titik awal keberangkatan dan kepulangan harianmu agar rute keliling Batam seimbang.'**
  String get tripHotelSubtitle;

  /// No description provided for @tripHotelSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama hotel atau resort di Batam...'**
  String get tripHotelSearchHint;

  /// No description provided for @tripHotelTabRecommended.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi Cerdas'**
  String get tripHotelTabRecommended;

  /// No description provided for @tripHotelTabSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari Semua Hotel'**
  String get tripHotelTabSearch;

  /// No description provided for @tripHotelRecommendedTitle.
  ///
  /// In id, this message translates to:
  /// **'{count} Hotel Rekomendasi'**
  String tripHotelRecommendedTitle(int count);

  /// No description provided for @tripHotelRecommendedBadge.
  ///
  /// In id, this message translates to:
  /// **'AI Matched'**
  String get tripHotelRecommendedBadge;

  /// No description provided for @tripHotelRecommendedHint.
  ///
  /// In id, this message translates to:
  /// **'Disesuaikan dengan minat dan anggaran trip-mu'**
  String get tripHotelRecommendedHint;

  /// No description provided for @tripHotelRank.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi #{rank}'**
  String tripHotelRank(int rank);

  /// No description provided for @tripHotelSelect.
  ///
  /// In id, this message translates to:
  /// **'Pilih Hotel Ini'**
  String get tripHotelSelect;

  /// No description provided for @tripHotelSelected.
  ///
  /// In id, this message translates to:
  /// **'Hotel Dipilih'**
  String get tripHotelSelected;

  /// No description provided for @tripHotelNoRecommendation.
  ///
  /// In id, this message translates to:
  /// **'Belum ada rekomendasi hotel. Cari hotel atau tambah manual.'**
  String get tripHotelNoRecommendation;

  /// No description provided for @tripHotelNoResult.
  ///
  /// In id, this message translates to:
  /// **'Hotel tidak ditemukan.'**
  String get tripHotelNoResult;

  /// No description provided for @tripHotelManual.
  ///
  /// In id, this message translates to:
  /// **'Tidak menemukan hotelmu? Tambah hotel manual di peta'**
  String get tripHotelManual;

  /// No description provided for @tripHotelInfoTitle.
  ///
  /// In id, this message translates to:
  /// **'Optimalisasi Navigasi Harian'**
  String get tripHotelInfoTitle;

  /// No description provided for @tripHotelInfoBody.
  ///
  /// In id, this message translates to:
  /// **'Hotel yang kamu pilih menjadi titik awal dan akhir rute setiap hari.'**
  String get tripHotelInfoBody;

  /// No description provided for @tripHotelSelectedLabel.
  ///
  /// In id, this message translates to:
  /// **'Titik Terpilih:'**
  String get tripHotelSelectedLabel;

  /// No description provided for @tripHotelNoneSelected.
  ///
  /// In id, this message translates to:
  /// **'Belum dipilih'**
  String get tripHotelNoneSelected;

  /// No description provided for @tripGenerateButton.
  ///
  /// In id, this message translates to:
  /// **'Buat Itinerary Cerdas Sekarang'**
  String get tripGenerateButton;

  /// No description provided for @tripGenerateHint.
  ///
  /// In id, this message translates to:
  /// **'SmartTrip akan menghitung rute, jam buka, dan durasi kunjungan.'**
  String get tripGenerateHint;

  /// No description provided for @mapPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih Lokasi di Peta'**
  String get mapPickerTitle;

  /// No description provided for @mapPickerHint.
  ///
  /// In id, this message translates to:
  /// **'Ketuk peta untuk menaruh titik lokasi'**
  String get mapPickerHint;

  /// No description provided for @mapPickerPinRequired.
  ///
  /// In id, this message translates to:
  /// **'Ketuk peta untuk memilih lokasi terlebih dahulu'**
  String get mapPickerPinRequired;

  /// No description provided for @mapPickerNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Tempat'**
  String get mapPickerNameLabel;

  /// No description provided for @mapPickerNameHint.
  ///
  /// In id, this message translates to:
  /// **'cth. Hotel Harmoni'**
  String get mapPickerNameHint;

  /// No description provided for @validationPlaceNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama tempat wajib diisi'**
  String get validationPlaceNameRequired;

  /// No description provided for @generateTitle.
  ///
  /// In id, this message translates to:
  /// **'Menyusun Perjalanan Terbaikmu'**
  String get generateTitle;

  /// No description provided for @generateFailedTitle.
  ///
  /// In id, this message translates to:
  /// **'Itinerary gagal dibuat'**
  String get generateFailedTitle;

  /// No description provided for @generateStepCandidates.
  ///
  /// In id, this message translates to:
  /// **'Mengumpulkan tempat wishlist & rekomendasi'**
  String get generateStepCandidates;

  /// No description provided for @generateStepCandidatesHint.
  ///
  /// In id, this message translates to:
  /// **'Mencocokkan minat dan anggaranmu'**
  String get generateStepCandidatesHint;

  /// No description provided for @generateStepRoute.
  ///
  /// In id, this message translates to:
  /// **'Menghitung estimasi rute antar tempat'**
  String get generateStepRoute;

  /// No description provided for @generateStepRouteHint.
  ///
  /// In id, this message translates to:
  /// **'Mengurutkan kunjungan dari hotel'**
  String get generateStepRouteHint;

  /// No description provided for @generateStepSchedule.
  ///
  /// In id, this message translates to:
  /// **'Menyesuaikan jadwal dengan jam buka'**
  String get generateStepSchedule;

  /// No description provided for @generateStepScheduleHint.
  ///
  /// In id, this message translates to:
  /// **'Memastikan tiap hari muat di jam jalan-jalanmu'**
  String get generateStepScheduleHint;

  /// No description provided for @generateStage.
  ///
  /// In id, this message translates to:
  /// **'TAHAP AKHIR KURASI'**
  String get generateStage;

  /// No description provided for @itineraryHeader.
  ///
  /// In id, this message translates to:
  /// **'Trip Saya'**
  String get itineraryHeader;

  /// No description provided for @itineraryDayTab.
  ///
  /// In id, this message translates to:
  /// **'Hari {day} ({date})'**
  String itineraryDayTab(int day, String date);

  /// No description provided for @itineraryRecommended.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi'**
  String get itineraryRecommended;

  /// No description provided for @itineraryFromWishlist.
  ///
  /// In id, this message translates to:
  /// **'Dari Wishlist'**
  String get itineraryFromWishlist;

  /// No description provided for @itineraryVisitMinutes.
  ///
  /// In id, this message translates to:
  /// **'{minutes} menit'**
  String itineraryVisitMinutes(int minutes);

  /// No description provided for @itineraryDistance.
  ///
  /// In id, this message translates to:
  /// **'± {km} km dari tempat sebelumnya'**
  String itineraryDistance(String km);

  /// No description provided for @itineraryVisited.
  ///
  /// In id, this message translates to:
  /// **'Sudah dikunjungi'**
  String get itineraryVisited;

  /// No description provided for @itineraryOpenMap.
  ///
  /// In id, this message translates to:
  /// **'Buka Rute Peta Live'**
  String get itineraryOpenMap;

  /// No description provided for @itineraryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Itinerary belum dibuat untuk trip ini.'**
  String get itineraryEmpty;

  /// No description provided for @itineraryGenerateNow.
  ///
  /// In id, this message translates to:
  /// **'Buat Itinerary'**
  String get itineraryGenerateNow;

  /// No description provided for @itineraryDayEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tempat yang muat di hari ini.'**
  String get itineraryDayEmpty;

  /// No description provided for @itineraryOverpacked.
  ///
  /// In id, this message translates to:
  /// **'Jadwal hari ini cukup padat, pertimbangkan mengganti satu tempat.'**
  String get itineraryOverpacked;

  /// No description provided for @itineraryShortOfPlaces.
  ///
  /// In id, this message translates to:
  /// **'Tempat yang cocok kurang untuk mengisi hari ini.'**
  String get itineraryShortOfPlaces;

  /// No description provided for @itineraryDroppedWishlist.
  ///
  /// In id, this message translates to:
  /// **'{count} tempat wishlist tidak muat dan dilewati.'**
  String itineraryDroppedWishlist(int count);

  /// No description provided for @itineraryStartFrom.
  ///
  /// In id, this message translates to:
  /// **'Berangkat dari {name}'**
  String itineraryStartFrom(String name);

  /// No description provided for @itineraryUnknownPlace.
  ///
  /// In id, this message translates to:
  /// **'Tempat tidak tersedia'**
  String get itineraryUnknownPlace;

  /// No description provided for @liveMapTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelacakan Trip'**
  String get liveMapTitle;

  /// No description provided for @liveMapSubtitle.
  ///
  /// In id, this message translates to:
  /// **'SmartTrip Batam • Hari {day}'**
  String liveMapSubtitle(int day);

  /// No description provided for @liveMapStartDay.
  ///
  /// In id, this message translates to:
  /// **'Mulai Hari Ini'**
  String get liveMapStartDay;

  /// No description provided for @liveMapStopTracking.
  ///
  /// In id, this message translates to:
  /// **'Hentikan Pelacakan'**
  String get liveMapStopTracking;

  /// No description provided for @liveMapTrackingActive.
  ///
  /// In id, this message translates to:
  /// **'Tracking aktif'**
  String get liveMapTrackingActive;

  /// No description provided for @liveMapTrackingOff.
  ///
  /// In id, this message translates to:
  /// **'Tracking belum aktif'**
  String get liveMapTrackingOff;

  /// No description provided for @liveMapCenter.
  ///
  /// In id, this message translates to:
  /// **'Pusatkan lokasi'**
  String get liveMapCenter;

  /// No description provided for @liveMapArrived.
  ///
  /// In id, this message translates to:
  /// **'Kamu sudah tiba di lokasi tujuan!'**
  String get liveMapArrived;

  /// No description provided for @liveMapAutoCheckIn.
  ///
  /// In id, this message translates to:
  /// **'Auto Check-in ✓'**
  String get liveMapAutoCheckIn;

  /// No description provided for @liveMapMarkVisited.
  ///
  /// In id, this message translates to:
  /// **'Selesai Dikunjungi'**
  String get liveMapMarkVisited;

  /// No description provided for @liveMapUnmarkVisited.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Tanda'**
  String get liveMapUnmarkVisited;

  /// No description provided for @liveMapNavigate.
  ///
  /// In id, this message translates to:
  /// **'Buka Navigasi'**
  String get liveMapNavigate;

  /// No description provided for @liveMapStopsTitle.
  ///
  /// In id, this message translates to:
  /// **'Rangkaian Kunjungan Hari Ini'**
  String get liveMapStopsTitle;

  /// No description provided for @liveMapStopsCount.
  ///
  /// In id, this message translates to:
  /// **'{count} Destinasi'**
  String liveMapStopsCount(int count);

  /// No description provided for @liveMapStopVisited.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get liveMapStopVisited;

  /// No description provided for @liveMapStopNext.
  ///
  /// In id, this message translates to:
  /// **'Tujuan berikutnya'**
  String get liveMapStopNext;

  /// No description provided for @liveMapStopPending.
  ///
  /// In id, this message translates to:
  /// **'Belum dikunjungi'**
  String get liveMapStopPending;

  /// No description provided for @liveMapNextBadge.
  ///
  /// In id, this message translates to:
  /// **'Berikutnya'**
  String get liveMapNextBadge;

  /// No description provided for @liveMapAllocation.
  ///
  /// In id, this message translates to:
  /// **'Alokasi {minutes} mnt'**
  String liveMapAllocation(int minutes);

  /// No description provided for @liveMapHotel.
  ///
  /// In id, this message translates to:
  /// **'Hotel'**
  String get liveMapHotel;

  /// No description provided for @liveMapLongPressHint.
  ///
  /// In id, this message translates to:
  /// **'Tekan lama penanda atau daftar tempat untuk menandai/membatalkan kunjungan.'**
  String get liveMapLongPressHint;

  /// No description provided for @liveMapPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin lokasi ditolak. Kamu tetap bisa menandai kunjungan secara manual.'**
  String get liveMapPermissionDenied;

  /// No description provided for @liveMapLocationServiceOff.
  ///
  /// In id, this message translates to:
  /// **'Layanan lokasi (GPS) mati. Nyalakan untuk pelacakan otomatis.'**
  String get liveMapLocationServiceOff;

  /// No description provided for @liveMapVisitQueued.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi. Tanda kunjungan disimpan dan dikirim otomatis nanti.'**
  String get liveMapVisitQueued;

  /// No description provided for @notificationChannelName.
  ///
  /// In id, this message translates to:
  /// **'Kedatangan di Tempat Wisata'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In id, this message translates to:
  /// **'Pemberitahuan saat kamu tiba di tempat dalam itinerary hari ini.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationArrivedTitle.
  ///
  /// In id, this message translates to:
  /// **'Kamu sudah tiba di {name}'**
  String notificationArrivedTitle(String name);

  /// No description provided for @notificationArrivedBody.
  ///
  /// In id, this message translates to:
  /// **'Kunjunganmu otomatis ditandai. Selamat menikmati!'**
  String get notificationArrivedBody;

  /// No description provided for @detailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Destinasi'**
  String get detailTitle;

  /// No description provided for @detailClosedTemporarily.
  ///
  /// In id, this message translates to:
  /// **'Tutup sementara'**
  String get detailClosedTemporarily;

  /// No description provided for @detailFactTicket.
  ///
  /// In id, this message translates to:
  /// **'Tiket masuk'**
  String get detailFactTicket;

  /// No description provided for @detailFactVisit.
  ///
  /// In id, this message translates to:
  /// **'Lama kunjungan'**
  String get detailFactVisit;

  /// No description provided for @detailFactHours.
  ///
  /// In id, this message translates to:
  /// **'Jam buka'**
  String get detailFactHours;

  /// No description provided for @detailFactDistance.
  ///
  /// In id, this message translates to:
  /// **'Jarak'**
  String get detailFactDistance;

  /// No description provided for @detailVisitMinutes.
  ///
  /// In id, this message translates to:
  /// **'±{minutes} menit'**
  String detailVisitMinutes(int minutes);

  /// No description provided for @detailVisitHours.
  ///
  /// In id, this message translates to:
  /// **'±{hours} jam'**
  String detailVisitHours(String hours);

  /// No description provided for @detailAbout.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get detailAbout;

  /// No description provided for @detailReadMore.
  ///
  /// In id, this message translates to:
  /// **'Baca selengkapnya'**
  String get detailReadMore;

  /// No description provided for @detailReadLess.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan lebih sedikit'**
  String get detailReadLess;

  /// No description provided for @detailOpenMaps.
  ///
  /// In id, this message translates to:
  /// **'Buka Maps'**
  String get detailOpenMaps;

  /// No description provided for @detailReviews.
  ///
  /// In id, this message translates to:
  /// **'Ulasan'**
  String get detailReviews;

  /// No description provided for @detailSeeAllReviews.
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get detailSeeAllReviews;

  /// No description provided for @detailShowFewerReviews.
  ///
  /// In id, this message translates to:
  /// **'Lebih sedikit'**
  String get detailShowFewerReviews;

  /// No description provided for @detailReviewCount.
  ///
  /// In id, this message translates to:
  /// **'{count} ulasan'**
  String detailReviewCount(String count);

  /// No description provided for @detailNoReviews.
  ///
  /// In id, this message translates to:
  /// **'Belum ada ulasan untuk tempat ini.'**
  String get detailNoReviews;

  /// No description provided for @detailToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get detailToday;

  /// No description provided for @detailYesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get detailYesterday;

  /// No description provided for @detailDaysAgo.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lalu'**
  String detailDaysAgo(int days);

  /// No description provided for @detailAddToTrip.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke Trip'**
  String get detailAddToTrip;

  /// No description provided for @detailChooseTrip.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke trip mana?'**
  String get detailChooseTrip;

  /// No description provided for @detailTripMeta.
  ///
  /// In id, this message translates to:
  /// **'{days} hari · {date}'**
  String detailTripMeta(int days, String date);

  /// No description provided for @detailNoTrips.
  ///
  /// In id, this message translates to:
  /// **'Kamu belum punya trip. Buat dulu, lalu tempat ini bisa ditambahkan.'**
  String get detailNoTrips;

  /// No description provided for @detailNewTrip.
  ///
  /// In id, this message translates to:
  /// **'Buat trip baru'**
  String get detailNewTrip;

  /// No description provided for @detailAddedToTrip.
  ///
  /// In id, this message translates to:
  /// **'Ditambahkan ke wishlist {title}.'**
  String detailAddedToTrip(String title);

  /// No description provided for @detailAddedNeedsRegenerate.
  ///
  /// In id, this message translates to:
  /// **'Ditambahkan ke wishlist {title}. Buat ulang itinerary-nya supaya tempat ini ikut dihitung.'**
  String detailAddedNeedsRegenerate(String title);

  /// No description provided for @detailAlreadyInTrip.
  ///
  /// In id, this message translates to:
  /// **'Sudah ada di wishlist {title}.'**
  String detailAlreadyInTrip(String title);

  /// No description provided for @detailLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Detail tempat gagal dimuat.'**
  String get detailLoadFailed;

  /// No description provided for @detailPhotoCredit.
  ///
  /// In id, this message translates to:
  /// **'Foto: {credit}, {license}'**
  String detailPhotoCredit(String credit, String license);

  /// No description provided for @detailPhotoAnonymous.
  ///
  /// In id, this message translates to:
  /// **'Anonim'**
  String get detailPhotoAnonymous;
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
