import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../l10n/app_localizations.dart';

/// Home / katalog tempat wisata (PRD Section 8 - browse tanpa login, US3).
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SmartTrip Batam')),
      body: const Center(
        child: Text('Katalog tempat wisata'),
      ),
      // "Buat Trip" (B1): the router sends a logged-out user to login first.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newTrip),
        icon: const Icon(Icons.add_road),
        label: Text(l10n.catalogCreateTrip),
      ),
    );
  }
}
