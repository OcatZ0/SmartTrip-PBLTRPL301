import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

/// Place photo from the API server, or a tinted placeholder icon when the
/// place has no photo or it fails to load.
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.url, this.icon = Icons.landscape_outlined});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final placeholder = ColoredBox(
      color: tokens.chipFill,
      child: Center(child: Icon(icon, color: tokens.link.withValues(alpha: 0.5))),
    );

    final photoUrl = url;
    if (photoUrl == null) return placeholder;

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }
}
