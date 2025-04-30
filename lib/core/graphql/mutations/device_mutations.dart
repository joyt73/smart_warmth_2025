// lib/graphql/mutations/device_mutations.dart
class DeviceMutations {
  // Mutation per registrare un nuovo termostato
  static String registerThermostat = r'''
    mutation ThermostatRegister($input: ThermostatRegisterInput!) {
      thermostatRegister(input: $input) {
        thermostat {
          id
          name
          online
          version
          ... on OneThermostat {
            ambientTemperature
            boostRemainingTime
            comfortTemperature
            boostTime
            currentSchedule
            economyTemperature
            functions
            holidayRemainingTime
            holidayTime
            id
            mode
            name
            online
            version
          }
        }
      }
    }
  ''';

  // Mutation per modificare il nome di un termostato
  static String setThermostatName = r'''
    mutation ThermostatSetName($input: ThermostatSetNameInput!) {
      thermostatSetName(input: $input) {
        thermostat {
          id
        }
      }
    }
  ''';

  // Mutation per rimuovere un termostato
  static String removeThermostat = r'''
    mutation ThermostatRemove($input: ThermostatRemoveInput!) {
      thermostatRemove(input: $input) {
        thermostat {
          id
        }
      }
    }
  ''';

  // Mutation per impostare la modalità
  static String setMode = r'''
    mutation OneSetMode($input: OneSetModeInput!) {
      oneSetMode(input: $input) {
        thermostat {
          id
          mode
        }
      }
    }
  ''';

  // Mutation per impostare le funzioni
  static String setFunctions = r'''
    mutation OneSetFunctions($input: OneSetFunctionsInput!) {
      oneSetFunctions(input: $input) {
        thermostat {
          id
          functions
        }
      }
    }
  ''';

  // Mutation per impostare la temperatura comfort
  static String setComfortTemperature = r'''
    mutation OneSetComfortTemperature($input: OneSetComfortTemperatureInput!) {
      oneSetComfortTemperature(input: $input) {
        thermostat {
          id
          comfortTemperature
        }
      }
    }
  ''';

  // Mutation per impostare la temperatura economy
  static String setEconomyTemperature = r'''
    mutation OneSetEconomyTemperature($input: OneSetEconomyTemperatureInput!) {
      oneSetEconomyTemperature(input: $input) {
        thermostat {
          id
          economyTemperature
        }
      }
    }
  ''';

  // Mutation per inviare un ping al termostato
  static String identifyThermostat = r'''
    mutation ThermostatIdentify($input: ThermostatIdentifyInput!) {
      thermostatIdentify(input: $input) {
        thermostat {
          id
        }
      }
    }
  ''';

  // Mutation per impostare il programma attivo
  static String setCurrentSchedule = r'''
    mutation OneSetCurrentSchedule($input: OneSetCurrentScheduleInput!) {
      oneSetCurrentSchedule(input: $input) {
        thermostat {
          id
          currentSchedule
        }
      }
    }
  ''';

  // Mutation per impostare il tempo della modalità vacanza
  static String setHolidayTime = r'''
    mutation OneSetHolidayTime($input: OneSetHolidayTimeInput!) {
      oneSetHolidayTime(input: $input) {
        thermostat {
          id
          holidayTime
        }
      }
    }
  ''';

  // Mutation per impostare la programmazione
  static String setSchedules = r'''
    mutation OneSetSchedules($input: OneSetSchedulesInput!) {
      oneSetSchedules(input: $input) {
        thermostat {
          id
          currentSchedule
        }
      }
    }
  ''';

  // Mutation per impostare il timezone
  static String setTimezone = r'''
    mutation ThermostatSetTimezone($input: ThermostatSetTimezoneInput!) {
      thermostatSetTimezone(input: $input) {
        thermostat {
          id
          timezone {
            id
            name
          }
        }
      }
    }
  ''';
}
