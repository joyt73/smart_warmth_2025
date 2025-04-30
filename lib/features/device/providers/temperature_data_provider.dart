// lib/features/device/providers/temperature_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/features/device/models/temperature_data.dart';
import 'package:smart_warmth_2025/features/device/repositories/temperature_repository.dart';

class TemperatureDataParams {
  final String deviceId;
  final int daysAgo;

  TemperatureDataParams({
    required this.deviceId,
    required this.daysAgo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TemperatureDataParams &&
              runtimeType == other.runtimeType &&
              deviceId == other.deviceId &&
              daysAgo == other.daysAgo;

  @override
  int get hashCode => deviceId.hashCode ^ daysAgo.hashCode;
}

final temperatureRepositoryProvider = Provider<TemperatureRepository>((ref) {
  return TemperatureRepository();
});

final temperatureDataProvider = StateNotifierProvider.family<TemperatureDataNotifier, AsyncValue<List<TemperatureData>>, TemperatureDataParams>((ref, params) {
  final repository = ref.watch(temperatureRepositoryProvider);
  return TemperatureDataNotifier(repository, params);
});

class TemperatureDataNotifier extends StateNotifier<AsyncValue<List<TemperatureData>>> {
  final TemperatureRepository _repository;
  final TemperatureDataParams _params;

  TemperatureDataNotifier(this._repository, this._params) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      state = const AsyncValue.loading();
      final data = await _repository.getTemperatureData(_params.deviceId, _params.daysAgo);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}