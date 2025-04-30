// lib/services/user_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/graphql/errors/error_handler.dart';
import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/graphql/queries/user_queries.dart';
import 'package:smart_warmth_2025/features/auth/models/user_model.dart';

class UserResult<T> {
  final bool success;
  final T? data;
  final String? error;

  UserResult({required this.success, this.data, this.error});
}

class UserService {
  final GraphQLClientService _clientService = GraphQLClientService.instance;

  // Ottieni i dati dell'utente
  Future<UserResult<User>> getUser() async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(UserQueries.viewer),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientService.client.query(options);

      if (result.hasException) {
        if (ErrorHandlerNew.isAuthError(result.exception?.graphqlErrors)) {
          await _clientService.removeToken();
        }

        return UserResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final userData = result.data?['viewer'];
      if (userData == null) {
        return UserResult(
          success: false,
          error: 'Nessun dato utente trovato',
        );
      }

      final user = User.fromJson(userData);
      return UserResult(success: true, data: user);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
    }
  }

  // Ottieni i timezone disponibili
  Future<UserResult<List<Timezone>>> getTimezones() async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(UserQueries.timezones),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientService.client.query(options);

      if (result.hasException) {
        return UserResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final timezonesData = result.data?['viewer']['timezones'] as List<dynamic>?;
      if (timezonesData == null) {
        return UserResult(
          success: false,
          error: 'Nessun timezone trovato',
        );
      }

      final timezones = timezonesData
          .where((timezone) => timezone != null)
          .map((timezone) => Timezone.fromJson(timezone))
          .toList();

      return UserResult(success: true, data: timezones);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
    }
  }
}