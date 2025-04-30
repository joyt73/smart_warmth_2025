// lib/graphql/queries/user_queries.dart
class UserQueries {
  // Query per ottenere i dati dell'utente
  static String viewer = r'''
    query Viewer {
      viewer {
        id
        displayName
        email
        thermostats {
          edges {
            node {
              id
              name
              online
              ... on OneThermostat {
                mode
                comfortTemperature
                ambientTemperature
                economyTemperature
                functions
                timezone {
                  id
                  name
                }
              }
            }
          }
        }
        rooms {
          id
          name
          thermostats {
            ... on OneThermostat {
              id
              name
              online
              mode
              comfortTemperature
              ambientTemperature
              economyTemperature
            }
          }
        }
        timezones {
          id
          name
        }
      }
    }
  ''';

  // Query per ottenere i timezone
  static String timezones = r'''
    query TimezonesQuery {
      viewer {
        timezones {
          id
          name
        }
      }
    }
  ''';
}