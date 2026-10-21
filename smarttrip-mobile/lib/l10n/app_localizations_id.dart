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
  String get loginSubtitle => 'Masuk untuk lanjut merencanakan tripmu.';

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
  String get loginRememberMe => 'Ingat saya';

  @override
  String get loginForgotPassword => 'Lupa kata sandi?';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginOrSignInWith => 'atau';

  @override
  String get loginWithGoogle => 'Lanjut dengan Google';

  @override
  String get loginBrowseWithoutLogin => 'Lewati';

  @override
  String get loginNoAccount => 'Belum punya akun?';

  @override
  String get loginRegisterNow => 'Daftar sekarang';

  @override
  String get registerTitle => 'Buat Akun Baru';

  @override
  String get registerSubtitle =>
      'Daftar untuk mulai merencanakan tripmu di Batam.';

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
  String get registerTermsSuffix => ' SmartTrip.';

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

  @override
  String get actionRetry => 'Coba Lagi';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get catalogCreateTrip => 'Buat Trip';

  @override
  String get navHome => 'Home';

  @override
  String get navWishlist => 'Wishlist';

  @override
  String get navTrips => 'Trip Saya';

  @override
  String get navProfile => 'Profil';

  @override
  String get catalogHeaderSubtitle => 'Beranda';

  @override
  String get catalogLogin => 'Masuk';

  @override
  String get catalogEyebrow => 'PANDUAN WISATA BATAM';

  @override
  String get catalogGreeting => 'Halo, mau ke mana hari ini?';

  @override
  String get catalogTagline => 'Temukan surga bahari & kuliner di Batam';

  @override
  String get catalogSearchHint => 'Cari pantai, jembatan barelang, seafood...';

  @override
  String get catalogClearSearch => 'Hapus pencarian';

  @override
  String get catalogFilterAll => 'Semua';

  @override
  String get catalogFilterLodging => 'Hotel';

  @override
  String get catalogKecamatanAll => 'Semua kecamatan';

  @override
  String get catalogKecamatanPick => 'Pilih kecamatan';

  @override
  String catalogKecamatanCount(int count) {
    return '$count tempat';
  }

  @override
  String get catalogKecamatanLoadFailed => 'Daftar kecamatan gagal dimuat.';

  @override
  String catalogSectionKecamatan(String kecamatan) {
    return 'Destinasi di $kecamatan';
  }

  @override
  String catalogSectionInKecamatan(String title, String kecamatan) {
    return '$title di $kecamatan';
  }

  @override
  String get catalogSectionAll => 'Destinasi di Batam';

  @override
  String get catalogSectionTopRated => 'Rating tertinggi';

  @override
  String catalogSectionSearch(String query) {
    return 'Hasil untuk \"$query\"';
  }

  @override
  String catalogFavoriteCount(int count) {
    return '$count Favorit';
  }

  @override
  String get catalogNoReviews => 'Belum ada ulasan';

  @override
  String get catalogPriceFreeLabel => 'Tiket Masuk';

  @override
  String get catalogPriceFree => 'Gratis';

  @override
  String get catalogPriceFromLabel => 'Mulai dari';

  @override
  String get catalogPriceUnknownLabel => 'Harga';

  @override
  String get catalogPriceUnknown => 'Belum ada info';

  @override
  String get catalogTypeAttraction => 'Wisata';

  @override
  String get catalogTypeCulinary => 'Kuliner';

  @override
  String get catalogTypeLodging => 'Hotel';

  @override
  String get catalogSaveToWishlist => 'Simpan ke wishlist';

  @override
  String get catalogRemoveFromWishlist => 'Hapus dari wishlist';

  @override
  String get catalogWishlistFailed => 'Wishlist gagal diperbarui. Coba lagi.';

  @override
  String get catalogEmpty => 'Belum ada tempat di katalog.';

  @override
  String get catalogNoResults =>
      'Tidak ada tempat yang cocok. Coba kata kunci atau kategori lain.';

  @override
  String tripStepLabel(int step, int total, String name) {
    return 'Langkah $step dari $total: $name';
  }

  @override
  String get tripNameLabel => 'Nama Trip';

  @override
  String get tripNameHint => 'Biar mudah dikenali di Trip Tersimpan';

  @override
  String tripNameDefault(String dates) {
    return 'Trip Batam $dates';
  }

  @override
  String tripHoursPerDay(int hours) {
    return '$hours jam per hari';
  }

  @override
  String get tripScheduleLabel => 'Tanggal & durasi';

  @override
  String get tripScheduleHint => 'Ketuk tanggal mulai, lalu tanggal selesai.';

  @override
  String get tripDailyHoursLabel => 'Jam jalan-jalan per hari';

  @override
  String get tripDailyHoursHint => 'Pilih rekomendasi atau atur sendiri.';

  @override
  String get tripShortDayWarning =>
      'Kurang dari 4 jam: tiap hari hanya muat sedikit tempat.';

  @override
  String get tripStartDateShort => 'Mulai';

  @override
  String get tripEndDateShort => 'Selesai';

  @override
  String tripBudgetPerDay(String amount) {
    return '≈ Rp$amount per hari';
  }

  @override
  String get tripSetupHeader => 'Atur Trip';

  @override
  String get tripSetupTitle => 'Rencanakan Trip-mu';

  @override
  String get tripSetupSubtitle =>
      'Beri tahu preferensimu, kami susunkan itinerary terbaik.';

  @override
  String get tripDurationDecrease => 'Kurangi durasi';

  @override
  String get tripDurationIncrease => 'Tambah durasi';

  @override
  String tripDays(int count) {
    return '$count Hari';
  }

  @override
  String tripNights(int count) {
    return '$count Malam';
  }

  @override
  String get tripDurationLongWarning =>
      'Lebih dari 7 hari boleh, tapi pilihan tempat di Batam bisa mulai terasa berulang.';

  @override
  String get tripBudgetLabel => 'Estimasi Anggaran per Orang';

  @override
  String get tripBudgetHint => 'Eksklusi tiket penerbangan utama';

  @override
  String get tripBudgetEconomy => 'Ekonomis';

  @override
  String get tripBudgetEconomyRange => '< 1 Jt';

  @override
  String get tripBudgetStandard => 'Standar';

  @override
  String get tripBudgetStandardRange => '1 - 2.5 Jt';

  @override
  String get tripBudgetPremium => 'Premium';

  @override
  String get tripBudgetPremiumRange => '> 2.5 Jt';

  @override
  String get validationBudgetRequired => 'Anggaran harus lebih dari 0';

  @override
  String get tripStartTimeLabel => 'Jam Mulai';

  @override
  String get tripEndTimeLabel => 'Jam Selesai';

  @override
  String get tripTimeZone => 'WIB';

  @override
  String get validationEndTimeAfterStart =>
      'Jam selesai harus setelah jam mulai';

  @override
  String get tripTipTitle => 'Tips SmartTrip:';

  @override
  String get tripTipBody =>
      ' Waktu terbaik tiba di Batam Centre adalah sebelum jam 10:00 WIB agar itinerary maksimal.';

  @override
  String get tripSetupNext => 'Lanjut ke wishlist';

  @override
  String get tripCancelTitle => 'Batalkan pembuatan trip?';

  @override
  String get tripCancelBody => 'Pengaturan yang belum disimpan akan hilang.';

  @override
  String get tripCancelStay => 'Lanjut Mengisi';

  @override
  String get tripCancelConfirm => 'Batalkan';

  @override
  String get tripWishlistSearchHint => 'Cari pantai, kuliner, museum...';

  @override
  String get tripWishlistNoResults => 'Tidak ada tempat yang cocok.';

  @override
  String get tripWishlistPin => 'Pin di peta';

  @override
  String tripWishlistRemove(String name) {
    return 'Hapus $name dari wishlist trip';
  }

  @override
  String get tripWishlistVisitLength => 'Lama kunjungan';

  @override
  String get tripWishlistVisitLengthHint => 'Berapa lama kamu di tempat ini?';

  @override
  String get tripWishlistSave => 'Simpan';

  @override
  String get tripWishlistSummaryPlaces => 'Tempat';

  @override
  String get tripWishlistSummaryVisit => 'Total kunjungan';

  @override
  String tripWishlistHours(String hours) {
    return '±$hours jam';
  }

  @override
  String get tripWishlistActionFailed =>
      'Wishlist trip gagal diperbarui, coba lagi.';

  @override
  String get tripWishlistPicked => 'Terpilih';

  @override
  String get tripWishlistPageTitle => 'Tambahkan Tempat Favoritmu';

  @override
  String get tripWishlistPageSubtitle =>
      'Ketuk tempat yang wajib dikunjungi dalam liburan ini (opsional).';

  @override
  String get tripWishlistPins => 'Pin sendiri';

  @override
  String get tripWishlistHeader => 'Susun Wishlist';

  @override
  String get tripWishlistNext => 'Lanjut ke Minat & Prioritas (3/4)';

  @override
  String get tripPreferencesHeader => 'Pilih Minat dan Prioritas';

  @override
  String get tripPreferencesStepName => 'Preferensi & Prioritas';

  @override
  String get tripPreferencesTitle => 'Sesuaikan Karakter Trip-mu';

  @override
  String get tripPreferencesSubtitle =>
      'Algoritma cerdas kami akan mengoptimalkan rute sesuai bobot preferensimu.';

  @override
  String get tripInterestTitle => 'Minat untuk Trip Ini';

  @override
  String get tripInterestHint => 'Kategori yang diprioritaskan dalam trip ini:';

  @override
  String get validationInterestRequired => 'Pilih minimal 1 kategori';

  @override
  String get tripPriorityTitle => 'Apa yang Paling Penting Buatmu?';

  @override
  String get tripPriorityHint =>
      'Geser slider untuk mengatur prioritas komputasi rute.';

  @override
  String get tripPriorityInterest => 'Kesesuaian Minat Wisata';

  @override
  String get tripPriorityInterestMin => 'Eksplorasi Acak';

  @override
  String get tripPriorityInterestMax => 'Fokus Minat 100%';

  @override
  String get tripPriorityDistance => 'Jarak / Waktu Perjalanan';

  @override
  String get tripPriorityDistanceMin => 'Bebas Keliling';

  @override
  String get tripPriorityDistanceMax => 'Paling Cepat';

  @override
  String get tripPriorityBudget => 'Kepatuhan Anggaran';

  @override
  String get tripPriorityBudgetMin => 'Fleksibel Pengeluaran';

  @override
  String get tripPriorityBudgetMax => 'Ketat di Bawah Plafon';

  @override
  String get tripPriorityRating => 'Rating & Ulasan Terbaik';

  @override
  String get tripPriorityRatingMin => 'Spot Hidden Gem';

  @override
  String get tripPriorityRatingMax => 'Top Verified Only';

  @override
  String tripPriorityValue(int value, String level) {
    return '$value/10 ($level)';
  }

  @override
  String get tripPriorityLevelLow => 'Rendah';

  @override
  String get tripPriorityLevelMedium => 'Sedang';

  @override
  String get tripPriorityLevelHigh => 'Prioritas';

  @override
  String get tripPriorityLevelVeryHigh => 'Sangat Prioritas';

  @override
  String get tripSaveDefaultTitle =>
      'Simpan sebagai preferensi default profil saya';

  @override
  String get tripSaveDefaultHint =>
      'Diterapkan otomatis untuk perencanaan rute berikutnya';

  @override
  String get tripPreferencesNext => 'Lanjut ke Pilih Hotel (4/4)';

  @override
  String get tripHotelHeader => 'Pilih Hotel';

  @override
  String get tripHotelBadge => 'Penentu Titik Berangkat & Pulang';

  @override
  String get tripHotelTitle => 'Pilih Titik Menginap / Hotel';

  @override
  String get tripHotelSubtitle =>
      'Titik hotel menjadi acuan titik awal keberangkatan dan kepulangan harianmu agar rute keliling Batam seimbang.';

  @override
  String get tripHotelSearchHint => 'Cari nama hotel atau resort di Batam...';

  @override
  String get tripHotelTabRecommended => 'Rekomendasi Cerdas';

  @override
  String get tripHotelTabSearch => 'Cari Semua Hotel';

  @override
  String tripHotelRecommendedTitle(int count) {
    return '$count Hotel Rekomendasi';
  }

  @override
  String get tripHotelRecommendedBadge => 'AI Matched';

  @override
  String get tripHotelRecommendedHint =>
      'Disesuaikan dengan minat dan anggaran trip-mu';

  @override
  String tripHotelRank(int rank) {
    return 'Rekomendasi #$rank';
  }

  @override
  String get tripHotelSelect => 'Pilih Hotel Ini';

  @override
  String get tripHotelSelected => 'Hotel Dipilih';

  @override
  String get tripHotelNoRecommendation =>
      'Belum ada rekomendasi hotel. Cari hotel atau tambah manual.';

  @override
  String get tripHotelNoResult => 'Hotel tidak ditemukan.';

  @override
  String get tripHotelManual =>
      'Tidak menemukan hotelmu? Tambah hotel manual di peta';

  @override
  String get tripHotelInfoTitle => 'Optimalisasi Navigasi Harian';

  @override
  String get tripHotelInfoBody =>
      'Hotel yang kamu pilih menjadi titik awal dan akhir rute setiap hari.';

  @override
  String get tripHotelSelectedLabel => 'Titik Terpilih:';

  @override
  String get tripHotelNoneSelected => 'Belum dipilih';

  @override
  String get tripGenerateButton => 'Buat Itinerary Cerdas Sekarang';

  @override
  String get tripGenerateHint =>
      'SmartTrip akan menghitung rute, jam buka, dan durasi kunjungan.';

  @override
  String get mapPickerTitle => 'Pilih Lokasi di Peta';

  @override
  String get mapPickerHint => 'Ketuk peta untuk menaruh titik lokasi';

  @override
  String get mapPickerPinRequired =>
      'Ketuk peta untuk memilih lokasi terlebih dahulu';

  @override
  String get mapPickerNameLabel => 'Nama Tempat';

  @override
  String get mapPickerNameHint => 'cth. Hotel Harmoni';

  @override
  String get validationPlaceNameRequired => 'Nama tempat wajib diisi';

  @override
  String get generateTitle => 'Menyusun Perjalanan Terbaikmu';

  @override
  String get generateFailedTitle => 'Itinerary gagal dibuat';

  @override
  String get generateStepCandidates =>
      'Mengumpulkan tempat wishlist & rekomendasi';

  @override
  String get generateStepCandidatesHint => 'Mencocokkan minat dan anggaranmu';

  @override
  String get generateStepRoute => 'Menghitung estimasi rute antar tempat';

  @override
  String get generateStepRouteHint => 'Mengurutkan kunjungan dari hotel';

  @override
  String get generateStepSchedule => 'Menyesuaikan jadwal dengan jam buka';

  @override
  String get generateStepScheduleHint =>
      'Memastikan tiap hari muat di jam jalan-jalanmu';

  @override
  String get generateStage => 'TAHAP AKHIR KURASI';

  @override
  String get itineraryHeader => 'Trip Saya';

  @override
  String itineraryDayTab(int day, String date) {
    return 'Hari $day ($date)';
  }

  @override
  String get itineraryRecommended => 'Rekomendasi';

  @override
  String get itineraryFromWishlist => 'Dari Wishlist';

  @override
  String itineraryVisitMinutes(int minutes) {
    return '$minutes menit';
  }

  @override
  String itineraryDistance(String km) {
    return '± $km km dari tempat sebelumnya';
  }

  @override
  String get itineraryVisited => 'Sudah dikunjungi';

  @override
  String get itineraryOpenMap => 'Buka Rute Peta Live';

  @override
  String get itineraryEmpty => 'Itinerary belum dibuat untuk trip ini.';

  @override
  String get itineraryGenerateNow => 'Buat Itinerary';

  @override
  String get itineraryDayEmpty => 'Tidak ada tempat yang muat di hari ini.';

  @override
  String get itineraryOverpacked =>
      'Jadwal hari ini cukup padat, pertimbangkan mengganti satu tempat.';

  @override
  String get itineraryShortOfPlaces =>
      'Tempat yang cocok kurang untuk mengisi hari ini.';

  @override
  String itineraryDroppedWishlist(int count) {
    return '$count tempat wishlist tidak muat dan dilewati.';
  }

  @override
  String itineraryClosedWishlist(int count) {
    return '$count tempat wishlist tutup di semua hari trip dan dilewati.';
  }

  @override
  String itineraryStartFrom(String name) {
    return 'Berangkat dari $name';
  }

  @override
  String get itineraryUnknownPlace => 'Tempat tidak tersedia';

  @override
  String get liveMapTitle => 'Pelacakan Trip';

  @override
  String liveMapSubtitle(int day) {
    return 'SmartTrip • Hari $day';
  }

  @override
  String get liveMapStartDay => 'Mulai Hari Ini';

  @override
  String get liveMapStopTracking => 'Hentikan Pelacakan';

  @override
  String get liveMapTrackingActive => 'Tracking aktif';

  @override
  String get liveMapTrackingOff => 'Tracking belum aktif';

  @override
  String get liveMapCenter => 'Pusatkan lokasi';

  @override
  String get liveMapArrived => 'Kamu sudah tiba di lokasi tujuan!';

  @override
  String get liveMapAutoCheckIn => 'Auto Check-in ✓';

  @override
  String get liveMapMarkVisited => 'Selesai Dikunjungi';

  @override
  String get liveMapUnmarkVisited => 'Batalkan Tanda';

  @override
  String get liveMapNavigate => 'Buka Navigasi';

  @override
  String get liveMapStopsTitle => 'Rangkaian Kunjungan Hari Ini';

  @override
  String liveMapStopsCount(int count) {
    return '$count Destinasi';
  }

  @override
  String get liveMapStopVisited => 'Selesai';

  @override
  String get liveMapStopNext => 'Tujuan berikutnya';

  @override
  String get liveMapStopPending => 'Belum dikunjungi';

  @override
  String get liveMapNextBadge => 'Berikutnya';

  @override
  String liveMapAllocation(int minutes) {
    return 'Alokasi $minutes mnt';
  }

  @override
  String get liveMapHotel => 'Hotel';

  @override
  String get liveMapLongPressHint =>
      'Tekan lama penanda atau daftar tempat untuk menandai/membatalkan kunjungan.';

  @override
  String get liveMapPermissionDenied =>
      'Izin lokasi ditolak. Kamu tetap bisa menandai kunjungan secara manual.';

  @override
  String get liveMapLocationServiceOff =>
      'Layanan lokasi (GPS) mati. Nyalakan untuk pelacakan otomatis.';

  @override
  String get liveMapVisitQueued =>
      'Tidak ada koneksi. Tanda kunjungan disimpan dan dikirim otomatis nanti.';

  @override
  String get notificationChannelName => 'Kedatangan di Tempat Wisata';

  @override
  String get notificationChannelDescription =>
      'Pemberitahuan saat kamu tiba di tempat dalam itinerary hari ini.';

  @override
  String notificationArrivedTitle(String name) {
    return 'Kamu sudah tiba di $name';
  }

  @override
  String get notificationArrivedBody =>
      'Kunjunganmu otomatis ditandai. Selamat menikmati!';

  @override
  String get detailTitle => 'Detail Destinasi';

  @override
  String get detailFactTicket => 'Tiket masuk';

  @override
  String get detailFactVisit => 'Lama kunjungan';

  @override
  String get detailFactHours => 'Jam buka';

  @override
  String get detailFactDistance => 'Jarak';

  @override
  String detailVisitMinutes(int minutes) {
    return '±$minutes menit';
  }

  @override
  String detailVisitHours(String hours) {
    return '±$hours jam';
  }

  @override
  String get detailAbout => 'Tentang';

  @override
  String get detailReadMore => 'Baca selengkapnya';

  @override
  String get detailReadLess => 'Tampilkan lebih sedikit';

  @override
  String get detailOpenMaps => 'Buka Maps';

  @override
  String get detailReviews => 'Ulasan';

  @override
  String get detailSeeAllReviews => 'Lihat semua';

  @override
  String get detailShowFewerReviews => 'Lebih sedikit';

  @override
  String detailReviewCount(String count) {
    return '$count ulasan';
  }

  @override
  String get detailNoReviews => 'Belum ada ulasan untuk tempat ini.';

  @override
  String get detailToday => 'Hari ini';

  @override
  String get detailYesterday => 'Kemarin';

  @override
  String detailDaysAgo(int days) {
    return '$days hari lalu';
  }

  @override
  String get detailAddToTrip => 'Tambah ke Trip';

  @override
  String get detailChooseTrip => 'Tambah ke trip mana?';

  @override
  String detailTripMeta(int days, String date) {
    return '$days hari · $date';
  }

  @override
  String get detailNoTrips =>
      'Kamu belum punya trip. Buat dulu, lalu tempat ini bisa ditambahkan.';

  @override
  String get detailNewTrip => 'Buat trip baru';

  @override
  String detailAddedToTrip(String title) {
    return 'Ditambahkan ke wishlist $title.';
  }

  @override
  String detailAddedNeedsRegenerate(String title) {
    return 'Ditambahkan ke wishlist $title. Buat ulang itinerary-nya supaya tempat ini ikut dihitung.';
  }

  @override
  String detailAlreadyInTrip(String title) {
    return 'Sudah ada di wishlist $title.';
  }

  @override
  String get detailLoadFailed => 'Detail tempat gagal dimuat.';

  @override
  String get detailFactHoursToday => 'Jam buka hari ini';

  @override
  String get detailHoursUnknown => 'Belum ada info';

  @override
  String get detailHoursClosedToday => 'Tutup hari ini';

  @override
  String get detailHoursClosed => 'Tutup';

  @override
  String get detailHoursAllDay => 'Buka 24 jam';

  @override
  String get detailOpenNow => 'Sedang buka';

  @override
  String get detailClosedNow => 'Sedang tutup';

  @override
  String get detailOpeningHours => 'Jam Operasional';

  @override
  String get detailEveryDay => 'Setiap hari';

  @override
  String get detailFactArea => 'Area';

  @override
  String get detailAreaOutdoor => 'Luar ruangan';

  @override
  String get detailAreaIndoor => 'Dalam ruangan';

  @override
  String get profileInterests => 'Minat kamu';

  @override
  String get profileInterestsHint => 'Dipilih otomatis setiap buat trip baru.';

  @override
  String get profilePriorities => 'Prioritas rute';

  @override
  String get profileWeightInterest => 'Sesuai minat';

  @override
  String get profileWeightInterestHint =>
      'Utamakan tempat dengan kategori pilihanmu';

  @override
  String get profileWeightDistance => 'Jarak & waktu tempuh';

  @override
  String get profileWeightDistanceHint => 'Utamakan tempat yang berdekatan';

  @override
  String get profileWeightBudget => 'Hemat biaya';

  @override
  String get profileWeightBudgetHint => 'Utamakan tempat murah atau gratis';

  @override
  String get profileWeightRating => 'Rating tempat';

  @override
  String get profileWeightRatingHint => 'Utamakan tempat dengan ulasan bagus';

  @override
  String get profileNeedInterest => 'Pilih minimal satu minat.';

  @override
  String get profileLoadFailed => 'Preferensi gagal dimuat.';

  @override
  String get profileChangePassword => 'Ganti kata sandi';

  @override
  String get profileLanguage => 'Bahasa';

  @override
  String get profileLanguageName => 'Indonesia';

  @override
  String get profileLogout => 'Keluar';

  @override
  String get profileLogoutTitle => 'Keluar dari akun?';

  @override
  String get profileLogoutBody =>
      'Kamu perlu masuk lagi untuk membuka trip-mu.';

  @override
  String get profilePasswordCurrent => 'Kata sandi saat ini';

  @override
  String get profilePasswordNew => 'Kata sandi baru';

  @override
  String get profilePasswordConfirm => 'Ulangi kata sandi baru';

  @override
  String get profilePasswordSubmit => 'Simpan kata sandi';

  @override
  String get profileEyebrow => 'PROFIL';

  @override
  String get profileHeadline => 'Atur trip sesuai gayamu';

  @override
  String get profilePasswordGoogleOnly =>
      'Akunmu dibuat lewat Google, jadi belum punya kata sandi. Buat kata sandi di sini supaya bisa masuk juga dengan email.';

  @override
  String get swapTitle => 'Ganti Tempat';

  @override
  String swapSubtitle(String name) {
    return 'Pilih pengganti untuk $name.';
  }

  @override
  String swapRainSubtitle(String name) {
    return 'Hari ini diprediksi hujan. Tempat dalam ruangan untuk mengganti $name ada di atas.';
  }

  @override
  String get swapTabRecommended => 'Rekomendasi';

  @override
  String get swapTabSearch => 'Cari Manual';

  @override
  String get swapSearchHint => 'Cari nama tempat';

  @override
  String get swapEmpty => 'Belum ada tempat pengganti yang cocok.';

  @override
  String get swapIndoor => 'Dalam ruangan';

  @override
  String get swapOutdoor => 'Luar ruangan';

  @override
  String swapDone(String name) {
    return 'Diganti dengan $name.';
  }

  @override
  String get weatherClear => 'Cerah';

  @override
  String get weatherCloudy => 'Berawan';

  @override
  String get weatherFog => 'Berkabut';

  @override
  String get weatherRain => 'Hujan';

  @override
  String get weatherThunderstorm => 'Hujan petir';

  @override
  String weatherSummary(int min, int max, int chance) {
    return '$min-$max°C · peluang hujan $chance%';
  }

  @override
  String weatherRainWarning(int count) {
    return 'Diprediksi hujan, ada $count tempat luar ruangan hari ini. Pertimbangkan menggantinya dengan tempat dalam ruangan.';
  }

  @override
  String get weatherSwapAction => 'Ganti tempat luar ruangan';

  @override
  String get weatherRainBadge => 'Hujan, ganti?';

  @override
  String weatherReminderTitle(String title) {
    return 'Cek cuaca untuk $title';
  }

  @override
  String get weatherReminderBody =>
      'Trip kamu tinggal 7 hari lagi. Prakiraan cuaca sudah bisa dilihat di itinerary.';

  @override
  String get weatherReminderChannel => 'Pengingat cuaca';

  @override
  String get weatherReminderChannelDescription =>
      'Pengingat cek prakiraan cuaca menjelang trip';

  @override
  String dayReminderTitle(String title, int day) {
    return '$title: hari ke-$day';
  }

  @override
  String dayReminderBody(int count, String first, String time) {
    return '$count tempat menunggu hari ini, mulai dari $first pukul $time.';
  }

  @override
  String get dayReminderChannel => 'Pengingat hari trip';

  @override
  String get dayReminderChannelDescription =>
      'Pengingat di awal setiap hari trip';

  @override
  String get tripPaceRelaxed => 'Santai';

  @override
  String get tripPaceStandard => 'Standar';

  @override
  String get tripPacePacked => 'Padat';

  @override
  String get tripSummaryBudget => 'Anggaran';

  @override
  String get tripSummaryDuration => 'Durasi';

  @override
  String get tripSummaryHours => 'Jam harian';
}
