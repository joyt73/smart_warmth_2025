// lib/features/device/screens/bluetooth_scan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_manager.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_provider.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text.dart';

class BluetoothScanScreen extends ConsumerStatefulWidget {
  const BluetoothScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends ConsumerState<BluetoothScanScreen> {
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _connectingDeviceId;
  bool _hasScanned = false;

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  void _scanForDevices() async {
    final bleManager = ref.read(bleManagerProvider);
    final isBluetoothOn = ref.read(bluetoothStateProvider);

    if (!isBluetoothOn) {
      _showBluetoothDisabledDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      // Ottieni tutti i dispositivi già connessi per non mostrarli nuovamente
      final deviceIds = <String>[];

      final discoveredDevices = await bleManager.discover(deviceIds);
      setState(() {
        _devices = discoveredDevices;
        _isScanning = false;
        _hasScanned = true;
      });
    } catch (e) {
      debugPrint('Errore durante la scansione: $e');
      setState(() {
        _isScanning = false;
        _hasScanned = true;
      });
    }
  }

  void _showBluetoothDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('bluetooth_disabled')),
        content: Text(_getTranslation('bluetooth_enable_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getTranslation('ok')),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _connectingDeviceId = device.id;
    });

    try {
      final bleManager = ref.read(bleManagerProvider);
      final thermostat = await bleManager.connect(device);

      if (thermostat != null) {
        if (mounted) {
          context.push('/device-bluetooth/${device.id}');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_getTranslation('connection_failed'))),
          );
        }
      }
    } catch (e) {
      debugPrint('Errore di connessione: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslation('connection_error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _connectingDeviceId = null;
        });
      }
    }
  }

  void _saveDeviceWithName(DiscoveredDevice device, String name) async {
    // Qui implementeremo il salvataggio del dispositivo nel database locale
    // Per ora, simuliamo semplicemente il successo

    Navigator.of(context).pop(); // Chiudi il dialogo

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getTranslation('device_saved'))),
    );

    context.go('/home');
  }

  void _showNameInputDialog(DiscoveredDevice device) {
    final nameController = TextEditingController(text: device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('new_device_name')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: _getTranslation('device_name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getTranslation('cancel')),
          ),
          TextButton(
            onPressed: () => _saveDeviceWithName(device, nameController.text),
            child: Text(_getTranslation('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBluetoothOn = ref.watch(bluetoothStateProvider);

    return AppScaffold(
      title: _getTranslation('bluetooth'),
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslation('bluetooth_scan_info'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              text: _getTranslation('scan'),
              isLoading: _isScanning,
              onPressed: isBluetoothOn ? _scanForDevices : null,
              leadingIcon: const Icon(Icons.bluetooth_searching),
            ),

            const SizedBox(height: 24),

            AppText(
              text: _getTranslation('nearby_devices'),
              preset: TextPreset.subheading,
            ),

            const SizedBox(height: 16),

            if (_isScanning)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_hasScanned && _devices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _getTranslation('no_devices_found'),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final isConnecting = _connectingDeviceId == device.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      leading: const Icon(Icons.bluetooth),
                      trailing: isConnecting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.connect_without_contact),
                        onPressed: () => _showNameInputDialog(device),
                      ),
                      onTap: isConnecting
                          ? null
                          : () => _connectToDevice(device),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}