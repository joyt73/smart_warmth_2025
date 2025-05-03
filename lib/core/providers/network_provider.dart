import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modello per le configurazioni di rete
class NetworkConfiguration {
  final String? ssid;
  final String? password;
  final bool isConfigured;

  NetworkConfiguration({
    this.ssid,
    this.password,
    this.isConfigured = false,
  });

  NetworkConfiguration copyWith({
    String? ssid,
    String? password,
    bool? isConfigured,
  }) {
    return NetworkConfiguration(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  factory NetworkConfiguration.initial() {
    return NetworkConfiguration(
      ssid: null,
      password: null,
      isConfigured: false,
    );
  }
}

// Notifier per la gestione dello stato del provider
class NetworkNotifier extends StateNotifier<NetworkConfiguration> {
  NetworkNotifier() : super(NetworkConfiguration.initial()) {
    _loadNetworkConfiguration();
  }

  // Carica la configurazione di rete dalle SharedPreferences
  Future<void> _loadNetworkConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ssid = prefs.getString('network_ssid');
      final password = prefs.getString('network_password');
      final isConfigured = prefs.getBool('network_configured') ?? false;

      if (ssid != null && password != null && isConfigured) {
        state = NetworkConfiguration(
          ssid: ssid,
          password: password,
          isConfigured: true,
        );
      }
    } catch (e) {
      // Gestione dell'errore
      print('Errore nel caricamento della configurazione di rete: $e');
    }
  }

  // Salva la configurazione di rete
  Future<void> saveNetworkConfiguration(String ssid, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('network_ssid', ssid);
      await prefs.setString('network_password', password);
      await prefs.setBool('network_configured', true);

      state = NetworkConfiguration(
        ssid: ssid,
        password: password,
        isConfigured: true,
      );
    } catch (e) {
      // Gestione dell'errore
      print('Errore nel salvare la configurazione di rete: $e');
      throw Exception('Impossibile salvare la configurazione di rete: $e');
    }
  }

  // Rimuovi la configurazione di rete
  Future<void> clearNetworkConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('network_ssid');
      await prefs.remove('network_password');
      await prefs.setBool('network_configured', false);

      state = NetworkConfiguration.initial();
    } catch (e) {
      // Gestione dell'errore
      print('Errore nella rimozione della configurazione di rete: $e');
      throw Exception('Impossibile rimuovere la configurazione di rete: $e');
    }
  }

  // Controlla se la rete è configurata
  bool isNetworkConfigured() {
    return state.isConfigured;
  }
}

// Provider per la gestione della configurazione di rete
final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkConfiguration>((ref) {
  return NetworkNotifier();
});