// lib/config/routes.dart (aggiornato)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/features/auth/screens/contact_screen.dart';
import 'package:smart_warmth_2025/features/auth/screens/forgot_password_screen.dart';
import 'package:smart_warmth_2025/features/auth/screens/login_screen.dart';
import 'package:smart_warmth_2025/features/auth/screens/register_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/bluetooth_device_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/bluetooth_scan_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/bluetooth_settings_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/device_detail_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/device_settings_screen.dart';
import 'package:smart_warmth_2025/features/device/screens/temperature_chart_screen.dart';
import 'package:smart_warmth_2025/features/home/screens/home_screen.dart';
import 'package:smart_warmth_2025/features/room/screens/add_device_to_room_screen.dart';
import 'package:smart_warmth_2025/features/room/screens/add_room_screen.dart';
import 'package:smart_warmth_2025/features/room/screens/room_detail_screen.dart';
import 'package:smart_warmth_2025/features/settings/screens/wifi_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      // Ottieni lo stato corrente di autenticazione
      final isLoggedIn = authState == AuthState.authenticated;

      // Definisci quali percorsi sono accessibili senza autenticazione
      final publicPaths = ['/login', '/register', '/forgot-password', '/contact'];
      final isPublicPath = publicPaths.contains(state.matchedLocation);

      // Se non è autenticato e sta cercando di accedere a un percorso protetto
      if (!isLoggedIn && !isPublicPath) {
        return '/login';
      }

      // Se è autenticato e sta cercando di accedere a login o registrazione
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/home';
      }

      // In tutti gli altri casi non fare alcun reindirizzamento
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-room',
        builder: (context, state) => const AddRoomScreen(),
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) => RoomDetailScreen(
          roomId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/room/:id/add-device',
        builder: (context, state) => AddDeviceToRoomScreen(
          roomId: state.pathParameters['id']!,
        ),
      ),
/*      GoRoute(
        path: '/add-device',
        builder: (context, state) => const AddDeviceScreen(),
      ),*/
      GoRoute(
        path: '/device/:id',
        builder: (context, state) => DeviceDetailScreen(
          deviceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/device/:id/settings',
        builder: (context, state) => DeviceSettingsScreen(
          deviceId: state.pathParameters['id']!,
        ),
      ),
/*      GoRoute(
        path: '/device/:id/programming',
        builder: (context, state) => DeviceProgrammingScreen(
          deviceId: state.pathParameters['id']!,
        ),
      ),*/
      GoRoute(
        path: '/device/:id/temperature-chart',
        builder: (context, state) => TemperatureChartScreen(
          deviceId: state.pathParameters['id']!,
        ),
      ),
/*
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
*/
      GoRoute(
        path: '/settings/wifi',
        builder: (context, state) => const WifiSetupScreen(),
      ),
/*
      GoRoute(
        path: '/settings/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/settings/third-party',
        builder: (context, state) => const ThirdPartyScreen(),
      ),
      GoRoute(
        path: '/settings/alexa-guide',
        builder: (context, state) => const AlexaGuideScreen(),
      ),
      GoRoute(
        path: '/settings/google-home-guide',
        builder: (context, state) => const GoogleHomeGuideScreen(),
      ),
*/
      // Rotte per dispositivi Bluetooth
      GoRoute(
        path: '/bluetooth-scan',
        builder: (context, state) => const BluetoothScanScreen(),
      ),
      GoRoute(
        path: '/device-bluetooth/:id',
        builder: (context, state) {
          final deviceId = state.pathParameters['id']!;
          return BluetoothDeviceScreen(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: '/device-bluetooth-settings/:id',
        builder: (context, state) {
          final deviceId = state.pathParameters['id']!;
          return BluetoothSettingsScreen(deviceId: deviceId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Errore: Pagina non trovata'),
      ),
    ),
  );
});