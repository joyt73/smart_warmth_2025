// lib/features/room/providers/room_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

final roomsProvider = StateNotifierProvider<RoomsNotifier, List<RoomModel>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return RoomsNotifier(repository);
});

class RoomsNotifier extends StateNotifier<List<RoomModel>> {
  final RoomRepository _repository;

  RoomsNotifier(this._repository) : super([]) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      final rooms = await _repository.getRooms();
      state = rooms;
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> addRoom(RoomModel room) async {
    try {
      final newRoom = await _repository.addRoom(room);
      state = [...state, newRoom];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    try {
      await _repository.updateRoom(room);
      state = [
        for (final r in state)
          if (r.id == room.id) room else r,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> removeRoom(String id) async {
    try {
      await _repository.removeRoom(id);
      state = [
        for (final room in state)
          if (room.id != id) room,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> addDeviceToRoom(String roomId, String deviceId) async {
    try {
      await _repository.addDeviceToRoom(roomId, deviceId);
      state = [
        for (final room in state)
          if (room.id == roomId)
            room.copyWith(deviceIds: [...room.deviceIds, deviceId])
          else
            room,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }

  Future<void> removeDeviceFromRoom(String roomId, String deviceId) async {
    try {
      await _repository.removeDeviceFromRoom(roomId, deviceId);
      state = [
        for (final room in state)
          if (room.id == roomId)
            room.copyWith(
              deviceIds: [
                for (final id in room.deviceIds)
                  if (id != deviceId) id,
              ],
            )
          else
            room,
      ];
    } catch (e) {
      // Gestione degli errori
    }
  }
}