// lib/graphql/client.dart
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'errors/error_link.dart';

class GraphQLClientService {
  static GraphQLClientService? _instance;
  GraphQLClient? _client;

  final String _apiUrl = 'https://graphqlwifi.radiatori2000.it/graphql';

  // Singleton pattern
  static GraphQLClientService get instance {
    _instance ??= GraphQLClientService._();
    return _instance!;
  }

  GraphQLClientService._();

  // Ottieni il client GraphQL
  GraphQLClient get client {
    if (_client == null) {
      throw Exception('GraphQL client non inizializzato. Chiama init() prima.');
    }
    return _client!;
  }

  // Inizializza il client GraphQL
  Future<void> init() async {
    print("GQL_CLIENT: Inizializzazione client GraphQL");
    try {
      await initHiveForFlutter();
      print("GQL_CLIENT: Hive inizializzato");

      final HttpLink httpLink = HttpLink(_apiUrl);
      print("GQL_CLIENT: HttpLink creato per URL: $_apiUrl");

      final AuthLink authLink = AuthLink(
        getToken: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          print("GQL_CLIENT: Token recuperato: ${token != null ? 'presente' : 'assente'}");
          if (token == null) return null;
          return 'Bearer $token';
        },
      );

      final ErrorLink errorLink = createErrorLink();
      print("GQL_CLIENT: ErrorLink creato");

      final Link link = authLink.concat(errorLink).concat(httpLink);
      print("GQL_CLIENT: Link concatenati");

      _client = GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: link,
        defaultPolicies: DefaultPolicies(
          query: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
            cacheReread: CacheRereadPolicy.mergeOptimistic,
          ),
          mutate: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
            cacheReread: CacheRereadPolicy.mergeOptimistic,
          ),
          subscribe: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
            cacheReread: CacheRereadPolicy.mergeOptimistic,
          ),
        ),
      );
      print("GQL_CLIENT: Client GraphQL inizializzato con successo");
    } catch (e) {
      print("GQL_CLIENT ERROR: Errore durante l'inizializzazione del client: $e");
      rethrow;
    }
  }

  // Verifica se l'utente è loggato
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Salva il token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Rimuovi il token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}