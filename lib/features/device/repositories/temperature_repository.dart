// lib/features/device/repositories/temperature_repository.dart
import 'package:dio/dio.dart';
import 'package:smart_warmth_2025/features/device/models/temperature_data.dart';

class TemperatureRepository {
  final Dio _dio;
  final _logger = LoggerUtil('TemperatureRepository');

  TemperatureRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<TemperatureData>> getTemperatureData(String deviceId, int daysAgo) async {
    try {
      // Nell'implementazione reale, qui ci sarà una chiamata API
      // Per ora generiamo dati di esempio a scopo dimostrativo
      return _generateMockData(deviceId, daysAgo);
    } catch (e) {
      _logger.error('Errore nel recupero dati temperatura: $e');
      throw Exception('Impossibile recuperare i dati di temperatura: $e');
    }
  }

  List<TemperatureData> _generateMockData(String deviceId, int daysAgo) {
    final List<TemperatureData> data = [];

    // Generazione dati di esempio per la temperatura ambiente
    final DateTime now = DateTime.now();
    final DateTime startDate = now.subtract(Duration(days: daysAgo));

    // Per daysAgo=0 (oggi), generiamo dati ogni 30 minuti
    // Per daysAgo=1 (ieri), dati ogni ora
    // Per daysAgo=7 (ultima settimana), dati ogni 6 ore
    int intervalMinutes = daysAgo == 0 ? 30 : (daysAgo == 1 ? 60 : 360);

    // Generiamo dati per le ultime 24 ore o più
    for (int i = 0; i < 1440 / intervalMinutes; i++) {
      final timestamp = startDate.add(Duration(minutes: i * intervalMinutes));

      // Temperatura ambiente - varia durante la giornata
      double ambientTemp = 20.0 + 2.0 * sin(timestamp.hour / 24.0 * 2 * 3.14159);

      // Aggiungi un po' di rumore casuale
      ambientTemp += (DateTime.now().millisecondsSinceEpoch % 10) / 10 - 0.5;

      data.add(TemperatureData(
        type: 'AMBIENT',
        value: double.parse(ambientTemp.toStringAsFixed(1)),
        timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
      ));

      // Temperature impostate (comfort ed economy) - più costanti
      double comfortTemp = 22.5;
      double economyTemp = 19.0;

      data.add(TemperatureData(
        type: 'COMFORT',
        value: comfortTemp,
        timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
      ));

      data.add(TemperatureData(
        type: 'ECONOMY',
        value: economyTemp,
        timestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
      ));
    }

    return data;
  }

  double sin(double x) {
    // Implementazione semplificata della funzione seno
    // In un'applicazione reale, utilizzerai librerie matematiche
    double result = 0;
    double term = x;
    double factorial = 1;
    double power = x;

    for (int i = 1; i <= 7; i += 2) {
      result += term;
      power *= -x * x;
      factorial *= (i + 1) * (i + 2);
      term = power / factorial;
    }

    return result;
  }
}

class LoggerUtil {
  final String _tag;

  LoggerUtil(this._tag);

  void error(String message) {
    print('[$_tag] ERROR: $message');
  }

  void info(String message) {
    print('[$_tag] INFO: $message');
  }
}