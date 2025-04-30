// lib/features/device/screens/bluetooth_device_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_manager.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_provider.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text.dart';
import 'package:smart_warmth_2025/features/device/widgets/temperature_control.dart';
import 'package:smart_warmth_2025/features/device/widgets/mode_selector.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';

class BluetoothDeviceScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const BluetoothDeviceScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<BluetoothDeviceScreen> createState() => _BluetoothDeviceScreenState();
}

class _BluetoothDeviceScreenState extends ConsumerState<BluetoothDeviceScreen> {
  double _sliderValue = 19.0;
  bool _isDragging = false;

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  void _disconnect() async {
    final bleManager = ref.read(bleManagerProvider);
    try {
      await bleManager.disconnect();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Errore disconnessione: $e');
    }
  }

  void _showSettingsScreen() {
    context.push('/device-bluetooth-settings/${widget.deviceId}');
  }

  void _handleModeChange(DeviceMode mode) async {
    final bleManager = ref.read(bleManagerProvider);
    final thermostat = bleManager.connectedDevice();

    if (thermostat == null) return;

    try {
      final updatedThermostat = thermostat.copyWith(mode: mode);
      await bleManager.sendCharacteristics(updatedThermostat);
    } catch (e) {
      debugPrint('Errore cambio modalità: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslation('mode_change_error'))),
      );
    }
  }

  void _handleTemperatureChange(double temperature) async {
    final bleManager = ref.read(bleManagerProvider);
    final thermostat = bleManager.connectedDevice();

    if (thermostat == null) return;

    try {
      if (thermostat.mode == DeviceMode.comfort) {
        final updatedThermostat = thermostat.copyWith(comfortTemperature: temperature);
        await bleManager.sendCharacteristics(updatedThermostat);
      } else if (thermostat.mode == DeviceMode.economy) {
        final updatedThermostat = thermostat.copyWith(economyTemperature: temperature);
        await bleManager.sendCharacteristics(updatedThermostat);
      }
    } catch (e) {
      debugPrint('Errore cambio temperatura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslation('temperature_change_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thermostatAsyncValue = ref.watch(bluetoothThermostatProvider);

    return thermostatAsyncValue.when(
      data: (thermostat) {
        if (thermostat == null) {
          // Se non c'è nessun termostato, torna alla home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Aggiorna il valore dello slider in base alla modalità attuale
        if (!_isDragging) {
          if (thermostat.mode == DeviceMode.comfort) {
            _sliderValue = thermostat.comfortTemperature;
          } else if (thermostat.mode == DeviceMode.economy) {
            _sliderValue = thermostat.economyTemperature;
          } else if (thermostat.mode == DeviceMode.antIce) {
            _sliderValue = 7.0;
          } else if (thermostat.mode == DeviceMode.boost) {
            _sliderValue = 30.0;
          }
        }

        return AppScaffold(
          title: thermostat.name,
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _disconnect,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsScreen,
            ),
          ],
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(thermostat.mode, _sliderValue),
                stops: _getGradientStops(_sliderValue),
              ),
            ),
            child: Column(
              children: [
                // Area principale con temperatura e controlli
                Expanded(
                  child: GestureDetector(
                    onVerticalDragStart: (details) {
                      if (thermostat.mode == DeviceMode.comfort ||
                          thermostat.mode == DeviceMode.economy) {
                        setState(() {
                          _isDragging = true;
                        });
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      if (thermostat.mode == DeviceMode.comfort ||
                          thermostat.mode == DeviceMode.economy) {
                        final newTemp = _sliderValue - (details.delta.dy * 0.1);
                        if (newTemp >= 7 && newTemp <= 30) {
                          setState(() {
                            _sliderValue = newTemp;
                          });
                        }
                      }
                    },
                    onVerticalDragEnd: (details) {
                      if (thermostat.mode == DeviceMode.comfort ||
                          thermostat.mode == DeviceMode.economy) {
                        setState(() {
                          _isDragging = false;
                          // Arrotonda a 0.5
                          _sliderValue = ((_sliderValue * 2).round() / 2);
                        });
                        _handleTemperatureChange(_sliderValue);
                      }
                    },
                    child: Center(
                      child: _buildTemperatureDisplay(thermostat),
                    ),
                  ),
                ),

                // Selettore modalità
                ModeSelector(
                  currentMode: thermostat.mode,
                  onModeChanged: _handleModeChange,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Errore: $error'),
        ),
      ),
    );
  }

  Widget _buildTemperatureDisplay(BluetoothThermostat thermostat) {
    // Mostra controlli diversi in base alla modalità
    switch (thermostat.mode) {
      case DeviceMode.comfort:
      case DeviceMode.economy:
        return TemperatureControl(
          temperature: _sliderValue,
          showControls: true,
          onIncrement: () {
            if (_sliderValue < 30) {
              setState(() {
                _sliderValue += 0.5;
              });
              _handleTemperatureChange(_sliderValue);
            }
          },
          onDecrement: () {
            if (_sliderValue > 7) {
              setState(() {
                _sliderValue -= 0.5;
              });
              _handleTemperatureChange(_sliderValue);
            }
          },
        );

      case DeviceMode.standby:
      case DeviceMode.filPilot:
        return TemperatureControl(
          temperature: thermostat.ambientTemperature,
          showControls: false,
        );

      case DeviceMode.antIce:
        return TemperatureControl(
          temperature: 7.0,
          showControls: false,
        );

      case DeviceMode.boost:
        return TemperatureControl(
          temperature: 30.0,
          showControls: false,
          boostMode: true,
          boostRemainingTime: null, // Dovresti ottenere questo dato dal termostato
        );

      case DeviceMode.schedule:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text: _getTranslation('current_program'),
              preset: TextPreset.subheading,
            ),
            const SizedBox(height: 16),
            Text(
              'P${thermostat.schedulerSlot + 1}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    AppText(
                      text: _getTranslation('comfort_temperature'),
                      preset: TextPreset.body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${thermostat.comfortTemperature}°',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                Column(
                  children: [
                    AppText(
                      text: _getTranslation('economy_temperature'),
                      preset: TextPreset.body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${thermostat.economyTemperature}°',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
    }
  }

  List<Color> _getGradientColors(DeviceMode mode, double temperature) {
    // Modalità che hanno un gradiente per la temperatura
    final temperatureModes = [
      DeviceMode.comfort,
      DeviceMode.economy,
      DeviceMode.antIce,
      DeviceMode.boost,
    ];

    if (temperatureModes.contains(mode)) {
      return [
        const Color(0xFF1a2a6c),
        const Color(0xFFb21f1f),
        const Color(0xFFfdbb2d),
      ];
    }

    // Modalità che hanno un colore fisso
    return [
      const Color(0xFF333232),
      const Color(0xFF333232),
      const Color(0xFF333232),
    ];
  }

  List<double>? _getGradientStops(double temperature) {
    const minTemp = 7.0;
    const maxTemp = 30.0;

    return [0, (maxTemp - temperature) / (maxTemp - minTemp), 1];
  }
}