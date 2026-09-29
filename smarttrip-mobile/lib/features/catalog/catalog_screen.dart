import 'package:flutter/material.dart';

/// Home / katalog tempat wisata (PRD Section 8 - browse tanpa login, US3).
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTrip Batam')),
      body: const Center(
        child: Text('Katalog tempat wisata'),
      ),
    );
  }
}
