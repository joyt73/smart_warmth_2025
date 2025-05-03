// lib/graphql/models/device_model.dart

import 'package:smart_warmth_2025/core/graphql/models/room_model.dart';

enum DeviceMode {
  STANDBY,
  FIL_PILOT,
  COMFORT,
  ECONOMY,
  ANT_ICE,
  SCHEDULE,
  BOOST,
  HOLIDAY,
}

extension DeviceModeExtension on DeviceMode {
  static DeviceMode fromString(String value) {
    return DeviceMode.values.firstWhere(
          (e) => e.toString().split('.').last == value,
      orElse: () => DeviceMode.STANDBY,
    );
  }

  String get displayName {
    switch (this) {
      case DeviceMode.STANDBY:
        return 'Stand by';
      case DeviceMode.FIL_PILOT:
        return 'Filo pilota';
      case DeviceMode.COMFORT:
        return 'Comfort';
      case DeviceMode.ECONOMY:
        return 'Economia';
      case DeviceMode.ANT_ICE:
        return 'Antigelo';
      case DeviceMode.SCHEDULE:
        return 'Programmazione';
      case DeviceMode.BOOST:
        return 'Boost';
      case DeviceMode.HOLIDAY:
        return 'Vacanza';
    }
  }
}

enum DeviceFunction {
  WINDOW,
  CHILDREN,
  KEY_LOCK,
  ASC,
  ECO,
}

extension DeviceFunctionExtension on DeviceFunction {
  static DeviceFunction fromString(String value) {
    return DeviceFunction.values.firstWhere(
          (e) => e.toString().split('.').last == value,
      orElse: () => DeviceFunction.WINDOW,
    );
  }

  String get displayName {
    switch (this) {
      case DeviceFunction.WINDOW:
        return 'Rilevamento finestra';
      case DeviceFunction.CHILDREN:
        return 'Protezione bambini';
      case DeviceFunction.KEY_LOCK:
        return 'Blocco tastiera';
      case DeviceFunction.ASC:
        return 'Controllo adattivo';
      case DeviceFunction.ECO:
        return 'Modalità ECO';
    }
  }
}

enum DayEnum {
  MONDAY,
  TUESDAY,
  WEDNESDAY,
  THURSDAY,
  FRIDAY,
  SATURDAY,
  SUNDAY,
}

class Timezone {
  final String id;
  final String name;

  Timezone({required this.id, required this.name});

  factory Timezone.fromJson(Map<String, dynamic> json) {
    return Timezone(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Device {
  final String id;
  final String name;
  final bool online;
  final String? version;
  final DeviceMode mode;
  final RoomModel? room;
  final double ambientTemperature;
  final double comfortTemperature;
  final double economyTemperature;
  final int boostTime;
  final int boostRemainingTime;
  final int currentSchedule;
  final List<DeviceFunction> functions;
  final int holidayTime;
  final int holidayRemainingTime;
  final Timezone timezone;

  Device({
    required this.id,
    required this.name,
    required this.online,
    this.version,
    required this.mode,
    this.room,
    required this.ambientTemperature,
    required this.comfortTemperature,
    required this.economyTemperature,
    required this.boostTime,
    required this.boostRemainingTime,
    required this.currentSchedule,
    required this.functions,
    required this.holidayTime,
    required this.holidayRemainingTime,
    required this.timezone,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'] ?? 'Device',
      online: json['online'] ?? false,
      version: json['version'],
      mode: DeviceModeExtension.fromString(json['mode']),
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
      ambientTemperature: (json['ambientTemperature'] ?? 0.0).toDouble(),
      comfortTemperature: (json['comfortTemperature'] ?? 20.0).toDouble(),
      economyTemperature: (json['economyTemperature'] ?? 16.0).toDouble(),
      boostTime: json['boostTime'] ?? 0,
      boostRemainingTime: json['boostRemainingTime'] ?? 0,
      currentSchedule: json['currentSchedule'] ?? 0,
      functions: (json['functions'] as List<dynamic>?)
          ?.map((e) => DeviceFunctionExtension.fromString(e))
          .toList() ?? [],
      holidayTime: json['holidayTime'] ?? 0,
      holidayRemainingTime: json['holidayRemainingTime'] ?? 0,
      timezone: json['timezone'] != null
          ? Timezone.fromJson(json['timezone'])
          : Timezone(id: '0', name: 'UTC'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'online': online,
      'version': version,
      'mode': mode,
      'room': room?.toJson(),
      'ambientTemperature': ambientTemperature,
      'comfortTemperature': comfortTemperature,
      'economyTemperature': economyTemperature,
      'boostTime': boostTime,
      'boostRemainingTime': boostRemainingTime,
      'currentSchedule': currentSchedule,
      'functions': functions,
      'holidayTime': holidayTime,
      'holidayRemainingTime': holidayRemainingTime,
      'timezone': timezone,
    };
  }

  // lib/core/graphql/models/device_model.dart
// Aggiungi questo metodo alla classe Device

  Device copyWith({
    String? id,
    String? name,
    bool? online,
    String? version,
    DeviceMode? mode,
    RoomModel? room,
    double? ambientTemperature,
    double? comfortTemperature,
    double? economyTemperature,
    int? boostTime,
    int? boostRemainingTime,
    int? currentSchedule,
    List<DeviceFunction>? functions,
    int? holidayTime,
    int? holidayRemainingTime,
    Timezone? timezone,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      online: online ?? this.online,
      version: version ?? this.version,
      mode: mode ?? this.mode,
      room: room ?? this.room,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      comfortTemperature: comfortTemperature ?? this.comfortTemperature,
      economyTemperature: economyTemperature ?? this.economyTemperature,
      boostTime: boostTime ?? this.boostTime,
      boostRemainingTime: boostRemainingTime ?? this.boostRemainingTime,
      currentSchedule: currentSchedule ?? this.currentSchedule,
      functions: functions ?? this.functions,
      holidayTime: holidayTime ?? this.holidayTime,
      holidayRemainingTime: holidayRemainingTime ?? this.holidayRemainingTime,
      timezone: timezone ?? this.timezone,
    );
  }
}

class Schedule {
  final List<bool> monday;
  final List<bool> tuesday;
  final List<bool> wednesday;
  final List<bool> thursday;
  final List<bool> friday;
  final List<bool> saturday;
  final List<bool> sunday;

  Schedule({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      monday: (json['monday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      tuesday: (json['tuesday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      wednesday: (json['wednesday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      thursday: (json['thursday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      friday: (json['friday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      saturday: (json['saturday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
      sunday: (json['sunday'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? [],
    );
  }

  Map<String, List<bool>> toJson() {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }
}

class Temperature {
  final double value;
  final DateTime createdAt;

  Temperature({required this.value, required this.createdAt});

  factory Temperature.fromJson(Map<String, dynamic> json) {
    return Temperature(
      value: (json['value'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num).toInt(),
      ),
    );
  }
}