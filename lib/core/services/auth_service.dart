// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/graphql/errors/error_handler.dart';
import 'package:smart_warmth_2025/core/graphql/models/auth_model.dart';
import 'package:smart_warmth_2025/core/graphql/mutations/auth_mutations.dart';
import 'package:smart_warmth_2025/core/graphql/queries/user_queries.dart';
import 'package:smart_warmth_2025/features/auth/models/user_model.dart';


class AuthResult {
  final bool success;
  final String? token;
  final String? error;
  final User? user;

  AuthResult({
    required this.success,
    this.token,
    this.error,
    this.user,
  });
}

class AuthService {
  final GraphQLClientService _clientService = GraphQLClientService.instance;

  Future<AuthResult> login(String email, String password) async {
    try {
      debugPrint("LOGIN: Starting login process for $email");

      // 1. Effettua la mutation di login
      final loginResult = await _performLoginMutation(email, password);
      if (!loginResult.success) return loginResult;

      // 2. Salva il token
      await _clientService.saveToken(loginResult.token!);
      debugPrint("LOGIN: Token saved successfully");

      // 3. Recupera i dati utente
      final userResult = await _fetchUserData();
      if (!userResult.success) {
        debugPrint("LOGIN: User data fetch failed");
        return AuthResult(
          success: false,
          error: userResult.error ?? 'Failed to fetch user data',
        );
      }

      debugPrint("LOGIN: Login completed successfully");
      return AuthResult(
        success: true,
        token: loginResult.token,
        user: userResult.user,
      );
    } catch (e) {
      debugPrint("LOGIN: Critical error: ${e.toString()}");
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<AuthResult> _performLoginMutation(String email, String password) async {
    try {
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(AuthMutations.login),
          variables: {
            'input': LoginRequestInput(
              email: email.trim(),
              password: password.trim(),
            ).toJson(),
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        debugPrint("LOGIN: Mutation error: $error");
        return AuthResult(success: false, error: error);
      }

      final token = result.data?['login']['token'] as String?;
      if (token == null) {
        debugPrint("LOGIN: Missing token in response");
        return AuthResult(success: false, error: 'Missing authentication token');
      }

      return AuthResult(success: true, token: token);
    } catch (e) {
      debugPrint("LOGIN: Mutation exception: ${e.toString()}");
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<AuthResult> _fetchUserData() async {
    try {
      final result = await _clientService.client.query(
        QueryOptions(
          document: gql(UserQueries.viewer),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        debugPrint("LOGIN: User query error: $error");
        return AuthResult(success: false, error: error);
      }

      final userData = result.data?['viewer'];
      if (userData == null) {
        debugPrint("LOGIN: No user data in response");
        return AuthResult(success: false, error: 'No user data available');
      }

      return AuthResult(
        success: true,
        user: User.fromJson(userData),
      );
    } catch (e) {
      debugPrint("LOGIN: User query exception: ${e.toString()}");
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Registrazione
  Future<AuthResult> register(String displayName, String email, String password) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(AuthMutations.register),
        variables: {
          'input': RegisterRequestInput(
            displayName: displayName.trim(),
            email: email.trim(),
            password: password.trim(),
          ).toJson(),
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return AuthResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final token = result.data?['register']['token'] as String;
      await _clientService.saveToken(token);

      // Dopo aver salvato il token, facciamo una query per ottenere i dati dell'utente
      final userData = await _fetchUserData();

      if (userData.success && userData.user != null) {
        return AuthResult(
            success: true,
            token: token,
            user: userData.user
        );
      } else {
        // La registrazione è comunque riuscita, ma non abbiamo i dati utente
        return AuthResult(success: true, token: token);
      }
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Recupero password
  Future<AuthResult> forgotPassword(String email) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(AuthMutations.forgotPassword),
        variables: {
          'input': ForgotPasswordInput(
            email: email.trim(),
          ).toJson(),
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return AuthResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final success = result.data?['passwordRecovery']['success'] as bool;
      return AuthResult(success: success);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    await _clientService.removeToken();
  }

  // Verifica se l'utente è loggato e restituisce anche i dati utente se disponibili
  Future<AuthResult> checkAuthStatus() async {
    final isLoggedIn = await _clientService.isLoggedIn();

    if (!isLoggedIn) {
      return AuthResult(success: false);
    }

    // Se l'utente è loggato, proviamo a recuperare i suoi dati
    final userData = await _fetchUserData();

    if (userData.success && userData.user != null) {
      return AuthResult(success: true, user: userData.user);
    } else {
      // L'utente è loggato ma non siamo riusciti a recuperare i suoi dati
      return AuthResult(success: true);
    }
  }

  // Verifica solo se l'utente è loggato (metodo più leggero)
  Future<bool> isLoggedIn() async {
    return await _clientService.isLoggedIn();
  }

  // Eliminazione account
  Future<AuthResult> deleteAccount(String userId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(AuthMutations.deleteAccount),
        variables: {
          'input': {
            'id': userId,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return AuthResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final success = result.data?['deleteAccount']['success'] as bool;
      if (success) {
        await _clientService.removeToken();
      }

      return AuthResult(success: success);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }
}