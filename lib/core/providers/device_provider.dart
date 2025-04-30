// lib/core/providers/device_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/services/device_service.dart';

// Provider per il servizio di Device
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

// Provider per la lista di dispositivi
final devicesProvider = FutureProvider<List<Device>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.fetchDevices();
});

// Provider per dispositivi disponibili (da utilizzare per aggiungere alle stanze)
final availableDevicesProvider = FutureProvider<List<Device>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.fetchDevices();
});

// Provider per dispositivi filtrati per una stanza specifica
final devicesByRoomProvider = FutureProvider.family<List<Device>, String>((ref, roomId) async {
  final devices = await ref.watch(devicesProvider.future);
  return devices.where((device) => device.room?.id == roomId).toList();
});

// Provider per un dispositivo specifico per ID
final deviceByIdProvider = FutureProvider.family<Device?, String>((ref, deviceId) async {
  final devices = await ref.watch(devicesProvider.future);
  try {
    return devices.firstWhere((device) => device.id == deviceId);
  } catch (e) {
    return null;
  }
});

// Notifier per le operazioni sui dispositivi
class DeviceNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  final DeviceService _deviceService;

  DeviceNotifier(this._deviceService) : super(const AsyncValue.loading()) {
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      state = const AsyncValue.loading();
      final devices = await _deviceService.fetchDevices();
      state = AsyncValue.data(devices);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refreshDevices() async {
    await _loadDevices();
  }

  Future<bool> setDeviceMode(String deviceId, DeviceMode mode) async {
    try {
      // Implementare la chiamata al servizio per impostare la modalità
      // await _deviceService.setDeviceMode(deviceId, mode);

      // Aggiornare lo stato locale
      if (state.hasValue) {
        final updatedDevices = state.value!.map((device) {
          if (device.id == deviceId) {
            return device.copyWith(mode: mode);
          }
          return device;
        }).toList();

        state = AsyncValue.data(updatedDevices);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

// Altri metodi per operazioni sui dispositivi (temperatura, funzioni, ecc.)
}

final deviceNotifierProvider = StateNotifierProvider<DeviceNotifier, AsyncValue<List<Device>>>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return DeviceNotifier(deviceService);
});