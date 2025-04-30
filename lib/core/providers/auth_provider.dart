// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/services/auth_service.dart';
import 'package:smart_warmth_2025/features/auth/models/user_model.dart';

// Stati possibili dell'autenticazione
enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

// Classe che rappresenta lo stato dell'autenticazione
class AuthStateData {
  final AuthState state;
  final User? user;
  final String? error;

  AuthStateData({
    required this.state,
    this.user,
    this.error,
  });

  AuthStateData copyWith({
    AuthState? state,
    User? user,
    String? error,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

// Notifier per lo stato dell'autenticazione
class AuthStateNotifier extends StateNotifier<AuthStateData> {
  final AuthService _authService;

  AuthStateNotifier(this._authService)
      : super(AuthStateData(state: AuthState.initial)) {
    _checkAuth();
  }

  // Controlla se l'utente è autenticato e recupera i dati utente
  Future<void> _checkAuth() async {
    state = state.copyWith(state: AuthState.loading);

    final authResult = await _authService.checkAuthStatus();

    if (authResult.success) {
      state = AuthStateData(
        state: AuthState.authenticated,
        user: authResult.user,
      );
    } else {
      state = AuthStateData(
        state: AuthState.unauthenticated,
      );
    }
  }

  // Login
  Future<AuthResult> login(String email, String password) async {
    state = state.copyWith(state: AuthState.loading, error: null);

    final result = await _authService.login(email, password);

    if (result.success) {
      state = AuthStateData(
        state: AuthState.authenticated,
        user: result.user,
      );
    } else {
      state = AuthStateData(
        state: AuthState.unauthenticated,
        error: result.error,
      );
    }

    return result;
  }

  // Registrazione
  Future<AuthResult> register(String displayName, String email, String password) async {
    state = state.copyWith(state: AuthState.loading, error: null);

    final result = await _authService.register(displayName, email, password);

    if (result.success) {
      state = AuthStateData(
        state: AuthState.authenticated,
        user: result.user,
      );
    } else {
      state = AuthStateData(
        state: AuthState.unauthenticated,
        error: result.error,
      );
    }

    return result;
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(state: AuthState.loading);
    await _authService.logout();
    state = AuthStateData(state: AuthState.unauthenticated);
  }

  // Recupero password
  Future<AuthResult> forgotPassword(String email) async {
    return await _authService.forgotPassword(email);
  }

  // Elimina account
  Future<AuthResult> deleteAccount(String userId) async {
    state = state.copyWith(state: AuthState.loading);

    final result = await _authService.deleteAccount(userId);

    if (result.success) {
      state = AuthStateData(state: AuthState.unauthenticated);
    } else {
      state = state.copyWith(
        state: AuthState.authenticated,
        error: result.error,
      );
    }

    return result;
  }

  // Aggiorna i dati utente
  void updateUser(User user) {
    if (state.state == AuthState.authenticated) {
      state = state.copyWith(user: user);
    }
  }
}

// Provider per lo stato dell'autenticazione
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthStateData>((ref) {
  final authService = AuthService();
  return AuthStateNotifier(authService);
});

// Provider per l'AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider per l'utente corrente
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

// Provider per lo stato di autenticazione
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).state == AuthState.authenticated;
});

// Provider per lo stato di caricamento
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).state == AuthState.loading;
});

// Provider per l'errore di autenticazione
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});