class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const catalog = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const profile = '/profile';

  static const newTrip = '/trips/new';

  /// Trip setup steps 2-4, the generate screen and the itinerary (C2-D1).
  static String tripWishlist(int tripsId) => '/trips/$tripsId/wishlist';
  static String tripPreferences(int tripsId) => '/trips/$tripsId/preferences';
  static String tripHotel(int tripsId) => '/trips/$tripsId/hotel';
  static String tripGenerate(int tripsId) => '/trips/$tripsId/generate';
  static String trip(int tripsId) => '/trips/$tripsId';
  static String liveMap(int tripsId, int dayNumber) =>
      '/trips/$tripsId/days/$dayNumber/map';

  /// B2 Detail Tempat (F006).
  static String place(int placesId) => '/places/$placesId';
  static const trips = '/trips';
  static const review = '/review';

  /// Reachable without being logged in (PRD Section 8: browsing is public).
  static const publicPaths = {catalog, login, register, forgotPassword, trips, review};

  /// Place details are public too, like the catalog they open from.
  static bool isPublic(String location) =>
      publicPaths.contains(location) || location.startsWith('/places/');

  /// Only reachable while logged out.
  static const guestOnlyPaths = {login, register, forgotPassword};
}