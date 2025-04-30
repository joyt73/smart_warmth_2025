// lib/core/bluetooth/ble_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';

/// Modalità di funzionamento disponibili per il termostato
enum DeviceMode {
  standby(10),
  filPilot(20),
  comfort(30),
  economy(40),
  antIce(50),
  schedule(70),
  boost(80);

  final int value;
  const DeviceMode(this.value);

  static DeviceMode fromValue(int value) {
    return DeviceMode.values.firstWhere(
          (mode) => mode.value == value,
      orElse: () => DeviceMode.standby,
    );
  }
}

/// Funzioni supportate dal termostato
enum DeviceFunction {
  window('WINDOW'),
  keyLock('KEY_LOCK'),
  asc('ASC'),
  eco('ECO');

  final String value;
  const DeviceFunction(this.value);

  static DeviceFunction? fromValue(String value) {
    try {
      return DeviceFunction.values.firstWhere(
            (function) => function.value == value,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Modello del termostato connesso via Bluetooth
class BluetoothThermostat {
  final String id;
  final String name;
  DeviceMode mode;
  List<DeviceFunction> functionValues;
  double comfortTemperature;
  double economyTemperature;
  double ambientTemperature;
  int schedulerSlot;
  List<String> p8;
  List<String> p9;

  BluetoothThermostat({
    required this.id,
    required this.name,
    this.mode = DeviceMode.standby,
    this.functionValues = const [],
    this.comfortTemperature = 19,
    this.economyTemperature = 17,
    this.ambientTemperature = 20,
    this.schedulerSlot = 0,
    this.p8 = const [],
    this.p9 = const [],
  });

  BluetoothThermostat copyWith({
    String? id,
    String? name,
    DeviceMode? mode,
    List<DeviceFunction>? functionValues,
    double? comfortTemperature,
    double? economyTemperature,
    double? ambientTemperature,
    int? schedulerSlot,
    List<String>? p8,
    List<String>? p9,
  }) {
    return BluetoothThermostat(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      functionValues: functionValues ?? this.functionValues,
      comfortTemperature: comfortTemperature ?? this.comfortTemperature,
      economyTemperature: economyTemperature ?? this.economyTemperature,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      schedulerSlot: schedulerSlot ?? this.schedulerSlot,
      p8: p8 ?? this.p8,
      p9: p9 ?? this.p9,
    );
  }
}

typedef ThermostatCallback = void Function(BluetoothThermostat thermostat);
typedef StateCallback = void Function(bool isEnabled);
typedef DisconnectCallback = void Function(dynamic error);

class BleManager {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  BluetoothThermostat? _thermostat;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _connectionSubscription;
  List<StreamSubscription> _characteristicSubscriptions = [];

  // Caratteristiche UUID
  static const String serviceUUID = '6c8b5040-233f-11e6-bdf4-0800200c9a66';
  static const String writeUUID = '06d9b970-2340-11e6-bdf4-0800200c9a66';
  static const String temperatureUUID = 'c9c79d21-8007-4bff-a707-5d90e380bbfe';
  static const String modeUUID = '2277af8c-8435-4f9b-a89f-a473bdd01d85';
  static const String functionUUID = 'a4cf66ae-8dcc-49fb-9047-12d31f8e2f05';
  static const String p8FirstUUID = '2c7c7ee0-3ca8-41f1-af57-f97ff8eb6bea';
  static const String p8SecondUUID = '523bc415-0e2b-4fd2-ad6a-5c1b78f5de2a';
  static const String p9FirstUUID = '2e933520-3754-11e8-b566-0800200c9a66';
  static const String p9SecondUUID = '3b125d80-3754-11e8-b566-0800200c9a66';

  // Stream controllers per gestire le notifiche
  final StreamController<BluetoothThermostat> _thermostatController =
  StreamController<BluetoothThermostat>.broadcast();

  // Instanza singleton
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  /// Stream di eventi del termostato
  Stream<BluetoothThermostat> get thermostatStream => _thermostatController.stream;

  /// Verifica lo stato del Bluetooth e notifica tramite la callback
  Future<void> state(StateCallback stateCallback) async {
    await _ble.statusStream.first.then((status) {
      final bool isEnabled = status == BleStatus.ready;
      stateCallback(isEnabled);
    });
  }

  /// Ascolta i cambiamenti di stato del Bluetooth
  void onStateChange(StateCallback stateCallback) {
    _stateSubscription?.cancel();
    _stateSubscription = _ble.statusStream.listen((status) {
      final bool isEnabled = status == BleStatus.ready;
      stateCallback(isEnabled);
    });
  }

  /// Effettua una scansione alla ricerca di dispositivi Bluetooth
  Future<List<DiscoveredDevice>> discover(List<String> deviceIds) async {
    final completer = Completer<List<DiscoveredDevice>>();
    final List<DiscoveredDevice> devices = [];

    // Ascolta i risultati della scansione
    late StreamSubscription<DiscoveredDevice> scanSubscription;
    scanSubscription = _ble.scanForDevices(
      withServices: [], // Scansione di tutti i dispositivi
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      // Filtra dispositivi che contengono 'One' nel nome e non sono già stati trovati
      if (device.name.isNotEmpty &&
          device.name.contains('One') &&
          !deviceIds.contains(device.id) &&
          !devices.any((d) => d.id == device.id)) {
        devices.add(device);
      }
    }, onError: (error) {
      scanSubscription.cancel();
      completer.completeError(error);
    });

    // Imposta un timer per fermare la scansione dopo 3 secondi
    Timer(const Duration(seconds: 3), () {
      scanSubscription.cancel();
      completer.complete(devices);
    });

    return completer.future;
  }

  /// Trova uno specifico dispositivo Bluetooth
  Future<DiscoveredDevice?> discoverSingle(String deviceId) async {
    final completer = Completer<DiscoveredDevice?>();

    // Ascolta i risultati della scansione
    late StreamSubscription<DiscoveredDevice> scanSubscription;
    scanSubscription = _ble.scanForDevices(
      withServices: [], // Scansione di tutti i dispositivi
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.id == deviceId) {
        scanSubscription.cancel();
        completer.complete(device);
      }
    }, onError: (error) {
      scanSubscription.cancel();
      completer.completeError(error);
    });

    // Imposta un timeout
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        scanSubscription.cancel();
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Si connette a un dispositivo e legge le caratteristiche
  Future<BluetoothThermostat?> connect(DiscoveredDevice device) async {
    try {
      _thermostat = BluetoothThermostat(
        id: device.id,
        name: device.name,
      );

      // Cerca il dispositivo
      final foundDevice = await discoverSingle(_thermostat!.id);
      if (foundDevice == null) {
        return null;
      }

      // Connessione al dispositivo
      _cancelConnectionSubscription();
      _connectionSubscription = _ble
          .connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 15),
      )
          .listen(
            (connectionState) {
          // Gestione degli stati di connessione
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            _discoverServicesAndCharacteristics(device.id);
          }
        },
        onError: (error) {
          debugPrint('Errore connessione: $error');
          _thermostat = null;
        },
      );

      // Attendi la connessione
      await _waitForConnection(device.id);

      // Scopri servizi e caratteristiche
      final results = await _discoverServicesAndCharacteristics(device.id);
      if (results == null) {
        return null;
      }

      // Aggiorna il termostato con tutti i valori letti
      _thermostat = _thermostat!.copyWith(
        mode: results['mode'],
        comfortTemperature: results['temperatureResult']['comfortTemperature'] ?? 19.0,
        economyTemperature: results['temperatureResult']['economyTemperature'] ?? 17.0,
        ambientTemperature: results['temperatureResult']['ambientTemperature'] ?? 20.0,
        functionValues: results['functionResult'],
        schedulerSlot: results['p8SecondStep']['schedulerSlot'] ?? 0,
        p8: [...results['p8FirstStep'], ...results['p8SecondStep']['days']],
        p9: [...results['p9FirstStep'], ...results['p9SecondStep']['days']],
      );

      // Notifica gli ascoltatori
      _thermostatController.add(_thermostat!);

      // Registra per notifiche di caratteristiche
      _setupCharacteristicNotifications(device.id);

      return _thermostat;
    } catch (error) {
      debugPrint('Errore di connessione: $error');
      try {
        await _ble.deinitialize();
      } catch (e) {
        debugPrint('Errore di deinizializzazione: $e');
      }
      return null;
    }
  }

  // Attende che la connessione si stabilisca
  Future<void> _waitForConnection(String deviceId) async {
    final completer = Completer<void>();

    late StreamSubscription<ConnectionStateUpdate> subscription;
    subscription = _ble.connectToDevice(id: deviceId).listen(
          (update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          subscription.cancel();
          completer.complete();
        }
        if (update.connectionState == DeviceConnectionState.disconnected) {
          subscription.cancel();
          completer.completeError('Disconnesso durante il tentativo di connessione');
        }
      },
      onError: (e) {
        subscription.cancel();
        completer.completeError(e);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException('Timeout di connessione');
      },
    );
  }

  /// Scopre i servizi e legge le caratteristiche
  Future<Map<String, dynamic>?> _discoverServicesAndCharacteristics(String deviceId) async {
    try {
      // Leggi tutte le caratteristiche necessarie
      final temperatureResult = await _readTemperatureCharacteristic(deviceId);
      final functionResult = await _readFunctionCharacteristic(deviceId);
      final mode = await _readModeCharacteristic(deviceId);
      final p8FirstStep = await _readP8FirstStepCharacteristic(deviceId);
      final p8SecondStep = await _readP8SecondStepCharacteristic(deviceId);
      final p9FirstStep = await _readP9FirstStepCharacteristic(deviceId);
      final p9SecondStep = await _readP9SecondStepCharacteristic(deviceId);

      return {
        'mode': mode,
        'temperatureResult': temperatureResult,
        'functionResult': functionResult,
        'p8FirstStep': p8FirstStep,
        'p8SecondStep': p8SecondStep,
        'p9FirstStep': p9FirstStep,
        'p9SecondStep': p9SecondStep,
      };
    } catch (e) {
      debugPrint('Errore durante la scoperta dei servizi: $e');
      return null;
    }
  }

  /// Configura le notifiche per le caratteristiche
  void _setupCharacteristicNotifications(String deviceId) {
    // Cancella eventuali sottoscrizioni precedenti
    _clearCharacteristicSubscriptions();

    // Aggiungi le sottoscrizioni per le caratteristiche
    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: temperatureUUID,
        onNotification: (data) {
          final result = _parseTemperatureCharacteristic(data);
          if (result != null && _thermostat != null) {
            _thermostat = _thermostat!.copyWith(
              comfortTemperature: result['comfortTemperature']!,
              economyTemperature: result['economyTemperature']!,
              ambientTemperature: result['ambientTemperature']!,
            );
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: modeUUID,
        onNotification: (data) {
          final mode = _parseModeCharacteristic(data);
          if (_thermostat != null) {
            _thermostat = _thermostat!.copyWith(mode: mode);
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: functionUUID,
        onNotification: (data) {
          final functions = _parseFunctionCharacteristic(data);
          if (_thermostat != null) {
            _thermostat = _thermostat!.copyWith(functionValues: functions);
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    // Programmiamo anche p8 e p9
    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: p8FirstUUID,
        onNotification: (data) {
          final days = _parseProgramFirstCharacteristic(data);
          if (days != null && _thermostat != null) {
            List<String> updatedP8 = List.from(_thermostat!.p8);
            for (int i = 0; i < 4 && i < days.length; i++) {
              if (i < updatedP8.length) {
                updatedP8[i] = days[i];
              } else {
                updatedP8.add(days[i]);
              }
            }
            _thermostat = _thermostat!.copyWith(p8: updatedP8);
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: p8SecondUUID,
        onNotification: (data) {
          final result = _parseProgramSecondCharacteristic(data);
          if (result != null && _thermostat != null) {
            List<String> updatedP8 = List.from(_thermostat!.p8);
            for (int i = 0; i < result['days'].length; i++) {
              if (i + 4 < updatedP8.length) {
                updatedP8[i + 4] = result['days'][i];
              } else {
                updatedP8.add(result['days'][i]);
              }
            }
            _thermostat = _thermostat!.copyWith(
              p8: updatedP8,
              schedulerSlot: result['schedulerSlot'],
            );
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: p9FirstUUID,
        onNotification: (data) {
          final days = _parseProgramFirstCharacteristic(data);
          if (days != null && _thermostat != null) {
            List<String> updatedP9 = List.from(_thermostat!.p9);
            for (int i = 0; i < 4 && i < days.length; i++) {
              if (i < updatedP9.length) {
                updatedP9[i] = days[i];
              } else {
                updatedP9.add(days[i]);
              }
            }
            _thermostat = _thermostat!.copyWith(p9: updatedP9);
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );

    _characteristicSubscriptions.add(
      _setupCharacteristicNotification(
        deviceId: deviceId,
        serviceId: serviceUUID,
        characteristicId: p9SecondUUID,
        onNotification: (data) {
          final result = _parseProgramSecondCharacteristic(data);
          if (result != null && _thermostat != null) {
            List<String> updatedP9 = List.from(_thermostat!.p9);
            for (int i = 0; i < result['days'].length; i++) {
              if (i + 4 < updatedP9.length) {
                updatedP9[i + 4] = result['days'][i];
              } else {
                updatedP9.add(result['days'][i]);
              }
            }
            _thermostat = _thermostat!.copyWith(p9: updatedP9);
            _thermostatController.add(_thermostat!);
          }
        },
      ),
    );
  }

  /// Configura la notifica per una singola caratteristica
  StreamSubscription<List<int>> _setupCharacteristicNotification({
    required String deviceId,
    required String serviceId,
    required String characteristicId,
    required Function(List<int>) onNotification,
  }) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse(serviceId),
      characteristicId: Uuid.parse(characteristicId),
    );

    return _ble.subscribeToCharacteristic(characteristic).listen(
      onNotification,
      onError: (error) {
        debugPrint('Errore nella sottoscrizione alla caratteristica: $error');
      },
    );
  }

  void _clearCharacteristicSubscriptions() {
    for (var subscription in _characteristicSubscriptions) {
      subscription.cancel();
    }
    _characteristicSubscriptions.clear();
  }

  /// Funzione per leggere la caratteristica della temperatura
  Future<Map<String, double>> _readTemperatureCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(temperatureUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseTemperatureCharacteristic(response) ?? {
        'comfortTemperature': 19.0,
        'economyTemperature': 17.0,
        'ambientTemperature': 20.0,
      };
    } catch (e) {
      debugPrint('Errore nella lettura della temperatura: $e');
      return {
        'comfortTemperature': 19.0,
        'economyTemperature': 17.0,
        'ambientTemperature': 20.0,
      };
    }
  }

  /// Parsing della caratteristica della temperatura
  Map<String, double>? _parseTemperatureCharacteristic(List<int> value) {
    try {
      final decoded = utf8.decode(value);

      final comfortTemperature =
          (decoded.codeUnitAt(2) * 100 + decoded.codeUnitAt(1)) / 10;
      final economyTemperature =
          (decoded.codeUnitAt(4) * 100 + decoded.codeUnitAt(3)) / 10;
      final ambientTemperature =
          (decoded.codeUnitAt(6) * 100 + decoded.codeUnitAt(5)) / 10;

      return {
        'comfortTemperature': comfortTemperature >= 7 ? comfortTemperature : 7,
        'economyTemperature': economyTemperature >= 7 ? economyTemperature : 7,
        'ambientTemperature': ambientTemperature >= 7 ? ambientTemperature : 7,
      };
    } catch (e) {
      debugPrint('Errore nel parsing della temperatura: $e');
      return null;
    }
  }

  /// Funzione per leggere la caratteristica delle funzioni
  Future<List<DeviceFunction>> _readFunctionCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(functionUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseFunctionCharacteristic(response);
    } catch (e) {
      debugPrint('Errore nella lettura delle funzioni: $e');
      return [];
    }
  }

  /// Parsing della caratteristica delle funzioni
  List<DeviceFunction> _parseFunctionCharacteristic(List<int> value) {
    try {
      final decoded = utf8.decode(value);
      final functionValue = decoded.codeUnitAt(1);

      List<DeviceFunction> functions = [];

      if ((functionValue & 1) == 1) functions.add(DeviceFunction.window);
      if ((functionValue & 4) == 4) functions.add(DeviceFunction.keyLock);
      if ((functionValue & 8) == 8) functions.add(DeviceFunction.asc);
      if ((functionValue & 16) == 16) functions.add(DeviceFunction.eco);

      return functions;
    } catch (e) {
      debugPrint('Errore nel parsing delle funzioni: $e');
      return [];
    }
  }

  /// Funzione per leggere la caratteristica della modalità
  Future<DeviceMode> _readModeCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(modeUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseModeCharacteristic(response);
    } catch (e) {
      debugPrint('Errore nella lettura della modalità: $e');
      return DeviceMode.standby;
    }
  }

  /// Parsing della caratteristica della modalità
  DeviceMode _parseModeCharacteristic(List<int> value) {
    try {
      final decoded = utf8.decode(value);
      final mode = decoded.codeUnitAt(1);

      return DeviceMode.fromValue(mode);
    } catch (e) {
      debugPrint('Errore nel parsing della modalità: $e');
      return DeviceMode.standby;
    }
  }

  /// Funzione di decodifica dei giorni di programmazione
  String _decodeDay(int a, int b, int c) {
    final day = (a << 16) + (b << 8) + (c << 0);
    String dayHex = day.toRadixString(16);
    for (int i = 8 - dayHex.length; i > 0; i--) {
      dayHex = '0$dayHex';
    }
    return '0x$dayHex';
  }

  /// Legge la prima parte della programmazione P8
  Future<List<String>> _readP8FirstStepCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(p8FirstUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseProgramFirstCharacteristic(response) ?? [];
    } catch (e) {
      debugPrint('Errore nella lettura P8 primo step: $e');
      return [];
    }
  }

  /// Parsing del primo step della programmazione
  List<String>? _parseProgramFirstCharacteristic(List<int> value) {
    try {
      final decoded = utf8.decode(value);

      // decodifica.codeUnitAt(0) è uguale a 05
      final day0 = _decodeDay(
          decoded.codeUnitAt(3),
          decoded.codeUnitAt(2),
          decoded.codeUnitAt(1)
      );
      final day1 = _decodeDay(
          decoded.codeUnitAt(6),
          decoded.codeUnitAt(5),
          decoded.codeUnitAt(4)
      );
      final day2 = _decodeDay(
          decoded.codeUnitAt(9),
          decoded.codeUnitAt(8),
          decoded.codeUnitAt(7)
      );
      final day3 = _decodeDay(
          decoded.codeUnitAt(12),
          decoded.codeUnitAt(11),
          decoded.codeUnitAt(10)
      );

      return [day0, day1, day2, day3];
    } catch (e) {
      debugPrint('Errore nel parsing del primo step: $e');
      return null;
    }
  }

  /// Legge la seconda parte della programmazione P8
  Future<Map<String, dynamic>> _readP8SecondStepCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(p8SecondUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseProgramSecondCharacteristic(response) ?? { 'days': [], 'schedulerSlot': 0 };
    } catch (e) {
      debugPrint('Errore nella lettura P8 secondo step: $e');
      return { 'days': [], 'schedulerSlot': 0 };
    }
  }

  /// Parsing del secondo step della programmazione
  Map<String, dynamic>? _parseProgramSecondCharacteristic(List<int> value) {
    try {
      final decoded = utf8.decode(value);

      // decodifica.codeUnitAt(0) è uguale a 06
      final day4 = _decodeDay(
          decoded.codeUnitAt(3),
          decoded.codeUnitAt(2),
          decoded.codeUnitAt(1)
      );
      final day5 = _decodeDay(
          decoded.codeUnitAt(6),
          decoded.codeUnitAt(5),
          decoded.codeUnitAt(4)
      );
      final day6 = _decodeDay(
          decoded.codeUnitAt(9),
          decoded.codeUnitAt(8),
          decoded.codeUnitAt(7)
      );

      final schedulerSlot = decoded.codeUnitAt(10);

      return {
        'days': [day4, day5, day6],
        'schedulerSlot': schedulerSlot
      };
    } catch (e) {
      debugPrint('Errore nel parsing del secondo step: $e');
      return null;
    }
  }

  /// Legge la prima parte della programmazione P9
  Future<List<String>> _readP9FirstStepCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(p9FirstUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseProgramFirstCharacteristic(response) ?? [];
    } catch (e) {
      debugPrint('Errore nella lettura P9 primo step: $e');
      return [];
    }
  }

  /// Legge la seconda parte della programmazione P9
  Future<Map<String, dynamic>> _readP9SecondStepCharacteristic(String deviceId) async {
    try {
      final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse(serviceUUID),
        characteristicId: Uuid.parse(p9SecondUUID),
      );

      final response = await _ble.readCharacteristic(characteristic);
      return _parseProgramSecondCharacteristic(response) ?? { 'days': [] };
    } catch (e) {
      debugPrint('Errore nella lettura P9 secondo step: $e');
      return { 'days': [] };
    }
  }

  /// Invia le caratteristiche al termostato
  Future<void> sendCharacteristics(BluetoothThermostat thermostat) async {
    if (_thermostat == null) {
      throw Exception("Nessun termostato connesso");
    }

    // Converti le caratteristiche e invia
    final steps = _convertThermostatCharacteristics(thermostat);

    // Invia ogni passo
    for (final step in steps) {
      await _writeCharacteristic(
        deviceId: thermostat.id,
        serviceId: serviceUUID,
        characteristicId: writeUUID,
        data: base64Decode(step),
      );
    }

    // Aggiorna il termostato locale
    _thermostat = thermostat;
    _thermostatController.add(_thermostat!);
  }

  /// Scrittura di una caratteristica
  Future<void> _writeCharacteristic({
    required String deviceId,
    required String serviceId,
    required String characteristicId,
    required List<int> data,
  }) async {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse(serviceId),
      characteristicId: Uuid.parse(characteristicId),
    );

    await _ble.writeCharacteristicWithResponse(characteristic, value: data);
  }

  /// Converte le caratteristiche del termostato in bytes da inviare
  List<String> _convertThermostatCharacteristics(BluetoothThermostat thermostat) {
    // Verifica la coerenza tra le temperature comfort e economy
    double comfortTemperature = thermostat.comfortTemperature;
    double economyTemperature = thermostat.economyTemperature;

    // Se è cambiata la comfort, abbassa la economy se necessario
    if (_thermostat != null && _thermostat!.comfortTemperature != comfortTemperature) {
      if (economyTemperature > comfortTemperature) {
        economyTemperature = comfortTemperature;
      }
    }
    // Se è cambiata la economy, alza la comfort se necessario
    else if (_thermostat != null && _thermostat!.economyTemperature != economyTemperature) {
      if (comfortTemperature < economyTemperature) {
        comfortTemperature = economyTemperature;
      }
    }

    // Ottieni data corrente
    final now = DateTime.now();
    final day = now.weekday - 1 < 0 ? 6 : now.weekday - 1;

    // Converti le temperature
    final convertedComfortTemperature = _convertTemperature(comfortTemperature);
    final convertedEconomyTemperature = _convertTemperature(economyTemperature);
    final convertedFunctionsValues = _convertFunctions(thermostat.functionValues);

    // Step 1
    final step1 = <int>[];
    step1.add(0x11); // Header
    step1.add(thermostat.mode.value); // Mode
    step1.add(convertedComfortTemperature[0]);
    step1.add(convertedComfortTemperature[1]);
    step1.add(convertedEconomyTemperature[0]);
    step1.add(convertedEconomyTemperature[1]);
    step1.add(convertedFunctionsValues);
    step1.add(day);
    step1.add(now.hour);
    step1.add(now.minute);
    step1.add(now.second);
    step1.add(thermostat.schedulerSlot); // byte[11]=programma timer in uso

    // Padding
    for (int i = 0; i < 7; i++) {
      step1.add(0);
    }

    // Continua flag: 0x00 se si continua con le fasi successive, 0xAA se ci si ferma qui
    step1.add(0x00);

    // Step 2
    final step2 = <int>[];
    step2.add(0x22); // Header

    final p8WeekArray = _convertWeekToArrayOfArraysOfBytes(thermostat.p8);

    // Primi 6 giorni del P8
    for (int i = 0; i < 6; i++) {
      if (i < p8WeekArray.length) {
        step2.add(p8WeekArray[i][0]);
        step2.add(p8WeekArray[i][1]);
        step2.add(p8WeekArray[i][2]);
      }
    }

    step2.add(0); // zero mancante

    // Step 3
    final step3 = <int>[];
    step3.add(0x33); // Header

    // Ultimo giorno del P8
    if (p8WeekArray.length > 6) {
      step3.add(p8WeekArray[6][0]);
      step3.add(p8WeekArray[6][1]);
      step3.add(p8WeekArray[6][2]);
    } else {
      step3.addAll([0, 0, 0]);
    }

    // Primi 5 giorni del P9
    final p9WeekArray = _convertWeekToArrayOfArraysOfBytes(thermostat.p9);
    for (int i = 0; i < 5; i++) {
      if (i < p9WeekArray.length) {
        step3.add(p9WeekArray[i][0]);
        step3.add(p9WeekArray[i][1]);
        step3.add(p9WeekArray[i][2]);
      }
    }

    step3.add(0); // zero mancante

    // Step 4
    final step4 = <int>[];
    step4.add(0x44); // Header

    // Giorni 5 e 6 del P9
    for (int i = 5; i < 7; i++) {
      if (i < p9WeekArray.length) {
        step4.add(p9WeekArray[i][0]);
        step4.add(p9WeekArray[i][1]);
        step4.add(p9WeekArray[i][2]);
      }
    }

    // Zeri mancanti
    for (int i = 0; i < 13; i++) {
      step4.add(0);
    }

    // Converti in stringhe base64
    final step1String = String.fromCharCodes(step1);
    final step2String = String.fromCharCodes(step2);
    final step3String = String.fromCharCodes(step3);
    final step4String = String.fromCharCodes(step4);

    return [
      base64.encode(utf8.encode(step1String)),
      base64.encode(utf8.encode(step2String)),
      base64.encode(utf8.encode(step3String)),
      base64.encode(utf8.encode(step4String)),
    ];
  }

  /// Converte la settimana in array di array di bytes
  List<List<int>> _convertWeekToArrayOfArraysOfBytes(List<String> week) {
    return week.map((day) {
      List<int> result = [];
      String hexString = day;
      // Prendi solo gli ultimi 6 caratteri
      hexString = hexString.substring(hexString.length - 6, hexString.length);

      // Converti ogni coppia di caratteri in un numero esadecimale
      while (hexString.length >= 2) {
        result.add(int.parse(hexString.substring(0, 2), radix: 16));
        hexString = hexString.substring(2);
      }

      // Riorganizza i byte nell'ordine corretto
      return [result[2], result[1], result[0]];
    }).toList();
  }

  /// Converte una temperatura in bytes
  List<int> _convertTemperature(double temperature) {
    final tempValue = temperature * 10;
    final moreSig = (tempValue / 0x100).floor();
    final lessSig = (tempValue % 0x100).floor();
    return [moreSig, lessSig];
  }

  /// Converte le funzioni in un valore intero
  int _convertFunctions(List<DeviceFunction> functions) {
    int value = 0;
    if (functions.contains(DeviceFunction.window)) value += 1;
    if (functions.contains(DeviceFunction.keyLock)) value += 4;
    if (functions.contains(DeviceFunction.asc)) value += 8;
    if (functions.contains(DeviceFunction.eco)) value += 16;
    return value;
  }

  /// Disconnette il termostato
  Future<void> disconnect() async {
    // Cancella tutte le sottoscrizioni
    _clearCharacteristicSubscriptions();
    _cancelConnectionSubscription();

    if (_thermostat != null) {
      try {
        // Con flutter_reactive_ble, la disconnessione avviene annullando la sottoscrizione
        // e chiamando il metodo di disconnessione se necessario
        if (_connectionSubscription != null) {
          _connectionSubscription!.cancel();
          _connectionSubscription = null;
        }
      } catch (error) {
        debugPrint('Errore di disconnessione: $error');
        throw error;
      } finally {
        _thermostat = null;
      }
    }
  }

  void _cancelConnectionSubscription() {
    if (_connectionSubscription != null) {
      _connectionSubscription!.cancel();
      _connectionSubscription = null;
    }
  }

  /// Restituisce il termostato attualmente connesso
  BluetoothThermostat? connectedDevice() {
    return _thermostat;
  }

  /// Registra per ricevere notifiche dal termostato
  StreamSubscription<BluetoothThermostat> registerNotify(
      ThermostatCallback thermostatCallback
      ) {
    return thermostatStream.listen(thermostatCallback);
  }

  /// Disattiva le registrazioni per le notifiche
  void unregisterNotify(StreamSubscription subscription) {
    subscription.cancel();
  }

  /// Registra la callback di disconnessione
  StreamSubscription registerDisconnect(DisconnectCallback disconnectCallback) {
    if (_thermostat == null) {
      throw Exception("Nessun termostato connesso");
    }

    return _ble.connectToDevice(id: _thermostat!.id).listen((state) {
      if (state.connectionState == DeviceConnectionState.disconnected) {
        disconnectCallback(null);
      }
    });
  }

  /// Disattiva la registrazione per la disconnessione
  void unregisterDisconnect(StreamSubscription subscription) {
    subscription.cancel();
  }

  /// Riavvia il manager Bluetooth
  void restartManager() {
    // Cancella tutte le sottoscrizioni
    _clearCharacteristicSubscriptions();
    _cancelConnectionSubscription();
    _stateSubscription?.cancel();

    // Disconnette eventuali dispositivi connessi
    if (_thermostat != null) {
      disconnect();
    }
  }
}