import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/widgets/auth_layout.dart';
import '../../screens/catalog/catalog_screen.dart';
import '../../screens/catalog/place_detail_screen.dart';
import '../../screens/live_trip/live_map_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/place_review/review_form_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/saved_trip/trip_tersimpan_screen.dart';
import '../../screens/shared_trip/share_trip_readonly_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/trip/generate_itinerary_screen.dart';
import '../../screens/trip/itinerary_screen.dart';
import '../../screens/trip/trip_hotel_screen.dart';
import '../../screens/trip/trip_preferences_screen.dart';
import '../../screens/trip/trip_setup_screen.dart';
import '../../screens/trip/wishlist_step_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';
import '../auth/session_controller.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

class _SessionRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable();
  ref.onDispose(refreshListenable.dispose);
  ref.listen(sessionControllerProvider, (_, __) => refreshListenable.refresh());
  ref.listen(splashFinishedProvider, (_, __) => refreshListenable.refresh());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (session.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Let the launch animation finish before leaving the splash.
      if (location == AppRoutes.splash && !ref.read(splashFinishedProvider)) {
        return null;
      }

      final isLoggedIn = session.valueOrNull != null;

      if (isLoggedIn) {
        final leavesGuestArea =
            location == AppRoutes.splash ||
            AppRoutes.guestOnlyPaths.contains(location);
        return leavesGuestArea ? AppRoutes.catalog : null;
      }

      if (location == AppRoutes.splash) return AppRoutes.login;
      if (!AppRoutes.isPublic(location)) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        pageBuilder: (context, state) =>
            PageTransitions.fadeThrough(state, const CatalogScreen()),
      ),
      GoRoute(
        path: '/places/:placesId',
        builder: (context, state) => PlaceDetailScreen(
          placesId: int.parse(state.pathParameters['placesId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.trips,
        pageBuilder: (context, state) =>
            PageTransitions.fadeThrough(state, const TripTersimpanScreen()),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        pageBuilder: (context, state) =>
            PageTransitions.fadeThrough(state, const WishlistScreen()),
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const ReviewFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.sharedTrip,
        builder: (context, state) => const ShareTripReadonlyScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => PageTransitions.softFade(
          state,
          const LoginScreen(),
          fillColor: AuthColors.navy900,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => PageTransitions.sharedAxis(
          state,
          const RegisterScreen(),
          fillColor: AuthColors.navy900,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => PageTransitions.sharedAxis(
          state,
          const ForgotPasswordScreen(),
          fillColor: AuthColors.navy900,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            PageTransitions.sharedAxis(state, const OnboardingScreen()),
      ),

      // Declared before '/trips/:tripsId' so "new" is not read as an id.
      GoRoute(
        path: AppRoutes.newTrip,
        pageBuilder: (context, state) =>
            PageTransitions.sharedAxis(state, const TripSetupScreen()),
      ),
      GoRoute(
        path: '/trips/:tripsId',
        builder: (context, state) => ItineraryScreen(tripsId: _tripsId(state)),
        routes: [
          GoRoute(
            path: 'wishlist',
            pageBuilder: (context, state) => PageTransitions.sharedAxis(
              state,
              WishlistStepScreen(tripsId: _tripsId(state)),
            ),
          ),
          GoRoute(
            path: 'preferences',
            pageBuilder: (context, state) => PageTransitions.sharedAxis(
              state,
              TripPreferencesScreen(tripsId: _tripsId(state)),
            ),
          ),
          GoRoute(
            path: 'hotel',
            pageBuilder: (context, state) => PageTransitions.sharedAxis(
              state,
              TripHotelScreen(tripsId: _tripsId(state)),
            ),
          ),
          GoRoute(
            path: 'generate',
            pageBuilder: (context, state) => PageTransitions.sharedAxis(
              state,
              GenerateItineraryScreen(tripsId: _tripsId(state)),
            ),
          ),
          GoRoute(
            path: 'days/:dayNumber/map',
            builder: (context, state) => LiveMapScreen(
              tripsId: _tripsId(state),
              dayNumber: int.parse(state.pathParameters['dayNumber']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) =>
            PageTransitions.fadeThrough(state, const ProfileScreen()),
      ),
    ],
  );
});

int _tripsId(GoRouterState state) =>
    int.parse(state.pathParameters['tripsId']!);
