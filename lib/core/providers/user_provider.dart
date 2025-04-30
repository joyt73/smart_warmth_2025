// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/services/user_service.dart';
import 'package:smart_warmth_2025/features/auth/models/user_model.dart';
import 'package:smart_warmth_2025/features/room/models/room_model.dart';

// Classe che rappresenta lo stato dell'utente
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier per lo stato dell'utente
class UserStateNotifier extends StateNotifier<UserState> {
  final UserService _userService;

  UserStateNotifier(this._userService) : super(UserState());

  // Ottieni i dati dell'utente
  Future<void> fetchUser() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _userService.getUser();

    if (result.success) {
      state = state.copyWith(
        user: result.data,
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  // Ottieni i timezone disponibili
  Future<UserResult<List<Timezone>>> getTimezones() async {
    return await _userService.getTimezones();
  }

  // Aggiorna i dati dell'utente senza fare una nuova richiesta
  void updateUserData(User user) {
    state = state.copyWith(user: user);
  }

  // Aggiorna un termostato nei dati dell'utente
  void updateThermostat(Device updatedDevice) {
    if (state.user == null) return;

    final updatedThermostats = state.user!.thermostats.map((device) {
      if (device.id == updatedDevice.id) {
        return updatedDevice;
      }
      return device;
    }).toList();

    final updatedRooms = state.user!.rooms.map((room) {
      return room;
    }).toList();

    final updatedUser = User(
      id: state.user!.id,
      displayName: state.user!.displayName,
      email: state.user!.email,
      thermostats: updatedThermostats,
      rooms: updatedRooms,
      timezones: state.user!.timezones,
    );

    state = state.copyWith(user: updatedUser);
  }

  // Rimuovi un termostato dai dati dell'utente
  void removeThermostat(String deviceId) {
    if (state.user == null) return;

    final updatedThermostats = state.user!.thermostats
        .where((device) => device.id != deviceId)
        .toList();

    final updatedRooms = state.user!.rooms.map((room) {
      // Rimuovi il dispositivo anche dalle stanze
      if (room.deviceIds != null && room.deviceIds!.contains(deviceId)) {
        final updatedDeviceIds = room.deviceIds!
            .where((id) => id != deviceId)
            .toList();

        return RoomModel(
          id: room.id,
          name: room.name,
          deviceIds: updatedDeviceIds,
        );
      }
      return room;
    }).toList();

    final updatedUser = User(
      id: state.user!.id,
      displayName: state.user!.displayName,
      email: state.user!.email,
      thermostats: updatedThermostats,
      rooms: updatedRooms,
      timezones: state.user!.timezones,
    );

    state = state.copyWith(user: updatedUser);
  }

  // Aggiungi una stanza ai dati dell'utente
  void addRoom(RoomModel room) {
    if (state.user == null) return;

    final updatedRooms = [...state.user!.rooms, room];

    final updatedUser = User(
      id: state.user!.id,
      displayName: state.user!.displayName,
      email: state.user!.email,
      thermostats: state.user!.thermostats,
      rooms: updatedRooms,
      timezones: state.user!.timezones,
    );

    state = state.copyWith(user: updatedUser);
  }

  // Aggiorna una stanza nei dati dell'utente
  void updateRoom(RoomModel updatedRoom) {
    if (state.user == null) return;

    final updatedRooms = state.user!.rooms.map((room) {
      if (room.id == updatedRoom.id) {
        return updatedRoom;
      }
      return room;
    }).toList();

    final updatedUser = User(
      id: state.user!.id,
      displayName: state.user!.displayName,
      email: state.user!.email,
      thermostats: state.user!.thermostats,
      rooms: updatedRooms,
      timezones: state.user!.timezones,
    );

    state = state.copyWith(user: updatedUser);
  }

  // Rimuovi una stanza dai dati dell'utente
  void removeRoom(String roomId) {
    if (state.user == null) return;

    final updatedRooms = state.user!.rooms
        .where((room) => room.id != roomId)
        .toList();

    final updatedUser = User(
      id: state.user!.id,
      displayName: state.user!.displayName,
      email: state.user!.email,
      thermostats: state.user!.thermostats,
      rooms: updatedRooms,
      timezones: state.user!.timezones,
    );

    state = state.copyWith(user: updatedUser);
  }
}

// Provider per lo stato dell'utente
final userStateProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  final userService = UserService();
  return UserStateNotifier(userService);
});

// Provider per l'UserService
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Provider per l'utente corrente
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userStateProvider).user;
});

// Provider per le stanze dell'utente
final userRoomsProvider = Provider<List<RoomModel>>((ref) {
  final userState = ref.watch(userStateProvider);
  return userState.user?.rooms ?? [];
});

// Provider per i termostati dell'utente
final userThermostatsProvider = Provider<List<Device>>((ref) {
  final userState = ref.watch(userStateProvider);
  return userState.user?.thermostats ?? [];
});

// Provider per i timezone disponibili
final timezonesProvider = Provider<List<Timezone>>((ref) {
  final userState = ref.watch(userStateProvider);
  return userState.user?.timezones ?? [];
});