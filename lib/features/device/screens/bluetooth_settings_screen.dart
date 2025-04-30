// lib/features/device/screens/bluetooth_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_manager.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_provider.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/settings_item.dart';

class BluetoothSettingsScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const BluetoothSettingsScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends ConsumerState<BluetoothSettingsScreen> {
  final _nameController = TextEditingController();
  bool _waitingForOperation = false;

  @override
  void initState() {
    super.initState();

    final thermostat = ref.read(bleManagerProvider).connectedDevice();
    if (thermostat != null) {
      _nameController.text = thermostat.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('delete_device')),
        content: Text(_getTranslation('delete_device_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getTranslation('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDevice();
            },
            child: Text(_getTranslation('delete')),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteDevice() async {
    // Qui dovremmo implementare la rimozione dal database locale

    // Per ora, disconnettiamo il dispositivo
    setState(() {
      _waitingForOperation = true;
    });

    try {
      final bleManager = ref.read(bleManagerProvider);
      await bleManager.disconnect();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Errore eliminazione: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslation('delete_failed'))),
        );

        setState(() {
          _waitingForOperation = false;
        });
      }
    }
  }

  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _waitingForOperation = true;
    });

    try {
      // Aggiorna il nome nel database locale
      // Per ora, simuliamo il successo

      setState(() {
        _waitingForOperation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslation('device_updated'))),
        );
      }
    } catch (e) {
      debugPrint('Errore aggiornamento: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslation('update_failed'))),
        );

        setState(() {
          _waitingForOperation = false;
        });
      }
    }
  }

  void _toggleDeviceFunction(DeviceFunction function) async {
    final bleManager = ref.read(bleManagerProvider);
    final thermostat = bleManager.connectedDevice();

    if (thermostat == null) return;

    setState(() {
      _waitingForOperation = true;
    });

    try {
      final newFunctions = List<DeviceFunction>.from(thermostat.functionValues);

      if (newFunctions.contains(function)) {
        newFunctions.remove(function);
      } else {
        newFunctions.add(function);
      }

      final updatedThermostat = thermostat.copyWith(
        functionValues: newFunctions,
      );

      await bleManager.sendCharacteristics(updatedThermostat);

      setState(() {
        _waitingForOperation = false;
      });
    } catch (e) {
      debugPrint('Errore cambio funzione: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslation('update_failed'))),
        );

        setState(() {
          _waitingForOperation = false;
        });
      }
    }
  }

  void _openProgrammingScreen() {
    final thermostat = ref.read(bleManagerProvider).connectedDevice();
    if (thermostat == null) return;

    context.push('/device-bluetooth-programming/${widget.deviceId}');
  }

  void _sendPingToDevice() async {
    // In una implementazione reale, invieremmo un comando al termostato
    // Per ora, simuliamo il successo

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getTranslation('device_ping_sent'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thermostatAsyncValue = ref.watch(bluetoothThermostatProvider);

    return thermostatAsyncValue.when(
      data: (thermostat) {
        if (thermostat == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
          return const Center(child: CircularProgressIndicator());
        }

        return AppScaffold(
          title: _getTranslation('device_settings'),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sezione Generale
                    Text(
                      _getTranslation('general'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _nameController,
                      label: _getTranslation('device_name'),
                      hintText: _getTranslation('enter_device_name'),
                    ),
                    const SizedBox(height: 16),

                    AppButton(
                      text: _getTranslation('save'),
                      onPressed: _saveName,
                      style: AppButtonStyle.primary,
                    ),
                    const SizedBox(height: 32),

                    // Sezione Funzioni
                    Text(
                      _getTranslation('functions'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SettingsItem(
                      title: _getTranslation('chrono_scheduling'),
                      description: _getTranslation('chrono_scheduling_description'),
                      iconData: Icons.schedule,
                      iconColor: const Color(0xFFEFE7C8),
                      isLink: true,
                      onTap: _openProgrammingScreen,
                    ),

                    SettingsItem(
                      title: _getTranslation('adaptive_start'),
                      description: _getTranslation('adaptive_start_description'),
                      iconData: Icons.trending_up,
                      iconColor: const Color(0xFFFF7400),
                      isToggle: true,
                      isEnabled: thermostat.functionValues.contains(DeviceFunction.asc),
                      onToggle: (value) => _toggleDeviceFunction(DeviceFunction.asc),
                    ),

                    SettingsItem(
                      title: _getTranslation('window_detection'),
                      description: _getTranslation('window_detection_description'),
                      iconData: Icons.window,
                      iconColor: const Color(0xFFFF0A00),
                      isToggle: true,
                      isEnabled: thermostat.functionValues.contains(DeviceFunction.window),
                      onToggle: (value) => _toggleDeviceFunction(DeviceFunction.window),
                    ),

                    SettingsItem(
                      title: _getTranslation('eco_mode'),
                      description: _getTranslation('eco_mode_description'),
                      iconData: Icons.eco,
                      iconColor: const Color(0xFF14EB9C),
                      isToggle: true,
                      isEnabled: thermostat.functionValues.contains(DeviceFunction.eco),
                      onToggle: (value) => _toggleDeviceFunction(DeviceFunction.eco),
                    ),

                    SettingsItem(
                      title: _getTranslation('key_lock'),
                      description: _getTranslation('key_lock_description'),
                      iconData: Icons.lock,
                      iconColor: const Color(0xFFFFD700),
                      isToggle: true,
                      isEnabled: thermostat.functionValues.contains(DeviceFunction.keyLock),
                      onToggle: (value) => _toggleDeviceFunction(DeviceFunction.keyLock),
                    ),

                    SettingsItem(
                      title: _getTranslation('ping_device'),
                      description: _getTranslation('ping_device_description'),
                      iconData: Icons.notification_important,
                      iconColor: const Color(0xFF00A0F7),
                      isLink: true,
                      onTap: _sendPingToDevice,
                    ),

                    const SizedBox(height: 32),

                    // Pulsante Elimina
                    AppButton(
                      text: _getTranslation('delete_device'),
                      onPressed: _showDeleteConfirmationDialog,
                      style: AppButtonStyle.flat,
                      backgroundColor: Colors.red.shade800,
                      textColor: Colors.white,
                    ),

                    // Info Dispositivo
                    const SizedBox(height: 32),
                    Text(
                      _getTranslation('device_info'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(_getTranslation('id'), widget.deviceId),
                    _buildInfoRow(_getTranslation('type'), 'Bluetooth'),
                    if (thermostat.ambientTemperature != null)
                      _buildInfoRow(_getTranslation('temperature'), '${thermostat.ambientTemperature}°C'),

                    const SizedBox(height: 50), // Spazio extra in fondo per scorrimento
                  ],
                ),
              ),

              if (_waitingForOperation)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}