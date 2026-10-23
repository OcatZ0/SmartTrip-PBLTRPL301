import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';

/// Barelang panorama with the page eyebrow and title, like the catalog, and
/// [bottom] (tabs, a search field) floating over its bottom edge.
class PanoramaHeader extends StatelessWidget {
  const PanoramaHeader({super.key, required this.eyebrow, required this.title, required this.bottom});

  static const _panoramaHeight = 132.0;
  static const _bottomOverlap = 30.0;

  final String eyebrow;
  final String title;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topInset + _panoramaHeight + _bottomOverlap,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + _panoramaHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset('assets/images/login_panorama.svg', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8C0A2440), Color(0x000A2440)],
                      stops: [0, 0.75],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 18,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: appText(11, FontWeight.w700, AppColors.sun400, height: 16, letterSpacing: 0.88)),
                const SizedBox(height: 4),
                Text(title, style: appText(24, FontWeight.w800, Colors.white, height: 30, letterSpacing: -0.48)),
              ],
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 0, child: bottom),
        ],
      ),
    );
  }
}
