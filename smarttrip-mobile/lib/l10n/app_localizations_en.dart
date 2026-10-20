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
  String get loginSubtitle => 'Sign in to keep planning your trip.';

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
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSubmit => 'Sign In';

  @override
  String get loginOrSignInWith => 'or ';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginBrowseWithoutLogin => 'Skip';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegisterNow => 'Register now';

  @override
  String get registerTitle => 'Create New Account';

  @override
  String get registerSubtitle => 'Register to start planning your Batam trip.';

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
  String get registerTermsSuffix => ' of SmartTrip.';

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

  @override
  String get actionRetry => 'Try Again';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get catalogCreateTrip => 'Create Trip';

  @override
  String get navHome => 'Home';

  @override
  String get navWishlist => 'Wishlist';

  @override
  String get navTrips => 'My Trips';

  @override
  String get navProfile => 'Profile';

  @override
  String get catalogHeaderSubtitle => 'Home';

  @override
  String get catalogLogin => 'Log in';

  @override
  String get catalogEyebrow => 'BATAM TRAVEL GUIDE';

  @override
  String get catalogGreeting => 'Hi, where to today?';

  @override
  String get catalogTagline => 'Discover Batam\'s seaside spots and food';

  @override
  String get catalogSearchHint => 'Search beaches, Barelang bridge, seafood...';

  @override
  String get catalogClearSearch => 'Clear search';

  @override
  String get catalogFilterAll => 'All';

  @override
  String get catalogFilterLodging => 'Hotels';

  @override
  String get catalogKecamatanAll => 'All districts';

  @override
  String get catalogKecamatanPick => 'Choose a district';

  @override
  String catalogKecamatanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get catalogKecamatanLoadFailed => 'Couldn\'t load the districts.';

  @override
  String catalogSectionKecamatan(String kecamatan) {
    return 'Places in $kecamatan';
  }

  @override
  String catalogSectionInKecamatan(String title, String kecamatan) {
    return '$title in $kecamatan';
  }

  @override
  String get catalogSectionAll => 'Places in Batam';

  @override
  String get catalogSectionTopRated => 'Top rated';

  @override
  String catalogSectionSearch(String query) {
    return 'Results for \"$query\"';
  }

  @override
  String catalogFavoriteCount(int count) {
    return '$count Saved';
  }

  @override
  String get catalogNoReviews => 'No reviews yet';

  @override
  String get catalogPriceFreeLabel => 'Entry';

  @override
  String get catalogPriceFree => 'Free';

  @override
  String get catalogPriceFromLabel => 'From';

  @override
  String get catalogPriceUnknownLabel => 'Price';

  @override
  String get catalogPriceUnknown => 'Not available yet';

  @override
  String get catalogTypeAttraction => 'Attraction';

  @override
  String get catalogTypeCulinary => 'Food';

  @override
  String get catalogTypeLodging => 'Hotel';

  @override
  String get catalogSaveToWishlist => 'Save to wishlist';

  @override
  String get catalogRemoveFromWishlist => 'Remove from wishlist';

  @override
  String get catalogWishlistFailed =>
      'Couldn\'t update your wishlist. Try again.';

  @override
  String get catalogEmpty => 'The catalog has no places yet.';

  @override
  String get catalogNoResults =>
      'No places match. Try another keyword or category.';

  @override
  String tripStepLabel(int step, int total, String name) {
    return 'Step $step of $total: $name';
  }

  @override
  String get tripNameLabel => 'Trip Name';

  @override
  String get tripNameHint => 'So you can find it in Saved Trips';

  @override
  String tripNameDefault(String dates) {
    return 'Batam trip $dates';
  }

  @override
  String tripHoursPerDay(int hours) {
    return '$hours hours a day';
  }

  @override
  String get tripScheduleLabel => 'Dates & Duration';

  @override
  String get tripScheduleHint =>
      'Tap the dates to pick a range on the calendar';

  @override
  String get tripDailyHoursLabel => 'Daily Sightseeing Hours';

  @override
  String get tripDailyHoursHint =>
      'Each day of the itinerary fits within these hours';

  @override
  String get tripShortDayWarning =>
      'Under 4 hours: each day only fits a few places.';

  @override
  String get tripStartDateShort => 'Start';

  @override
  String get tripEndDateShort => 'End';

  @override
  String tripBudgetPerDay(String amount) {
    return '≈ Rp$amount a day';
  }

  @override
  String get tripSetupHeader => 'Trip Setup';

  @override
  String get tripSetupTitle => 'Plan Your Trip';

  @override
  String get tripSetupSubtitle =>
      'Tell us your preferences and we will build the best itinerary.';

  @override
  String get tripDurationLabel => 'Trip Duration';

  @override
  String get tripDurationHint => 'How long is your Batam holiday?';

  @override
  String get tripDurationDecrease => 'Decrease duration';

  @override
  String get tripDurationIncrease => 'Increase duration';

  @override
  String tripDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String tripNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nights',
      one: '1 Night',
    );
    return '$_temp0';
  }

  @override
  String get tripDurationLongWarning =>
      'More than 7 days is allowed, but places in Batam may start to repeat.';

  @override
  String get tripBudgetLabel => 'Estimated Budget per Person';

  @override
  String get tripBudgetHint => 'Excluding main flight tickets';

  @override
  String get tripBudgetEconomy => 'Economy';

  @override
  String get tripBudgetEconomyRange => '< 1M';

  @override
  String get tripBudgetStandard => 'Standard';

  @override
  String get tripBudgetStandardRange => '1 - 2.5M';

  @override
  String get tripBudgetPremium => 'Premium';

  @override
  String get tripBudgetPremiumRange => '> 2.5M';

  @override
  String get validationBudgetRequired => 'Budget must be more than 0';

  @override
  String get tripDateLabel => 'Start & End Date';

  @override
  String get tripDateHint => 'Your time on the island';

  @override
  String get tripStartTimeLabel => 'Start Time';

  @override
  String get tripEndTimeLabel => 'End Time';

  @override
  String get tripTimeZone => 'WIB';

  @override
  String get validationEndTimeAfterStart => 'End time must be after start time';

  @override
  String get tripTipTitle => 'SmartTrip tip:';

  @override
  String get tripTipBody =>
      ' Arriving in Batam Centre before 10:00 WIB gets the most out of your itinerary.';

  @override
  String get tripSetupNext => 'Continue to Wishlist (2/4)';

  @override
  String get tripCancelTitle => 'Cancel trip setup?';

  @override
  String get tripCancelBody => 'Unsaved settings will be lost.';

  @override
  String get tripCancelStay => 'Keep Editing';

  @override
  String get tripCancelConfirm => 'Cancel Setup';

  @override
  String get tripWishlistHeader => 'Build Wishlist';

  @override
  String get tripWishlistComingSoon =>
      'The wishlist is still being prepared. You can continue and the system will pick the best places for you.';

  @override
  String get tripWishlistNext => 'Continue to Interests & Priorities (3/4)';

  @override
  String get tripPreferencesHeader => 'Interests and Priorities';

  @override
  String get tripPreferencesStepName => 'Preferences & Priorities';

  @override
  String get tripPreferencesTitle => 'Shape Your Trip';

  @override
  String get tripPreferencesSubtitle =>
      'Our algorithm optimizes the route by how much each preference matters to you.';

  @override
  String get tripInterestTitle => 'Interests for This Trip';

  @override
  String get tripInterestHint => 'Categories to prioritize on this trip:';

  @override
  String get validationInterestRequired => 'Choose at least 1 category';

  @override
  String get tripPriorityTitle => 'What Matters Most to You?';

  @override
  String get tripPriorityHint =>
      'Move the sliders to set the route priorities.';

  @override
  String get tripPriorityInterest => 'Interest Match';

  @override
  String get tripPriorityInterestMin => 'Random Exploring';

  @override
  String get tripPriorityInterestMax => '100% Interest Focus';

  @override
  String get tripPriorityDistance => 'Distance / Travel Time';

  @override
  String get tripPriorityDistanceMin => 'Roam Freely';

  @override
  String get tripPriorityDistanceMax => 'Fastest';

  @override
  String get tripPriorityBudget => 'Budget Fit';

  @override
  String get tripPriorityBudgetMin => 'Flexible Spending';

  @override
  String get tripPriorityBudgetMax => 'Strictly Under Budget';

  @override
  String get tripPriorityRating => 'Best Ratings & Reviews';

  @override
  String get tripPriorityRatingMin => 'Hidden Gems';

  @override
  String get tripPriorityRatingMax => 'Top Rated Only';

  @override
  String tripPriorityValue(int value, String level) {
    return '$value/10 ($level)';
  }

  @override
  String get tripPriorityLevelLow => 'Low';

  @override
  String get tripPriorityLevelMedium => 'Medium';

  @override
  String get tripPriorityLevelHigh => 'High';

  @override
  String get tripPriorityLevelVeryHigh => 'Top Priority';

  @override
  String get tripSaveDefaultTitle => 'Save as my profile defaults';

  @override
  String get tripSaveDefaultHint => 'Applied automatically to your next trips';

  @override
  String get tripPreferencesNext => 'Continue to Hotel (4/4)';

  @override
  String get tripHotelHeader => 'Choose Hotel';

  @override
  String get tripHotelBadge => 'Daily Start & End Point';

  @override
  String get tripHotelTitle => 'Choose Where You Stay';

  @override
  String get tripHotelSubtitle =>
      'Your hotel is where every day starts and ends, so the route around Batam stays balanced.';

  @override
  String get tripHotelSearchHint => 'Search hotels or resorts in Batam...';

  @override
  String get tripHotelTabRecommended => 'Smart Picks';

  @override
  String get tripHotelTabSearch => 'Search All Hotels';

  @override
  String tripHotelRecommendedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Recommended Hotels',
      one: '1 Recommended Hotel',
    );
    return '$_temp0';
  }

  @override
  String get tripHotelRecommendedBadge => 'AI Matched';

  @override
  String get tripHotelRecommendedHint => 'Matched to your interests and budget';

  @override
  String tripHotelRank(int rank) {
    return 'Pick #$rank';
  }

  @override
  String get tripHotelSelect => 'Choose Hotel';

  @override
  String get tripHotelSelected => 'Selected';

  @override
  String get tripHotelNoRecommendation =>
      'No hotel recommendations yet. Search for a hotel or add one manually.';

  @override
  String get tripHotelNoResult => 'No hotels found.';

  @override
  String get tripHotelManual => 'Can\'t find your hotel? Add it on the map';

  @override
  String get tripHotelInfoTitle => 'Daily Route Optimization';

  @override
  String get tripHotelInfoBody =>
      'Your chosen hotel is the start and end of every day\'s route.';

  @override
  String get tripHotelSelectedLabel => 'Selected:';

  @override
  String get tripHotelNoneSelected => 'Not chosen yet';

  @override
  String get tripGenerateButton => 'Build My Smart Itinerary';

  @override
  String get tripGenerateHint =>
      'SmartTrip will work out routes, opening hours and visit times.';

  @override
  String get mapPickerTitle => 'Pick a Location';

  @override
  String get mapPickerHint => 'Tap the map to drop a pin';

  @override
  String get mapPickerPinRequired => 'Tap the map to choose a location first';

  @override
  String get mapPickerNameLabel => 'Place Name';

  @override
  String get mapPickerNameHint => 'e.g. Harmoni Hotel';

  @override
  String get validationPlaceNameRequired => 'Place name is required';

  @override
  String get generateTitle => 'Building Your Best Trip';

  @override
  String get generateFailedTitle => 'Could not build the itinerary';

  @override
  String get generateStepCandidates =>
      'Gathering wishlist and recommended places';

  @override
  String get generateStepCandidatesHint => 'Matching your interests and budget';

  @override
  String get generateStepRoute => 'Estimating routes between places';

  @override
  String get generateStepRouteHint => 'Ordering stops from your hotel';

  @override
  String get generateStepSchedule => 'Fitting the schedule to opening hours';

  @override
  String get generateStepScheduleHint => 'Making each day fit your daily hours';

  @override
  String get generateStage => 'FINAL CURATION';

  @override
  String get itineraryHeader => 'My Trips';

  @override
  String itineraryDayTab(int day, String date) {
    return 'Day $day ($date)';
  }

  @override
  String get itineraryRecommended => 'Recommended';

  @override
  String get itineraryFromWishlist => 'From Wishlist';

  @override
  String itineraryVisitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String itineraryDistance(String km) {
    return '± $km km from the previous stop';
  }

  @override
  String get itineraryVisited => 'Visited';

  @override
  String get itineraryOpenMap => 'Open Live Route Map';

  @override
  String get itineraryEmpty => 'This trip has no itinerary yet.';

  @override
  String get itineraryGenerateNow => 'Build Itinerary';

  @override
  String get itineraryDayEmpty => 'No places fit on this day.';

  @override
  String get itineraryOverpacked =>
      'This day is packed, consider swapping a place.';

  @override
  String get itineraryShortOfPlaces =>
      'There were not enough matching places to fill this day.';

  @override
  String itineraryDroppedWishlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wishlist places did not fit and were skipped.',
      one: '1 wishlist place did not fit and was skipped.',
    );
    return '$_temp0';
  }

  @override
  String itineraryClosedWishlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count wishlist places are closed on every trip day and were skipped.',
      one: '1 wishlist place is closed on every trip day and was skipped.',
    );
    return '$_temp0';
  }

  @override
  String itineraryStartFrom(String name) {
    return 'Starting from $name';
  }

  @override
  String get itineraryUnknownPlace => 'Place unavailable';

  @override
  String get liveMapTitle => 'Trip Tracking';

  @override
  String liveMapSubtitle(int day) {
    return 'SmartTrip • Day $day';
  }

  @override
  String get liveMapStartDay => 'Start Today';

  @override
  String get liveMapStopTracking => 'Stop Tracking';

  @override
  String get liveMapTrackingActive => 'Tracking on';

  @override
  String get liveMapTrackingOff => 'Tracking off';

  @override
  String get liveMapCenter => 'Center on me';

  @override
  String get liveMapArrived => 'You have arrived!';

  @override
  String get liveMapAutoCheckIn => 'Auto check-in ✓';

  @override
  String get liveMapMarkVisited => 'Mark Visited';

  @override
  String get liveMapUnmarkVisited => 'Unmark';

  @override
  String get liveMapNavigate => 'Navigate';

  @override
  String get liveMapStopsTitle => 'Today\'s Stops';

  @override
  String liveMapStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stops',
      one: '1 Stop',
    );
    return '$_temp0';
  }

  @override
  String get liveMapStopVisited => 'Visited';

  @override
  String get liveMapStopNext => 'Next stop';

  @override
  String get liveMapStopPending => 'Not visited yet';

  @override
  String get liveMapNextBadge => 'Next';

  @override
  String liveMapAllocation(int minutes) {
    return '$minutes min planned';
  }

  @override
  String get liveMapHotel => 'Hotel';

  @override
  String get liveMapLongPressHint =>
      'Long-press a pin or a stop in the list to mark or unmark it.';

  @override
  String get liveMapPermissionDenied =>
      'Location permission denied. You can still mark visits by hand.';

  @override
  String get liveMapLocationServiceOff =>
      'Location services (GPS) are off. Turn them on for automatic tracking.';

  @override
  String get liveMapVisitQueued =>
      'No connection. The visit is saved and will be sent automatically.';

  @override
  String get notificationChannelName => 'Arrival at a Stop';

  @override
  String get notificationChannelDescription =>
      'Alerts when you reach a stop on today\'s itinerary.';

  @override
  String notificationArrivedTitle(String name) {
    return 'You have reached $name';
  }

  @override
  String get notificationArrivedBody =>
      'Your visit was marked automatically. Enjoy!';

  @override
  String get detailTitle => 'Place Details';

  @override
  String get detailFactTicket => 'Entry ticket';

  @override
  String get detailFactVisit => 'Visit length';

  @override
  String get detailFactHours => 'Opening hours';

  @override
  String get detailFactDistance => 'Distance';

  @override
  String detailVisitMinutes(int minutes) {
    return '±$minutes min';
  }

  @override
  String detailVisitHours(String hours) {
    return '±$hours h';
  }

  @override
  String get detailAbout => 'About';

  @override
  String get detailReadMore => 'Read more';

  @override
  String get detailReadLess => 'Show less';

  @override
  String get detailOpenMaps => 'Open Maps';

  @override
  String get detailReviews => 'Reviews';

  @override
  String get detailSeeAllReviews => 'See all';

  @override
  String get detailShowFewerReviews => 'Show fewer';

  @override
  String detailReviewCount(String count) {
    return '$count reviews';
  }

  @override
  String get detailNoReviews => 'No reviews for this place yet.';

  @override
  String get detailToday => 'Today';

  @override
  String get detailYesterday => 'Yesterday';

  @override
  String detailDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get detailAddToTrip => 'Add to Trip';

  @override
  String get detailChooseTrip => 'Add to which trip?';

  @override
  String detailTripMeta(int days, String date) {
    return '$days days · $date';
  }

  @override
  String get detailNoTrips =>
      'You don\'t have a trip yet. Create one first, then add this place.';

  @override
  String get detailNewTrip => 'Create a new trip';

  @override
  String detailAddedToTrip(String title) {
    return 'Added to $title\'s wishlist.';
  }

  @override
  String detailAddedNeedsRegenerate(String title) {
    return 'Added to $title\'s wishlist. Generate its itinerary again to include this place.';
  }

  @override
  String detailAlreadyInTrip(String title) {
    return 'Already in $title\'s wishlist.';
  }

  @override
  String get detailLoadFailed => 'Couldn\'t load this place.';

  @override
  String get detailFactHoursToday => 'Open today';

  @override
  String get detailHoursUnknown => 'Not available yet';

  @override
  String get detailHoursClosedToday => 'Closed today';

  @override
  String get detailHoursClosed => 'Closed';

  @override
  String get detailHoursAllDay => 'Open 24 hours';

  @override
  String get detailOpenNow => 'Open now';

  @override
  String get detailClosedNow => 'Closed now';

  @override
  String get detailOpeningHours => 'Opening Hours';

  @override
  String get detailEveryDay => 'Every day';

  @override
  String get detailFactArea => 'Setting';

  @override
  String get detailAreaOutdoor => 'Outdoor';

  @override
  String get detailAreaIndoor => 'Indoor';

  @override
  String get profileInterests => 'Your interests';

  @override
  String get profileInterestsHint => 'Picked automatically for every new trip.';

  @override
  String get profilePriorities => 'Route priorities';

  @override
  String get profileWeightInterest => 'Matches your interests';

  @override
  String get profileWeightInterestHint =>
      'Favor places in your chosen categories';

  @override
  String get profileWeightDistance => 'Distance & travel time';

  @override
  String get profileWeightDistanceHint => 'Favor places close to each other';

  @override
  String get profileWeightBudget => 'Save money';

  @override
  String get profileWeightBudgetHint => 'Favor cheap or free places';

  @override
  String get profileWeightRating => 'Place rating';

  @override
  String get profileWeightRatingHint => 'Favor well-reviewed places';

  @override
  String get profileNeedInterest => 'Pick at least one interest.';

  @override
  String get profileLoadFailed => 'Couldn\'t load your preferences.';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageName => 'English';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutBody =>
      'You\'ll need to sign in again to open your trips.';

  @override
  String get profilePasswordCurrent => 'Current password';

  @override
  String get profilePasswordNew => 'New password';

  @override
  String get profilePasswordConfirm => 'Repeat the new password';

  @override
  String get profilePasswordSubmit => 'Save password';

  @override
  String get profileEyebrow => 'PROFILE';

  @override
  String get profileHeadline => 'Plan trips your way';

  @override
  String get profilePasswordGoogleOnly =>
      'Your account was made with Google, so it has no password yet. Set one here to also sign in with your email.';
}
