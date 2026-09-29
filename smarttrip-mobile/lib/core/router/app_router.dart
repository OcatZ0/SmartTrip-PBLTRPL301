import 'package:go_router/go_router.dart';

import '../../features/catalog/catalog_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CatalogScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);
