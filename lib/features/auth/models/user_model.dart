import 'package:smart_warmth_2025/core/graphql/models/device_model.dart';
import 'package:smart_warmth_2025/core/graphql/models/room_model.dart';

class User {
  final String id;
  final String displayName;
  final String email;
  final List<Device> thermostats;
  final List<RoomModel> rooms;
  final List<Timezone> timezones;

  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.thermostats,
    required this.rooms,
    required this.timezones,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Estrai i termostati
    final thermostatsJson = json['thermostats']?['edges'] as List<dynamic>?;
    List<Device> thermostats = [];

    if (thermostatsJson != null) {
      thermostats = thermostatsJson
          .where((edge) => edge['node'] != null)
          .map((edge) => Device.fromJson(edge['node']))
          .toList();
    }

    // Estrai le stanze
    final roomsJson = json['rooms'] as List<dynamic>?;
    List<RoomModel> rooms = [];

    if (roomsJson != null) {
      rooms = roomsJson.map((room) => RoomModel.fromJson(room)).toList();
    }

    // Estrai i timezone
    final timezonesJson = json['timezones'] as List<dynamic>?;
    List<Timezone> timezones = [];

    if (timezonesJson != null) {
      timezones = timezonesJson
          .where((timezone) => timezone != null)
          .map((timezone) => Timezone.fromJson(timezone))
          .toList();
    }

    return User(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      thermostats: thermostats,
      rooms: rooms,
      timezones: timezones,
    );
  }
}

class DeleteAccountInput {
  final String id;

  DeleteAccountInput({required this.id});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}

class DeleteAccountResponse {
  final bool success;

  DeleteAccountResponse({required this.success});

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponse(
      success: json['success'],
    );
  }
}

/*
class UserModel {
  final String id;
  final String username;
  final String email;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}*/
