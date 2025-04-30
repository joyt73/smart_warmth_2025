// lib/core/graphql/queries/room_queries.dart

class RoomQueries {
  // Altre query esistenti...

  static const String viewerWithRooms = '''
  query ViewerWithRooms {
    viewer {
      id
      rooms {
        id
        name
        thermostats {
          id
          ... on OneThermostat {
            name
            online
            mode
            comfortTemperature
            ambientTemperature
            economyTemperature
          }
        }
      }
    }
  }
  ''';
}