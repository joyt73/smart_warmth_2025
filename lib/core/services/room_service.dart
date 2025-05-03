// lib/core/services/room_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/graphql/errors/error_handler.dart';
import 'package:smart_warmth_2025/core/graphql/mutations/room_mutations.dart';
import 'package:smart_warmth_2025/core/graphql/queries/room_queries.dart';
import 'package:smart_warmth_2025/core/graphql/models/room_model.dart';

class RoomService {
  final GraphQLClientService _clientService = GraphQLClientService.instance;


  // Recupera tutte le stanze dell'utente
  Future<List<RoomModel>> fetchRooms() async {
    try {
      final result = await _clientService.client.query(
        QueryOptions(
          document: gql(RoomQueries.viewerWithRooms),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      final roomsData = result.data?['viewer']['rooms'] as List<dynamic>?;
      if (roomsData == null) {
        return [];
      }

      return roomsData.map((room) => RoomModel.fromJson(room)).toList();
    } catch (e) {
      throw Exception('Errore durante il recupero delle stanze: ${e.toString()}');
    }
  }

  // Crea una nuova stanza
  Future<RoomModel?> createRoom(String name) async {
    try {
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(RoomMutations.createRoom),
          variables: {
            'input': {
              'name': name,
            },
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      // Poiché la risposta potrebbe non contenere tutte le informazioni necessarie,
      // ricarica tutte le stanze
      final rooms = await fetchRooms();
      final newRoom = rooms.firstWhere(
            (room) => room.name == name,
        orElse: () => throw Exception('Stanza creata ma non trovata'),
      );

      return newRoom;
    } catch (e) {
      throw Exception('Errore durante la creazione della stanza: ${e.toString()}');
    }
  }

  // Aggiungere questo metodo nel file room_service.dart
  Future<bool> updateRoomName(String roomId, String name) async {
    try {
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(RoomMutations.editRoom),
          variables: {
            'input': {
              'id': roomId,
              'name': name,
            },
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      final success = result.data?['editRoom']['success'] as bool? ?? false;
      return success;
    } catch (e) {
      throw Exception('Errore durante l\'aggiornamento del nome della stanza: ${e.toString()}');
    }
  }

  // Elimina una stanza
  Future<bool> deleteRoom(String roomId) async {
    try {
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(RoomMutations.deleteRoom),
          variables: {
            'input': {
              'id': roomId,
            },
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      final success = result.data?['deleteRoom']['success'] as bool? ?? false;
      return success;
    } catch (e) {
      throw Exception('Errore durante l\'eliminazione della stanza: ${e.toString()}');
    }
  }

  // Aggiunge un dispositivo a una stanza
  Future<bool> addDeviceToRoom(String roomId, String deviceId) async {
    try {
      // Prima recuperiamo la stanza per ottenere l'elenco attuale dei dispositivi
      final rooms = await fetchRooms();
      final room = rooms.firstWhere(
            (room) => room.id == roomId,
        orElse: () => throw Exception('Stanza non trovata'),
      );

      // Otteniamo tutti gli ID dei dispositivi attuali e aggiungiamo il nuovo
      final List<String> deviceIds = room.thermostats.map((device) => device.id).toList();
      if (!deviceIds.contains(deviceId)) {
        deviceIds.add(deviceId);
      }

      // Inviamo la richiesta di aggiornamento
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(RoomMutations.editRoom),
          variables: {
            'input': {
              'id': roomId,
              'thermostats': deviceIds,
            },
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      final success = result.data?['editRoom']['success'] as bool? ?? false;
      return success;
    } catch (e) {
      throw Exception('Errore durante l\'aggiunta del dispositivo alla stanza: ${e.toString()}');
    }
  }

  // Rimuove un dispositivo da una stanza
  Future<bool> removeDeviceFromRoom(String roomId, String deviceId) async {
    try {
      // Prima recuperiamo la stanza per ottenere l'elenco attuale dei dispositivi
      final rooms = await fetchRooms();
      final room = rooms.firstWhere(
            (room) => room.id == roomId,
        orElse: () => throw Exception('Stanza non trovata'),
      );

      // Rimuoviamo il dispositivo dall'elenco
      final List<String> deviceIds = room.thermostats
          .map((device) => device.id)
          .where((id) => id != deviceId)
          .toList();

      // Inviamo la richiesta di aggiornamento
      final result = await _clientService.client.mutate(
        MutationOptions(
          document: gql(RoomMutations.editRoom),
          variables: {
            'input': {
              'id': roomId,
              'thermostats': deviceIds,
            },
          },
        ),
      );

      if (result.hasException) {
        final error = ErrorHandlerNew.getMessageFromGraphQLError(
          result.exception?.graphqlErrors,
        );
        throw Exception(error);
      }

      final success = result.data?['editRoom']['success'] as bool? ?? false;
      return success;
    } catch (e) {
      throw Exception('Errore durante la rimozione del dispositivo dalla stanza: ${e.toString()}');
    }
  }
}