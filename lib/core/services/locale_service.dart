import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'app_locale';

  final SharedPreferences _prefs;

  LocaleService(this._prefs);

  static const Map<String, Locale> supportedLocales = {
    'en': Locale('en'),
    'it': Locale('it'),
    'fr': Locale('fr'),
    'es': Locale('es'),
  };

  Future<Locale> getLocale() async {
    final String? localeCode = _prefs.getString(_localeKey);
    if (localeCode != null && supportedLocales.containsKey(localeCode)) {
      return supportedLocales[localeCode]!;
    }
    return const Locale('it'); // Default locale
  }

  Future<void> setLocale(String localeCode) async {
    if (supportedLocales.containsKey(localeCode)) {
      await _prefs.setString(_localeKey, localeCode);
    }
  }
}
