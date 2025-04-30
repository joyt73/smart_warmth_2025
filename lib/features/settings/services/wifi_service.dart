// lib/features/settings/services/wifi_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wifi_network.dart';

class WifiService {
  static const String _networksKey = 'wifi_networks';

  Future<String?> getCurrentWifi() async {
    // In un'app reale, utilizzeremmo un plugin per ottenere il WiFi corrente
    // Per ora, restituiamo un dato fittizio
    return 'HomeWiFi';
  }

  Future<List<WifiNetwork>> getSavedNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final networksJson = prefs.getStringList(_networksKey) ?? [];

    return networksJson
        .map((json) => WifiNetwork.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveNetwork(String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final networksJson = prefs.getStringList(_networksKey) ?? [];

    // Rimuoviamo la rete se esiste già
    final networks = networksJson
        .map((json) => WifiNetwork.fromJson(jsonDecode(json)))
        .where((network) => network.ssid != ssid)
        .toList();

    // Aggiungiamo la nuova rete
    networks.add(WifiNetwork(ssid: ssid, password: password));

    // Salviamo la lista aggiornata
    await prefs.setStringList(
      _networksKey,
      networks.map((network) => jsonEncode(network.toJson())).toList(),
    );
  }

  Future<void> removeNetwork(String ssid) async {
    final prefs = await SharedPreferences.getInstance();
    final networksJson = prefs.getStringList(_networksKey) ?? [];

    // Filtriamo le reti
    final networks = networksJson
        .map((json) => WifiNetwork.fromJson(jsonDecode(json)))
        .where((network) => network.ssid != ssid)
        .toList();

    // Salviamo la lista aggiornata
    await prefs.setStringList(
      _networksKey,
      networks.map((network) => jsonEncode(network.toJson())).toList(),
    );
  }
}