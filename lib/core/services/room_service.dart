// lib/services/room_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/graphql/errors/error_handler.dart';
import 'package:smart_warmth_2025/core/graphql/mutations/room_mutations.dart';


class RoomResult<T> {
  final bool success;
  final T? data;
  final String? error;

  RoomResult({required this.success, this.data, this.error});
}

class RoomService {
  final GraphQLClientService _clientService = GraphQLClientService.instance;

  // Crea una nuova stanza
  Future<RoomResult<String>> createRoom(String name) async {
    try {
      final createRoomInput = {
        'name': name,
      };

      final MutationOptions options = MutationOptions(
        document: gql(RoomMutations.createRoom),
        variables: {
          'input': createRoomInput,
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return RoomResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final roomName = result.data?['createRoom']['name'] as String;
      return RoomResult(success: true, data: roomName);
    } catch (e) {
      return RoomResult(success: false, error: e.toString());
    }
  }

  // Modifica una stanza
  Future<RoomResult<bool>> editRoom({
    required String roomId,
    String? name,
    List<String>? thermostats,
  }) async {
    try {
      final Map<String, dynamic> editRoomInput = {
        'id': roomId,
      };

      if (name != null) editRoomInput['name'] = name;
      if (thermostats != null) editRoomInput['thermostats'] = thermostats;

      final MutationOptions options = MutationOptions(
        document: gql(RoomMutations.editRoom),
        variables: {
          'input': editRoomInput,
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return RoomResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final success = result.data?['editRoom']['success'] as bool;
      return RoomResult(success: success, data: success);
    } catch (e) {
      return RoomResult(success: false, error: e.toString());
    }
  }

  // Elimina una stanza
  Future<RoomResult<bool>> deleteRoom(String roomId) async {
    try {
      final deleteRoomInput = {
        'id': roomId,
      };

      final MutationOptions options = MutationOptions(
        document: gql(RoomMutations.deleteRoom),
        variables: {
          'input': deleteRoomInput,
        },
      );

      final result = await _clientService.client.mutate(options);

      if (result.hasException) {
        return RoomResult(
          success: false,
          error: ErrorHandlerNew.getMessageFromGraphQLError(result.exception?.graphqlErrors),
        );
      }

      final success = result.data?['deleteRoom']['success'] as bool;
      return RoomResult(success: success, data: success);
    } catch (e) {
      return RoomResult(success: false, error: e.toString());
    }
  }
}