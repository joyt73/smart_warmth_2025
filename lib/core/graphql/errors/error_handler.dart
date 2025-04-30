// lib/graphql/errors/error_handler.dart
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// Classe per la gestione degli errori GraphQL
class ErrorHandlerNew {
  /// Estrae un messaggio di errore leggibile da una lista di errori GraphQL
  static String getMessageFromGraphQLError(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) {
      return 'Si è verificato un errore sconosciuto';
    }

    final error = errors.first;

    // Controlla se l'errore contiene un messaggio specifico
    if (error.message.contains('Email already taken') || error.message.contains('Email già registrata')) {
      return 'Email già registrata';
    }

    if (error.message.contains('Invalid credentials') || error.message.contains('Credenziali non valide')) {
      return 'Credenziali non valide';
    }

    if (error.message.contains('Password too short') || error.message.contains('Password troppo corta')) {
      return 'La password deve essere di almeno 6 caratteri';
    }

    // Restituisci il messaggio di errore originale se non corrisponde a nessun caso specifico
    return error.message;
  }

  /// Verifica se un errore è relativo all'autenticazione
  static bool isAuthError(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) {
      return false;
    }

    for (final error in errors) {
      if (error.message.contains('Unauthorized') ||
          error.message.contains('Non autorizzato') ||
          error.message.contains('token') ||
          error.extensions?.containsKey('code') == true &&
              error.extensions!['code'] == 'UNAUTHENTICATED') {
        return true;
      }
    }

    return false;
  }

  /// Registra gli errori GraphQL nella console (solo in modalità debug)
  static void logGraphQLError(List<GraphQLError>? errors, {String? operation}) {
    if (errors == null || errors.isEmpty) return;

    for (final error in errors) {
      debugPrint(
        '[GraphQL Error] Operation: ${operation ?? 'unknown'}, '
            'Message: ${error.message}, '
            'Location: ${error.locations}, '
            'Path: ${error.path}, '
            'Extensions: ${error.extensions}',
      );
    }
  }

  /// Gestisce errori di rete specifici
  static String handleNetworkError(LinkException? exception) {
    if (exception == null) {
      return 'Errore di rete sconosciuto';
    }

    if (exception is ServerException) {
      return 'Errore del server: ${exception.originalException ?? 'Risposta non valida dal server'}';
    }

    if (exception is HttpLinkServerException) {
      final statusCode = exception.response.statusCode;
      if (statusCode == 404) {
        return 'Servizio non trovato';
      } else if (statusCode == 500) {
        return 'Errore interno del server';
      } else if (statusCode == 403) {
        return 'Accesso non autorizzato';
      } else if (statusCode == 401) {
        return 'Autenticazione richiesta';
      } else {
        return 'Errore HTTP: $statusCode';
      }
    }

    return exception.toString();
  }
}

/// Crea un link per la gestione degli errori nelle richieste GraphQL
ErrorLink createErrorLink() {
  return ErrorLink(
    onGraphQLError: (request, forward, response) {
      final errors = response.errors;
      if (errors != null && errors.isNotEmpty) {
        ErrorHandlerNew.logGraphQLError(errors, operation: request.operation.operationName);
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