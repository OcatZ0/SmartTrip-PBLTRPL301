class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const catalog = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const trips = '/trips';
  static const review = '/review';
  static const sharedTrip = '/shared-trip';

  /// Reachable without being logged in (PRD Section 8: browsing is public).
  static const publicPaths = {catalog, login, register, forgotPassword, trips, review, sharedTrip};

  /// Only reachable while logged out.
  static const guestOnlyPaths = {login, register, forgotPassword};
}
