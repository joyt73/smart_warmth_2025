// lib/core/providers/room_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/services/room_service.dart';
import 'package:smart_warmth_2025/features/room/models/room_model.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});

// Provider per la lista di stanze con supporto per stati asincroni
final roomsProvider = StateNotifierProvider<RoomsNotifier, List<RoomModel>>((ref) {
  final roomService = ref.watch(roomServiceProvider);
  return RoomsNotifier(roomService);
});

class RoomsNotifier extends StateNotifier<List<RoomModel>> {
  final RoomService _roomService;
  bool _isLoading = false;

  RoomsNotifier(this._roomService) : super([]) {
    refreshRooms();
  }

  Future<void> refreshRooms() async {
    if (_isLoading) return;

    _isLoading = true;
    try {
      final rooms = await _roomService.fetchRooms();
      state = rooms;
    } catch (e) {
      // Gestisci l'errore ma mantieni lo stato corrente
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> addRoom(String name) async {
    try {
      final newRoom = await _roomService.createRoom(name);

      if (newRoom != null) {
        // Aggiorna lo stato con la nuova stanza
        state = [...state, newRoom];
        return true;
      }
      return false;
    } catch (e) {
      // Gestisci l'errore e mantieni lo stato attuale
      return false;
    }
  }

  Future<bool> deleteRoom(String roomId) async {
    try {
      final success = await _roomService.deleteRoom(roomId);

      if (success) {
        // Rimuovi la stanza dallo stato
        state = state.where((room) => room.id != roomId).toList();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRoomName(String roomId, String name) async {
    // Metodo per aggiornare il nome della stanza
    // Da implementare se necessario
    return false;
  }

  Future<bool> addDeviceToRoom(String roomId, String deviceId) async {
    try {
      final success = await _roomService.addDeviceToRoom(roomId, deviceId);

      if (success) {
        // Ricarica le stanze per ottenere i dati aggiornati
        await refreshRooms();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeDeviceFromRoom(String roomId, String deviceId) async {
    try {
      final success = await _roomService.removeDeviceFromRoom(roomId, deviceId);

      if (success) {
        // Ricarica le stanze per ottenere i dati aggiornati
        await refreshRooms();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Metodo per trovare una stanza per ID
  RoomModel? findRoomById(String roomId) {
    try {
      return state.firstWhere((room) => room.id == roomId);
    } catch (e) {
      return null;
    }
  }

  // Metodo per controllare tutti i dispositivi in una stanza (accendere/spegnere)
  Future<bool> controlAllDevicesInRoom(String roomId, bool turnOn) async {
    try {
      final room = findRoomById(roomId);
      if (room == null) return false;

      // Implementazione effettiva da completare una volta definita l'API
      // In questo caso, dovrebbe chiamare il servizio appropriato per ogni dispositivo

      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider per ottenere una stanza specifica per ID
final roomByIdProvider = Provider.family<RoomModel?, String>((ref, roomId) {
  final rooms = ref.watch(roomsProvider);
  try {
    return rooms.firstWhere((room) => room.id == roomId);
  } catch (e) {
    return null;
  }
});