import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SmartTripApp extends StatelessWidget {
  const SmartTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartTrip Batam',
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
