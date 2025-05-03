class ThermostatModel {
  final String id;
  final String name;
  final bool online;
  final String mode;
  final double ambientTemperature;
  final double comfortTemperature;
  final double economyTemperature;
  final int currentSchedule;
  final List<String> functions;

  ThermostatModel({
    required this.id,
    required this.name,
    this.online = false,
    this.mode = 'STANDBY',
    this.ambientTemperature = 0.0,
    this.comfortTemperature = 20.0,
    this.economyTemperature = 18.0,
    this.currentSchedule = 0,
    this.functions = const [],
  });

  factory ThermostatModel.fromJson(Map<String, dynamic> json) {
    // Gestione delle funzioni
    List<String> functionsList = [];
    if (json['functions'] != null) {
      if (json['functions'] is List) {
        functionsList = (json['functions'] as List).cast<String>();
      }
    }

    return ThermostatModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      online: json['online'] ?? false,
      mode: json['mode'] ?? 'STANDBY',
      ambientTemperature: _parseDouble(json['ambientTemperature']) ?? 0.0,
      comfortTemperature: _parseDouble(json['comfortTemperature']) ?? 20.0,
      economyTemperature: _parseDouble(json['economyTemperature']) ?? 18.0,
      currentSchedule: json['currentSchedule'] ?? 0,
      functions: functionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'online': online,
      'mode': mode,
      'ambientTemperature': ambientTemperature,
      'comfortTemperature': comfortTemperature,
      'economyTemperature': economyTemperature,
      'currentSchedule': currentSchedule,
      'functions': functions,
    };
  }

  ThermostatModel copyWith({
    String? id,
    String? name,
    bool? online,
    String? mode,
    double? ambientTemperature,
    double? comfortTemperature,
    double? economyTemperature,
    int? currentSchedule,
    List<String>? functions,
  }) {
    return ThermostatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      online: online ?? this.online,
      mode: mode ?? this.mode,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      comfortTemperature: comfortTemperature ?? this.comfortTemperature,
      economyTemperature: economyTemperature ?? this.economyTemperature,
      currentSchedule: currentSchedule ?? this.currentSchedule,
      functions: functions ?? this.functions,
    );
  }

  @override
  String toString() {
    return 'ThermostatModel(id: $id, name: $name, online: $online, mode: $mode)';
  }

  // Helper per il parsing dei valori double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}