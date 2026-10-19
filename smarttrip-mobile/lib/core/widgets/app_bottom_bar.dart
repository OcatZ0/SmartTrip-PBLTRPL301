import 'dart:ui';

import 'package:flutter/material.dart';

enum AppTab { home, wishlist, trips, profile }

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onCreateTrip,
    this.labels = const {
      AppTab.home: 'Home',
      AppTab.wishlist: 'Wishlist',
      AppTab.trips: 'Trip Saya',
      AppTab.profile: 'Profil',
    },
    this.createLabel = 'Buat Trip',
  });

  static const barHeight = 76.0;
  static const fabRise = 20.0;
  static const _fabSize = 62.0;

  static const _navy900 = Color(0xFF0A2440);
  static const _sea600 = Color(0xFF2B6FAB);
  static const _sun400 = Color(0xFFF6B03C);
  static const _ink = Color(0xFF14212F);
  static const _inkMuted = Color(0xFF5D6B7C);

  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onCreateTrip;
  final Map<AppTab, String> labels;
  final String createLabel;

  static TextStyle _text(FontWeight weight, Color color) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 11,
      height: 14 / 11,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: barHeight + fabRise + bottomInset,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomInset,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140A2440),
                    offset: Offset(0, -8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 10 + bottomInset),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tab(AppTab.home, Icons.home_outlined, Icons.home_rounded),
                    _tab(
                      AppTab.wishlist,
                      Icons.favorite_border_rounded,
                      Icons.favorite_rounded,
                    ),
                    SizedBox(
                      width: 84,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: ExcludeSemantics(
                            child: Text(
                              createLabel,
                              style: _text(FontWeight.w700, _ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _tab(AppTab.trips, Icons.explore_outlined, Icons.explore),
                    _tab(
                      AppTab.profile,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: createLabel,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onCreateTrip,
                child: Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: _sun400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x730A2440),
                        offset: Offset(0, 10),
                        blurRadius: 22,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: _navy900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(AppTab tab, IconData icon, IconData activeIcon) {
    final selected = tab == current;
    final color = selected ? _sea600 : _inkMuted;
    final label = labels[tab] ?? tab.name;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => onSelect(tab),
          radius: 32,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                Icon(selected ? activeIcon : icon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    selected ? FontWeight.w700 : FontWeight.w500,
                    color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
