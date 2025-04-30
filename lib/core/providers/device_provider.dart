// lib/providers/device_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/services/device_service.dart';
import 'user_provider.dart';

// Classe che rappresenta lo stato di un dispositivo
class DeviceState {
  final Device? device;
  final bool isLoading;
  final String? error;
  final Schedule? schedule;
  final Map<String, List<Temperature>>? temperatures;

  DeviceState({
    this.device,
    this.isLoading = false,
    this.error,
    this.schedule,
    this.temperatures,
  });

  DeviceState copyWith({
    Device? device,
    bool? isLoading,
    String? error,
    Schedule? schedule,
    Map<String, List<Temperature>>? temperatures,
  }) {
    return DeviceState(
      device: device ?? this.device,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      schedule: schedule ?? this.schedule,
      temperatures: temperatures ?? this.temperatures,
    );
  }
}

// Notifier per lo stato di un dispositivo
class DeviceStateNotifier extends StateNotifier<DeviceState> {
  final DeviceService _deviceService;
  final UserStateNotifier _userStateNotifier;

  DeviceStateNotifier(this._deviceService, this._userStateNotifier) : super(DeviceState());

  // Ottieni i dettagli di un dispositivo
  Future<void> fetchDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.getDevice(deviceId);

    if (result.success) {
      state = state.copyWith(
        device: result.data,
        isLoading: false,
        error: null,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(result.data!);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  // Ottieni la programmazione di un dispositivo
  Future<void> fetchSchedule(String deviceId, int slot) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.getDeviceSchedule(deviceId, slot);

    if (result.success) {
      state = state.copyWith(
        schedule: result.data,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  // Ottieni i dati di temperatura
  Future<void> fetchTemperatures(
      String deviceId,
      DateTime from,
      DateTime to,
      ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.getTemperatures(deviceId, from, to);

    if (result.success) {
      state = state.copyWith(
        temperatures: result.data,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  // Registra un nuovo dispositivo
  Future<DeviceResult<Device>> registerDevice(
      String serial,
      String name,
      String? timezoneId,
      ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.registerDevice(serial, name, timezoneId);

    state = state.copyWith(isLoading: false);

    if (result.success && result.data != null) {
      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(result.data!);
    }

    return result;
  }

  // Modifica il nome di un dispositivo
  Future<DeviceResult<bool>> setDeviceName(String deviceId, String name) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setDeviceName(deviceId, name);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Rimuovi un dispositivo
  Future<DeviceResult<bool>> removeDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.removeDevice(deviceId);

    state = state.copyWith(isLoading: false);

    if (result.success) {
      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.removeThermostat(deviceId);
    } else {
      state = state.copyWith(error: result.error);
    }

    return result;
  }

  // Imposta la modalità di un dispositivo
  Future<DeviceResult<String>> setDeviceMode(String deviceId, DeviceMode mode) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setDeviceMode(deviceId, mode);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Imposta le funzioni di un dispositivo
  Future<DeviceResult<List<String>>> setDeviceFunctions(
      String deviceId,
      List<DeviceFunction> functions,
      ) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setDeviceFunctions(deviceId, functions);

    if (result.success) {
      // Converti le stringhe in enum
      final deviceFunctions = result.data!.map((f) => DeviceFunctionExtension.fromString(f)).toList();

      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: deviceFunctions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Imposta la temperatura comfort
  Future<DeviceResult<double>> setComfortTemperature(
      String deviceId,
      double temperature,
      ) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setComfortTemperature(deviceId, temperature);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: temperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Imposta la temperatura economy
  Future<DeviceResult<double>> setEconomyTemperature(
      String deviceId,
      double temperature,
      ) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setEconomyTemperature(deviceId, temperature);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: temperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Ping dispositivo
  Future<DeviceResult<bool>> identifyDevice(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.identifyDevice(deviceId);

    state = state.copyWith(isLoading: false);

    if (!result.success) {
      state = state.copyWith(error: result.error);
    }

    return result;
  }

  // Imposta il programma attivo
  Future<DeviceResult<int>> setCurrentSchedule(String deviceId, int slot) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setCurrentSchedule(deviceId, slot);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: slot,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: state.device!.timezone,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }

  // Imposta la programmazione
  Future<DeviceResult<bool>> setSchedules(
      String deviceId,
      int slot,
      Schedule schedule,
      ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setSchedules(deviceId, slot, schedule);

    state = state.copyWith(
      isLoading: false,
      schedule: result.success ? schedule : state.schedule,
      error: result.success ? null : result.error,
    );

    return result;
  }

  // Imposta il timezone
  Future<DeviceResult<Timezone>> setTimezone(String deviceId, String timezoneId) async {
    if (state.device == null) {
      return DeviceResult(success: false, error: 'Dispositivo non disponibile');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _deviceService.setTimezone(deviceId, timezoneId);

    if (result.success) {
      // Aggiorna lo stato locale
      final updatedDevice = Device(
        id: state.device!.id,
        name: state.device!.name,
        online: state.device!.online,
        version: state.device!.version,
        mode: state.device!.mode,
        room: state.device!.room,
        ambientTemperature: state.device!.ambientTemperature,
        comfortTemperature: state.device!.comfortTemperature,
        economyTemperature: state.device!.economyTemperature,
        boostTime: state.device!.boostTime,
        boostRemainingTime: state.device!.boostRemainingTime,
        currentSchedule: state.device!.currentSchedule,
        functions: state.device!.functions,
        holidayTime: state.device!.holidayTime,
        holidayRemainingTime: state.device!.holidayRemainingTime,
        timezone: result.data!,
      );

      state = state.copyWith(
        device: updatedDevice,
        isLoading: false,
      );

      // Aggiorna anche i dati nel provider dell'utente
      _userStateNotifier.updateThermostat(updatedDevice);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }

    return result;
  }
}

// Provider per il DeviceService
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

// Provider per il dispositivo selezionato
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

// Provider per lo stato del dispositivo
final deviceStateProvider = StateNotifierProvider<DeviceStateNotifier, DeviceState>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  final userStateNotifier = ref.watch(userStateProvider.notifier);
  return DeviceStateNotifier(deviceService, userStateNotifier);
});

// Provider per ottenere la schedule del dispositivo selezionato
final deviceScheduleProvider = Provider<Schedule?>((ref) {
  return ref.watch(deviceStateProvider).schedule;
});

// Provider per ottenere le temperature del dispositivo selezionato
final deviceTemperaturesProvider = Provider<Map<String, List<Temperature>>?>((ref) {
  return ref.watch(deviceStateProvider).temperatures;
});