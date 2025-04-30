// lib/features/device/repositories/device_repository.dart
import 'package:dio/dio.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final Dio _dio;

  DeviceRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<DeviceModel>> getDevices() async {
    try {
      // Nella versione reale, questa sarebbe una chiamata API
      // Per ora, restituiamo dati di esempio
      return [
        DeviceModel(
          id: '1',
          name: 'Termostato Soggiorno',
          online: true,
          type: DeviceType.wifi,
          mode: DeviceMode.comfort,
          ambientTemperature: 22.5,
          comfortTemperature: 23.0,
          economyTemperature: 19.0,
        ),
        DeviceModel(
          id: '2',
          name: 'Termostato Camera',
          online: true,
          type: DeviceType.bluetooth,
          mode: DeviceMode.economy,
          ambientTemperature: 20.0,
          comfortTemperature: 22.0,
          economyTemperature: 18.0,
        ),
      ];
    } catch (e) {
      throw Exception('Impossibile caricare i dispositivi: $e');
    }
  }

  Future<DeviceModel> addDevice(DeviceModel device) async {
    try {
      // Simulazione di chiamata API
      return device.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    } catch (e) {
      throw Exception('Impossibile aggiungere il dispositivo: $e');
    }
  }

  Future<void> updateDevice(DeviceModel device) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile aggiornare il dispositivo: $e');
    }
  }

  Future<void> removeDevice(String id) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile rimuovere il dispositivo: $e');
    }
  }

  Future<void> setDeviceMode(String id, DeviceMode mode) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile impostare la modalità: $e');
    }
  }

  Future<void> setComfortTemperature(String id, double temperature) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile impostare la temperatura comfort: $e');
    }
  }

  Future<void> setEconomyTemperature(String id, double temperature) async {
    try {
      // Simulazione di chiamata API
    } catch (e) {
      throw Exception('Impossibile impostare la temperatura economy: $e');
    }
  }
}