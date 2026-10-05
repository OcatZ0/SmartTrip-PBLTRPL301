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
  String get loginSubmit => 'Masuk ke Akun';

  @override
  String get loginOrSignInWith => 'atau masuk dengan';

  @override
  String get loginWithGoogle => 'Masuk dengan Google';

  @override
  String get loginBrowseWithoutLogin => 'Masuk tanpa Login';

  @override
  String get loginNoAccount => 'Belum punya akun?';

  @override
  String get loginRegisterNow => 'Daftar Sekarang';

  @override
  String get loginSecurityNote => 'Enkripsi 256-bit berstandar pariwisata aman';

  @override
  String get validationEmailRequired => 'Email wajib diisi';

  @override
  String get validationEmailInvalid => 'Format email tidak valid';

  @override
  String get validationPasswordRequired => 'Kata sandi wajib diisi';

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
