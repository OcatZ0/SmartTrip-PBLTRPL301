// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get loginTitle => 'Selamat Datang Kembali';

  @override
  String get loginSubtitle =>
      'Akses rencana perjalanan bahari & wishlist wisatamu di Batam';

  @override
  String get loginEmailLabel => 'Alamat Email';

  @override
  String get loginEmailHint => 'nama@email.com';

  @override
  String get loginPasswordLabel => 'Kata Sandi';

  @override
  String get loginPasswordHint => 'Minimal 8 karakter';

  @override
  String get loginShowPassword => 'Tampilkan kata sandi';

  @override
  String get loginHidePassword => 'Sembunyikan kata sandi';

  @override
  String get loginRememberMe => 'Ingat Saya';

  @override
  String get loginForgotPassword => 'Lupa Kata Sandi?';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginOrSignInWith => 'atau';

  @override
  String get loginWithGoogle => 'Masuk dengan Google';

  @override
  String get loginBrowseWithoutLogin => 'Masuk tanpa Login';

  @override
  String get loginNoAccount => 'Belum punya akun?';

  @override
  String get loginRegisterNow => 'Daftar Sekarang';

  @override
  String get registerTitle => 'Buat Akun Baru';

  @override
  String get registerSubtitle =>
      'Mulai petualangan cerdas wisatamu di Batam\ndengan mudah & aman.';

  @override
  String get registerNameLabel => 'Nama Lengkap';

  @override
  String get registerNameHint => 'cth. Dian Pratama';

  @override
  String get registerEmailLabel => 'Alamat Email';

  @override
  String get registerEmailHint => 'dian@example.com';

  @override
  String get registerPasswordLabel => 'Kata Sandi';

  @override
  String get registerPasswordHint => 'Minimal 8 karakter';

  @override
  String get registerPasswordRequirement => 'Minimal 8 karakter';

  @override
  String get registerPasswordStrength => 'Kekuatan Sandi';

  @override
  String get registerPasswordWeak => 'Lemah';

  @override
  String get registerPasswordMedium => 'Sedang';

  @override
  String get registerPasswordStrong => 'Kuat';

  @override
  String get registerPasswordVeryStrong => 'Sangat Kuat';

  @override
  String get registerConfirmPasswordLabel => 'Konfirmasi Kata Sandi';

  @override
  String get registerConfirmPasswordHint => 'Masukkan ulang kata sandi';

  @override
  String get registerTermsPrefix => 'Saya menyetujui ';

  @override
  String get registerTerms => 'Syarat & Ketentuan';

  @override
  String get registerTermsAnd => ' serta ';

  @override
  String get registerPrivacy => 'Kebijakan Privasi';

  @override
  String get registerTermsSuffix => ' SmartTrip Batam.';

  @override
  String get registerSubmit => 'Daftar Akun';

  @override
  String get registerAlreadyHaveAccount => 'Sudah punya akun?';

  @override
  String get registerSignIn => 'Masuk';

  @override
  String get registerSuccessVerificationSent =>
      'Silakan cek email Anda untuk verifikasi akun.';

  @override
  String get validationNameRequired => 'Nama lengkap wajib diisi';

  @override
  String get validationEmailRequired => 'Email wajib diisi';

  @override
  String get validationEmailInvalid => 'Format email tidak valid';

  @override
  String get validationPasswordRequired => 'Kata sandi wajib diisi';

  @override
  String get validationPasswordMinLength => 'Kata sandi minimal 8 karakter';

  @override
  String get validationConfirmPasswordRequired =>
      'Konfirmasi kata sandi wajib diisi';

  @override
  String get validationConfirmPasswordMismatch =>
      'Konfirmasi kata sandi tidak cocok';

  @override
  String get validationTermsRequired =>
      'Anda harus menyetujui Syarat & Ketentuan';

  @override
  String get errorNetwork =>
      'Tidak dapat terhubung ke server. Periksa koneksi internetmu.';

  @override
  String get errorGeneric => 'Terjadi kesalahan. Coba lagi.';

  @override
  String get errorGoogleNotConfigured =>
      'Masuk dengan Google belum dikonfigurasi pada build ini.';

  @override
  String get comingSoon => 'Segera hadir';
}
