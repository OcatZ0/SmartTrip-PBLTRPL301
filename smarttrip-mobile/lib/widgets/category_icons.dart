import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/widgets.dart';

/// Category `icon_symbol` (set in the admin panel) to the same Bootstrap
/// Icons glyph the admin shows. Mirrors `Category::ICON_SYMBOLS` in the API;
/// a key added there needs a line here too.
const Map<String, IconData> _categoryIcons = {
  'ombak': BootstrapIcons.tsunami,
  'feri': BootstrapIcons.life_preserver,
  'selam': BootstrapIcons.water,
  'pantai': BootstrapIcons.umbrella_fill,
  'pulau': BootstrapIcons.globe_asia_australia,
  'air': BootstrapIcons.droplet_half,
  'senja': BootstrapIcons.sunset_fill,
  'matahari': BootstrapIcons.sun_fill,
  'alam': BootstrapIcons.tree_fill,
  'taman': BootstrapIcons.flower2,
  'spa': BootstrapIcons.flower1,
  'kemah': BootstrapIcons.fire,
  'hiking': BootstrapIcons.signpost_2_fill,
  'petualangan': BootstrapIcons.compass_fill,
  'sepeda': BootstrapIcons.bicycle,
  'kuliner': BootstrapIcons.cup_hot_fill,
  'restoran': BootstrapIcons.egg_fried,
  'kafe': BootstrapIcons.cup_straw,
  'belanja': BootstrapIcons.bag_fill,
  'pasar': BootstrapIcons.shop,
  'oleh': BootstrapIcons.gift_fill,
  'budaya': BootstrapIcons.bank2,
  'sejarah': BootstrapIcons.hourglass_split,
  'museum': BootstrapIcons.easel_fill,
  'seni': BootstrapIcons.palette_fill,
  'religi': BootstrapIcons.bookmark_star_fill,
  'landmark': BootstrapIcons.geo_alt_fill,
  'foto': BootstrapIcons.camera_fill,
  'romantis': BootstrapIcons.heart_fill,
  'populer': BootstrapIcons.star_fill,
  'keluarga': BootstrapIcons.people_fill,
  'anak': BootstrapIcons.balloon_fill,
  'hiburan': BootstrapIcons.controller,
  'acara': BootstrapIcons.calendar_event_fill,
  'malam': BootstrapIcons.moon_stars_fill,
  'musik': BootstrapIcons.music_note_beamed,
  'kota': BootstrapIcons.buildings_fill,
  'penginapan': BootstrapIcons.house_heart_fill,
  'transport': BootstrapIcons.bus_front_fill,
  'pesawat': BootstrapIcons.airplane_fill,
};

/// Glyph for a category, or null when the API sent no or an unknown key.
IconData? categoryIcon(String? iconSymbol) => _categoryIcons[iconSymbol];
