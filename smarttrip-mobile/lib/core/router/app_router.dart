import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/catalog/presentation/place_detail_screen.dart';
import '../../features/live_trip/presentation/live_map_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trip/presentation/generate_itinerary_screen.dart';
import '../../features/trip/presentation/itinerary_screen.dart';
import '../../features/trip/presentation/trip_hotel_screen.dart';
import '../../features/trip/presentation/trip_preferences_screen.dart';
import '../../features/trip/presentation/trip_setup_screen.dart';
import '../../features/wishlist/presentation/wishlist_step_screen.dart';
import '../../features/place_reviews/review_form_screen.dart';
import '../../features/share_trip_readonly/share_trip_readonly_screen.dart';
import '../../features/trip_management/trip_tersimpan_screen.dart';
import '../auth/session_controller.dart';
import 'app_routes.dart';

class _SessionRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable();
  ref.onDispose(refreshListenable.dispose);
  ref.listen(sessionControllerProvider, (_, __) => refreshListenable.refresh());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (session.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
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
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/places/:placesId',
        builder: (context, state) => PlaceDetailScreen(
          placesId: int.parse(state.pathParameters['placesId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.trips,
        builder: (context, state) => const TripTersimpanScreen(),
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Declared before '/trips/:tripsId' so "new" is not read as an id.
      GoRoute(
        path: AppRoutes.newTrip,
        builder: (context, state) => const TripSetupScreen(),
      ),
      GoRoute(
        path: '/trips/:tripsId',
        builder: (context, state) => ItineraryScreen(tripsId: _tripsId(state)),
        routes: [
          GoRoute(
            path: 'wishlist',
            builder: (context, state) =>
                WishlistStepScreen(tripsId: _tripsId(state)),
          ),
          GoRoute(
            path: 'preferences',
            builder: (context, state) =>
                TripPreferencesScreen(tripsId: _tripsId(state)),
          ),
          GoRoute(
            path: 'hotel',
            builder: (context, state) =>
                TripHotelScreen(tripsId: _tripsId(state)),
          ),
          GoRoute(
            path: 'generate',
            builder: (context, state) =>
                GenerateItineraryScreen(tripsId: _tripsId(state)),
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
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

int _tripsId(GoRouterState state) =>
    int.parse(state.pathParameters['tripsId']!);
