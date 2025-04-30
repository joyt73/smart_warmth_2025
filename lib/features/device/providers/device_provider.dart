// lib/features/device/providers/device_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  // Qui puoi iniettare le dipendenze necessarie
  return DeviceRepository();
});

final devicesProvider = StateNotifierProvider<DevicesNotifier, List<DeviceModel>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return DevicesNotifier(repository);
});

class DevicesNotifier extends StateNotifier<List<DeviceModel>> {
  final DeviceRepository _repository;

  DevicesNotifier(this._repository) : super([]) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    try {
      final devices = await _repository.getDevices();
      state = devices;
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> addDevice(DeviceModel device) async {
    try {
      final newDevice = await _repository.addDevice(device);
      state = [...state, newDevice];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> updateDevice(DeviceModel device) async {
    try {
      await _repository.updateDevice(device);
      state = [
        for (final d in state)
          if (d.id == device.id) device else d,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> removeDevice(String id) async {
    try {
      await _repository.removeDevice(id);
      state = [
        for (final device in state)
          if (device.id != id) device,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> setDeviceMode(String id, DeviceMode mode) async {
    try {
      await _repository.setDeviceMode(id, mode);
      state = [
        for (final device in state)
          if (device.id == id) device.copyWith(mode: mode) else device,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> setTemperature(String id, double temperature, bool isComfort) async {
    try {
      if (isComfort) {
        await _repository.setComfortTemperature(id, temperature);
        state = [
          for (final device in state)
            if (device.id == id) device.copyWith(comfortTemperature: temperature) else device,
        ];
      } else {
        await _repository.setEconomyTemperature(id, temperature);
        state = [
          for (final device in state)
            if (device.id == id) device.copyWith(economyTemperature: temperature) else device,
        ];
      }
    } catch (e) {
      // Gestione degli errori
    }
  }
}