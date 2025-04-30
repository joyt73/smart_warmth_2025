// lib/core/bluetooth/ble_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_manager.dart';

/// Provider per il gestore BLE
final bleManagerProvider = Provider<BleManager>((ref) {
  return BleManager();
});

/// Provider per lo stream del termostato Bluetooth
final bluetoothThermostatProvider = StreamProvider<BluetoothThermostat?>((ref) {
  final bleManager = ref.watch(bleManagerProvider);
  return bleManager.thermostatStream;
});

/// Provider per lo stato attuale del bluetooth (on/off)
final bluetoothStateProvider = StateNotifierProvider<BluetoothStateNotifier, bool>((ref) {
  return BluetoothStateNotifier(ref.watch(bleManagerProvider));
});

/// StateNotifier per gestire lo stato del Bluetooth
class BluetoothStateNotifier extends StateNotifier<bool> {
  final BleManager _bleManager;

  BluetoothStateNotifier(this._bleManager) : super(false) {
    _init();
  }

  void _init() async {
    // Controllo dello stato iniziale
    await _bleManager.state((isEnabled) {
      state = isEnabled;
    });

    // Impostazione del listener per i cambiamenti di stato
    _bleManager.onStateChange((isEnabled) {
      state = isEnabled;
    });
  }
}