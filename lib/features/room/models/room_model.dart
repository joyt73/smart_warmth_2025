// lib/features/room/models/room_model.dart
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
}