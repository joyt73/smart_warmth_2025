// lib/providers/room_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/services/room_service.dart';
import 'package:smart_warmth_2025/features/room/models/room_model.dart';
import 'user_provider.dart';

// Provider per il RoomService
final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});

// Azioni per le stanze
class RoomActions {
  final RoomService _roomService;
  final UserStateNotifier _userStateNotifier;

  RoomActions(this._roomService, this._userStateNotifier);

  // Crea una nuova stanza
  Future<RoomResult<String>> createRoom(String name) async {
    final result = await _roomService.createRoom(name);

    if (result.success && result.data != null) {
      // Aggiorniamo la lista delle stanze dopo che la creazione è avvenuta con successo
      // Non possiamo farlo qui direttamente perché non conosciamo l'ID della stanza
      // Dovremo fare un refresh dei dati dell'utente
      await _userStateNotifier.fetchUser();
    }

    return result;
  }

  // Modifica una stanza
  Future<RoomResult<bool>> editRoom({
    required String roomId,
    String? name,
    List<String>? thermostats,
  }) async {
    final result = await _roomService.editRoom(
      roomId: roomId,
      name: name,
      thermostats: thermostats,
    );

    if (result.success && result.data != null) {
      // Se abbiamo il nome da aggiornare, possiamo farlo localmente
      if (name != null) {
        // Trova la stanza corrente
        final currentRooms = _userStateNotifier.state.user?.rooms ?? [];
        final roomIndex = currentRooms.indexWhere((room) => room.id == roomId);

        if (roomIndex >= 0) {
          final room = currentRooms[roomIndex];
          final updatedRoom = RoomModel(
            id: room.id,
            name: name,
            deviceIds: room.deviceIds,
          );

          _userStateNotifier.updateRoom(updatedRoom);
        }
      } else {
        // Se stiamo aggiornando i dispositivi, è meglio aggiornare tutto
        await _userStateNotifier.fetchUser();
      }
    }

    return result;
  }

  // Elimina una stanza
  Future<RoomResult<bool>> deleteRoom(String roomId) async {
    final result = await _roomService.deleteRoom(roomId);

    if (result.success && result.data != null) {
      _userStateNotifier.removeRoom(roomId);
    }

    return result;
  }
}

// Provider per le azioni delle stanze
final roomActionsProvider = Provider<RoomActions>((ref) {
  final roomService = ref.watch(roomServiceProvider);
  final userNotifier = ref.watch(userStateProvider.notifier);
  return RoomActions(roomService, userNotifier);
});

// Provider per ottenere una stanza specifica per ID
final roomByIdProvider = Provider.family<RoomModel?, String>((ref, roomId) {
  final rooms = ref.watch(userRoomsProvider);
  return rooms.firstWhere((room) => room.id == roomId, orElse: () => null!);
});

// Provider per i dispositivi in una stanza
final devicesInRoomProvider = Provider.family<List<String>, String>((ref, roomId) {
  final room = ref.watch(roomByIdProvider(roomId));
  return room?.deviceIds ?? [];
});