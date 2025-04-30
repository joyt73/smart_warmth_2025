// lib/services/device_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/graphql/errors/error_handler.dart';
import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/graphql/mutations/device_mutations.dart';
import 'package:smart_warmth_2025/core/graphql/queries/device_queries.dart';


class DeviceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  DeviceResult({required this.success, this.data, this.error});
}

class DeviceService {
  final GraphQLClientService _clientService = GraphQLClientService.instance;

  // Ottieni i dettagli di un termostato
  Future<DeviceResult<Device>> getDevice(String deviceId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(DeviceQueries.thermostat),
        variables: {
          'id': deviceId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientService.client.query(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final deviceData = result.data?['viewer']['thermostat'];
      if (deviceData == null) {
        return DeviceResult(
          success: false,
          error: 'Dispositivo non trovato',
        );
      }

      final device = Device.fromJson(deviceData);
      return DeviceResult(success: true, data: device);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Ottieni la programmazione di un termostato
  Future<DeviceResult<Schedule>> getDeviceSchedule(String deviceId, int slot) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(DeviceQueries.deviceProgramming),
        variables: {
          'nodeId': deviceId,
          'slot': slot,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientService.client.query(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final scheduleData = result.data?['node']['schedule'];
      if (scheduleData == null) {
        return DeviceResult(
          success: false,
          error: 'Programmazione non trovata',
        );
      }

      final schedule = Schedule.fromJson(scheduleData);
      return DeviceResult(success: true, data: schedule);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Ottieni i dati di temperatura
  Future<DeviceResult<Map<String, List<Temperature>>>> getTemperatures(
      String deviceId,
      DateTime from,
      DateTime to,
      ) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(DeviceQueries.temperatures),
        variables: {
          'id': deviceId,
          'from': from.millisecondsSinceEpoch.toDouble(),
          'to': to.millisecondsSinceEpoch.toDouble(),
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientService.client.query(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final nodeData = result.data?['node'];
      if (nodeData == null) {
        return DeviceResult(
          success: false,
          error: 'Dati temperature non trovati',
        );
      }

      final ambientTemperatures = (nodeData['ambientTemperatures'] as List<dynamic>?)
          ?.map((t) => Temperature.fromJson(t))
          .toList() ?? [];

      final economyTemperatures = (nodeData['economyTemperatures'] as List<dynamic>?)
          ?.map((t) => Temperature.fromJson(t))
          .toList() ?? [];

      final comfortTemperatures = (nodeData['comfortTemperatures'] as List<dynamic>?)
          ?.map((t) => Temperature.fromJson(t))
          .toList() ?? [];

      return DeviceResult(
        success: true,
        data: {
          'ambient': ambientTemperatures,
          'economy': economyTemperatures,
          'comfort': comfortTemperatures,
        },
      );
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Registra un nuovo termostato
  Future<DeviceResult<Device>> registerDevice(
      String serial,
      String name,
      String? timezoneId,
      ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.registerThermostat),
        variables: {
          'input': {
            'serial': serial,
            'name': name,
            if (timezoneId != null) 'timezoneId': timezoneId,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final deviceData = result.data?['thermostatRegister']['thermostat'];
      if (deviceData == null) {
        return DeviceResult(
          success: false,
          error: 'Errore nella registrazione del dispositivo',
        );
      }

      final device = Device.fromJson(deviceData);
      return DeviceResult(success: true, data: device);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Modifica il nome di un termostato
  Future<DeviceResult<bool>> setDeviceName(String deviceId, String name) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setThermostatName),
        variables: {
          'input': {
            'id': deviceId,
            'name': name,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      return DeviceResult(success: true, data: true);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Rimuovi un termostato
  Future<DeviceResult<bool>> removeDevice(String deviceId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.removeThermostat),
        variables: {
          'input': {
            'id': deviceId,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      return DeviceResult(success: true, data: true);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta la modalità di un termostato
  Future<DeviceResult<String>> setDeviceMode(String deviceId, DeviceMode mode) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setMode),
        variables: {
          'input': {
            'id': deviceId,
            'mode': mode.toString().split('.').last,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final modeResult = result.data?['oneSetMode']['thermostat']['mode'] as String;
      return DeviceResult(success: true, data: modeResult);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta le funzioni di un termostato
  Future<DeviceResult<List<String>>> setDeviceFunctions(
      String deviceId,
      List<DeviceFunction> functions,
      ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setFunctions),
        variables: {
          'input': {
            'id': deviceId,
            'functions': functions.map((f) => f.toString().split('.').last).toList(),
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final functionsResult = (result.data?['oneSetFunctions']['thermostat']['functions'] as List<dynamic>)
          .cast<String>()
          .toList();
      return DeviceResult(success: true, data: functionsResult);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta la temperatura comfort
  Future<DeviceResult<double>> setComfortTemperature(
      String deviceId,
      double temperature,
      ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setComfortTemperature),
        variables: {
          'input': {
            'id': deviceId,
            'temperature': temperature,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final tempResult = (result.data?['oneSetComfortTemperature']['thermostat']['comfortTemperature'] as num).toDouble();
      return DeviceResult(success: true, data: tempResult);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta la temperatura economy
  Future<DeviceResult<double>> setEconomyTemperature(
      String deviceId,
      double temperature,
      ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setEconomyTemperature),
        variables: {
          'input': {
            'id': deviceId,
            'temperature': temperature,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final tempResult = (result.data?['oneSetEconomyTemperature']['thermostat']['economyTemperature'] as num).toDouble();
      return DeviceResult(success: true, data: tempResult);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Ping termostato
  Future<DeviceResult<bool>> identifyDevice(String deviceId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.identifyThermostat),
        variables: {
          'input': {
            'id': deviceId,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      return DeviceResult(success: true, data: true);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta il programma attivo
  Future<DeviceResult<int>> setCurrentSchedule(String deviceId, int slot) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setCurrentSchedule),
        variables: {
          'input': {
            'id': deviceId,
            'slot': slot,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final slotResult = result.data?['oneSetCurrentSchedule']['thermostat']['currentSchedule'] as int;
      return DeviceResult(success: true, data: slotResult);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta la programmazione
  Future<DeviceResult<bool>> setSchedules(
      String deviceId,
      int slot,
      Schedule schedule,
      ) async {
    try {
      final schedules = _createScheduleInputFromSchedule(schedule);

      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setSchedules),
        variables: {
          'input': {
            'id': deviceId,
            'slot': slot,
            'schedules': schedules,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      return DeviceResult(success: true, data: true);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Imposta il timezone
  Future<DeviceResult<Timezone>> setTimezone(String deviceId, String timezoneId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(DeviceMutations.setTimezone),
        variables: {
          'input': {
            'id': deviceId,
            'timezoneId': timezoneId,
          },
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return DeviceResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final timezoneData = result.data?['thermostatSetTimezone']['thermostat']['timezone'];
      final timezone = Timezone.fromJson(timezoneData);
      return DeviceResult(success: true, data: timezone);
    } catch (e) {
      return DeviceResult(success: false, error: e.toString());
    }
  }

  // Helper per convertire da Schedule a List<Map<String, dynamic>>
  List<Map<String, dynamic>> _createScheduleInputFromSchedule(Schedule schedule) {
    final List<Map<String, dynamic>> result = [];

    final scheduleMap = schedule.toJson();
    final days = scheduleMap.keys.toList();

    for (final day in days) {
      final dayEnum = day.toUpperCase();
      final hours = scheduleMap[day] as List<bool>;

      result.add({
        'day': dayEnum,
        'hours': hours,
      });
    }

    return result;
  }
}