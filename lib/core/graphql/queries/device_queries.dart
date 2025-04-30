// lib/graphql/queries/device_queries.dart
class DeviceQueries {
  // Query per ottenere i dettagli di un termostato
  static String thermostat = r'''
    query ThermostatQuery($id: ID!) {
      viewer {
        thermostat(id: $id) {
          id
          online
          ... on OneThermostat {
            name
            functions
            mode
            ambientTemperature
            comfortTemperature
            economyTemperature
            boostTime
            boostRemainingTime
            currentSchedule
            timezone {
              id
              name
            }
          }
        }
      }
    }
  ''';

  // Query per ottenere la programmazione di un termostato
  static String deviceProgramming = r'''
    query GetProgramming($nodeId: ID!, $slot: Int!) {
      node(id: $nodeId) {
        ... on OneThermostat {
          schedule(slot: $slot) {
            monday
            tuesday
            wednesday
            thursday
            friday
            saturday
            sunday
          }
        }
      }
    }
  ''';

  // Query per ottenere i dati di temperatura
  static String temperatures = r'''
    query TemperaturesQuery($id: ID!, $from: Float!, $to: Float!) {
      node(id: $id) {
        ... on OneThermostat {
          id
          name
          ambientTemperatures(from: $from, to: $to) {
            value
            createdAt
          }
          economyTemperatures(from: $from, to: $to) {
            value
            createdAt
          }
          comfortTemperatures(from: $from, to: $to) {
            value
            createdAt
          }
        }
      }
    }
  ''';

  // Correggi questa query con frammenti inline appropriati
  static const String viewerWithDevices = '''
  query ViewerWithDevices {
    viewer {
      id
      thermostats {
        edges {
          node {
            id
            ... on OneThermostat {
              name
              online
              mode
              ambientTemperature
              comfortTemperature
              economyTemperature
              boostTime
              boostRemainingTime
              currentSchedule
              functions
              holidayTime
              holidayRemainingTime
              timezone {
                id
                name
              }
            }
          }
        }
      }
    }
  }
  ''';
}