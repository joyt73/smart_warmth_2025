// lib/features/device/models/temperature_data.dart
import 'package:flutter/foundation.dart';

class TemperatureData {
  final String type;
  final double value;
  final int timestamp;

  TemperatureData({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'TemperatureData{type: $type, value: $value, timestamp: $timestamp}';
  }
}