// lib/graphql/mutations/room_mutations.dart
class RoomMutations {
  // Mutation per creare una stanza
  static String createRoom = r'''
    mutation CreateRoom($input: CreateRoomInput!) {
      createRoom(input: $input) {
        name
      }
    }
  ''';

  // Mutation per modificare una stanza
  static String editRoom = r'''
    mutation EditRoom($input: EditRoomInput!) {
      editRoom(input: $input) {
        success
      }
    }
  ''';

  // Mutation per eliminare una stanza
  static String deleteRoom = r'''
    mutation DeleteRoom($input: DeleteRoomInput!) {
      deleteRoom(input: $input) {
        success
      }
    }
  ''';
}