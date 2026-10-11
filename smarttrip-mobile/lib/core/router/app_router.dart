import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/place_reviews/review_form_screen.dart';
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
        final leavesGuestArea = location == AppRoutes.splash ||
            AppRoutes.guestOnlyPaths.contains(location);
        return leavesGuestArea ? AppRoutes.catalog : null;
      }

      if (location == AppRoutes.splash) return AppRoutes.login;
      if (!AppRoutes.publicPaths.contains(location)) return AppRoutes.login;
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
        path: AppRoutes.trips,
        builder: (context, state) => const TripTersimpanScreen(),
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const ReviewFormScreen(),
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
    ],
  );
});
