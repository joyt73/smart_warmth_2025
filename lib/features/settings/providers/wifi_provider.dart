// lib/features/settings/providers/wifi_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wifi_service.dart';
import '../models/wifi_network.dart';

final wifiServiceProvider = Provider<WifiService>((ref) {
  return WifiService();
});

class WifiNetworkNotifier extends StateNotifier<List<WifiNetwork>> {
  final WifiService _service;

  WifiNetworkNotifier(this._service) : super([]) {
    _loadNetworks();
  }

  Future<void> _loadNetworks() async {
    final networks = await _service.getSavedNetworks();
    state = networks;
  }

  Future<void> addNetwork(String ssid, String password) async {
    await _service.saveNetwork(ssid, password);
    await _loadNetworks();
  }

  Future<void> removeNetwork(String ssid) async {
    await _service.removeNetwork(ssid);
    await _loadNetworks();
  }
}

final wifiNetworksProvider = StateNotifierProvider<WifiNetworkNotifier, List<WifiNetwork>>((ref) {
  final service = ref.watch(wifiServiceProvider);
  return WifiNetworkNotifier(service);
});