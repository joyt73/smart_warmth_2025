// lib/features/room/repositories/room_repository.dart
import 'package:dio/dio.dart';
import '../models/room_model.dart';

class RoomRepository {
  final Dio _dio;

  RoomRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<RoomModel>> getRooms() async {
    try {
      // Simulazione di chiamata API
      return [
        RoomModel(
          id: '1',
          name: 'Soggiorno',
          deviceIds: ['1'],
        ),
        RoomModel(
          id: '2',
          name: 'Camera da letto',
          deviceIds: ['2'],
        ),
      ];
    } catch (e) {
      throw Exception('Impossibile caricare le stanze: $e');
    }
  }

  Future<RoomModel> addRoom(RoomModel room) async {
    try {
      // Simulazione di chiamata API
      return room.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    } catch (e) {
      throw Exception('Impossibile aggiungere la stanza: $e');
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile aggiornare la stanza: $e');
    }
  }

  Future<void> removeRoom(String id) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile rimuovere la stanza: $e');
    }
  }

  Future<void> addDeviceToRoom(String roomId, String deviceId) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile aggiungere il dispositivo alla stanza: $e');
    }
  }

  Future<void> removeDeviceFromRoom(String roomId, String deviceId) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile rimuovere il dispositivo dalla stanza: $e');
    }
  }
}