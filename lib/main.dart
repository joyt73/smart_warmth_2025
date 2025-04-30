// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_warmth_2025/config/router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/locale_provider.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/core/providers/utility_provider.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/core/services/locale_service.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inizializza il client GraphQL
  await GraphQLClientService.instance.init();

  // Imposta l'orientamento dell'app (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Prefetch data
    ref.read(roomsProvider.notifier).refreshRooms();
    ref.read(devicesProvider.notifier).loadDevices();

    return MaterialApp.router(
      title: 'Smart Warmth',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: LocaleService.supportedLocales.values,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Qui includiamo il nostro OverlayAlert che sarà visibile in tutta l'app
            const OverlayAlert(),
          ],
        );
      },
    );
  }
}