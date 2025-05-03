// lib/features/room/models/room_model.dart
import 'package:smart_warmth_2025/core/graphql/models/thermostat_model.dart';

class RoomModel {
  final String id;
  final String name;
  final List<ThermostatModel> thermostats;

  RoomModel({
    required this.id,
    required this.name,
    this.thermostats = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    List<ThermostatModel> devicesList = [];

    if (json['thermostats'] != null) {
      if (json['thermostats'] is List) {
        devicesList = (json['thermostats'] as List)
            .map((device) => ThermostatModel.fromJson(device))
            .toList();
      }
    }

    return RoomModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      thermostats: devicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thermostats': thermostats.map((device) => device.toJson()).toList(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    List<ThermostatModel>? thermostats,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thermostats: thermostats ?? this.thermostats,
    );
  }

  @override
  String toString() {
    return 'RoomModel(id: $id, name: $name, thermostats: $thermostats)';
  }
}

/*
class RoomModel {
  final String id;
  final String name;
  final List<Device> thermostats;

  RoomModel({
    required this.id,
    required this.name,
    required this.thermostats,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Gestisce la lista di termostati dalla risposta API
    final thermostatsJson = json['thermostats'] as List<dynamic>?;
    List<Device> thermostats = [];

    if (thermostatsJson != null) {
      thermostats = thermostatsJson
          .map((device) => Device.fromJson(device))
          .toList();
    }

    return RoomModel(
      id: json['id'],
      name: json['name'],
      thermostats: thermostats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thermostats': thermostats.map((device) => device.toJson()).toList(),
    };
  }

  // Crea una copia del modello con alcune proprietà modificate
  RoomModel copyWith({
    String? id,
    String? name,
    List<Device>? thermostats,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thermostats: thermostats ?? this.thermostats,
    );
  }
}
*/

/*
class RoomModel {
  final String id;
  final String name;
  final List<String> deviceIds;

  RoomModel({
    required this.id,
    required this.name,
    this.deviceIds = const [],
  });

  RoomModel copyWith({
    String? id,
    String? name,
    List<String>? deviceIds,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      name: json['name'],
      deviceIds: List<String>.from(json['deviceIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceIds': deviceIds,
    };
  }
}*/
