// lib/graphql/errors/error_link.dart
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// Crea un link per la gestione degli errori nelle richieste GraphQL
ErrorLink createErrorLink() {
  return ErrorLink(
    onGraphQLError: (request, forward, response) {
      final errors = response.errors;
      if (errors != null && errors.isNotEmpty) {
        for (final error in errors) {
          debugPrint(
            '[GraphQL Error]: ${error.message}, Posizione: ${error.locations}, Path: ${error.path}',
          );
        }
      }
      return forward(request);
    },
    onException: (request, forward, exception) {
      if (exception is OperationException) {
        final linkException = exception.originalException;
        if (linkException != null) {
          debugPrint('[Network Error]: ${linkException.toString()}');
        }
      } else {
        debugPrint('[Generic Error]: ${exception.toString()}');
      }
      return forward(request);
    },
  );
}

/// Classe per la gestione degli errori
class ErrorHandler {
  static String getMessageFromGraphQLError(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) {
      return 'Si è verificato un errore sconosciuto';
    }

    final error = errors.first;
    return error.message;
  }

  static bool isAuthError(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) {
      return false;
    }

    for (final error in errors) {
      if (error.message.contains('Unauthorized') ||
          error.message.contains('token') ||
          error.extensions?['code'] == 'UNAUTHENTICATED') {
        return true;
      }
    }

    return false;
  }
}