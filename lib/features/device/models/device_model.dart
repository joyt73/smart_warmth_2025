// lib/features/device/models/device_model.dart
import 'package:flutter/foundation.dart';

enum DeviceType {
  wifi,
  bluetooth
}

enum DeviceMode {
  standby,
  comfort,
  economy,
  antIce,
  boost,
  schedule,
  holiday,
  filPilot
}

class DeviceModel {
  final String id;
  final String name;
  final bool online;
  final DeviceType type;
  final DeviceMode mode;
  final double ambientTemperature;
  final double comfortTemperature;
  final double economyTemperature;
  final int boostRemainingTime;
  final int boostTime;
  final int currentSchedule;
  final List<String> functions;
  final String roomId;
  final String version;

  DeviceModel({
    required this.id,
    required this.name,
    required this.online,
    required this.type,
    this.mode = DeviceMode.standby,
    this.ambientTemperature = 0.0,
    this.comfortTemperature = 20.0,
    this.economyTemperature = 18.0,
    this.boostRemainingTime = 0,
    this.boostTime = 0,
    this.currentSchedule = 0,
    this.functions = const [],
    this.roomId = '',
    this.version = '',
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    bool? online,
    DeviceType? type,
    DeviceMode? mode,
    double? ambientTemperature,
    double? comfortTemperature,
    double? economyTemperature,
    int? boostRemainingTime,
    int? boostTime,
    int? currentSchedule,
    List<String>? functions,
    String? roomId,
    String? version,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      online: online ?? this.online,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      comfortTemperature: comfortTemperature ?? this.comfortTemperature,
      economyTemperature: economyTemperature ?? this.economyTemperature,
      boostRemainingTime: boostRemainingTime ?? this.boostRemainingTime,
      boostTime: boostTime ?? this.boostTime,
      currentSchedule: currentSchedule ?? this.currentSchedule,
      functions: functions ?? this.functions,
      roomId: roomId ?? this.roomId,
      version: version ?? this.version,
    );
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      online: json['online'] ?? false,
      type: json['type'] == 'wifi' ? DeviceType.wifi : DeviceType.bluetooth,
      mode: _parseMode(json['mode']),
      ambientTemperature: (json['ambientTemperature'] ?? 0.0).toDouble(),
      comfortTemperature: (json['comfortTemperature'] ?? 20.0).toDouble(),
      economyTemperature: (json['economyTemperature'] ?? 18.0).toDouble(),
      boostRemainingTime: json['boostRemainingTime'] ?? 0,
      boostTime: json['boostTime'] ?? 0,
      currentSchedule: json['currentSchedule'] ?? 0,
      functions: List<String>.from(json['functions'] ?? []),
      roomId: json['roomId'] ?? '',
      version: json['version'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'online': online,
      'type': type == DeviceType.wifi ? 'wifi' : 'bluetooth',
      'mode': _modeToString(mode),
      'ambientTemperature': ambientTemperature,
      'comfortTemperature': comfortTemperature,
      'economyTemperature': economyTemperature,
      'boostRemainingTime': boostRemainingTime,
      'boostTime': boostTime,
      'currentSchedule': currentSchedule,
      'functions': functions,
      'roomId': roomId,
      'version': version,
    };
  }

  static DeviceMode _parseMode(String? mode) {
    if (mode == null) return DeviceMode.standby;

    switch (mode) {
      case 'STANDBY':
        return DeviceMode.standby;
      case 'COMFORT':
        return DeviceMode.comfort;
      case 'ECONOMY':
        return DeviceMode.economy;
      case 'ANT_ICE':
        return DeviceMode.antIce;
      case 'BOOST':
        return DeviceMode.boost;
      case 'SCHEDULE':
        return DeviceMode.schedule;
      case 'HOLIDAY':
        return DeviceMode.holiday;
      case 'FIL_PILOT':
        return DeviceMode.filPilot;
      default:
        return DeviceMode.standby;
    }
  }

  static String _modeToString(DeviceMode mode) {
    switch (mode) {
      case DeviceMode.standby:
        return 'STANDBY';
      case DeviceMode.comfort:
        return 'COMFORT';
      case DeviceMode.economy:
        return 'ECONOMY';
      case DeviceMode.antIce:
        return 'ANT_ICE';
      case DeviceMode.boost:
        return 'BOOST';
      case DeviceMode.schedule:
        return 'SCHEDULE';
      case DeviceMode.holiday:
        return 'HOLIDAY';
      case DeviceMode.filPilot:
        return 'FIL_PILOT';
      default:
        return 'STANDBY';
    }
  }
}