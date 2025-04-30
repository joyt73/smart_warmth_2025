import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/providers/utility_provider.dart';
import 'package:smart_warmth_2025/core/services/locale_service.dart';


final localeServiceProvider = Provider<LocaleService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleService(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final LocaleService _localeService;

  LocaleNotifier(this._localeService) : super(const Locale('it')) {
    _init();
  }

  Future<void> _init() async {
    final locale = await _localeService.getLocale();
    state = locale;
  }

  Future<void> setLocale(String localeCode) async {
    if (LocaleService.supportedLocales.containsKey(localeCode)) {
      await _localeService.setLocale(localeCode);
      state = LocaleService.supportedLocales[localeCode]!;
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final localeService = ref.watch(localeServiceProvider);
  return LocaleNotifier(localeService);
});