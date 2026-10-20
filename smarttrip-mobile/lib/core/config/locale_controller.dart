import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language picked on the profile; null follows the phone.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'app_language';

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_key);
      if (code != null) state = Locale(code);
    } catch (_) {
      // No stored choice can be read (e.g. in widget tests): follow the phone.
    }
  }

  Future<void> select(String languageCode) async {
    state = Locale(languageCode);
    await (await SharedPreferences.getInstance()).setString(_key, languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);
