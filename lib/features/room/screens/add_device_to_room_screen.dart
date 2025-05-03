// lib/features/room/screens/add_device_to_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/device_provider.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class AddDeviceToRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const AddDeviceToRoomScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  ConsumerState<AddDeviceToRoomScreen> createState() => _AddDeviceToRoomScreenState();
}

class _AddDeviceToRoomScreenState extends ConsumerState<AddDeviceToRoomScreen> {
  bool _isLoading = false;
  List<String> _selectedDeviceIds = [];

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(availableDevicesProvider);
    final rooms = ref.watch(roomsProvider);

    // Trova la stanza corrente nell'elenco
    final room = rooms.firstWhere(
          (r) => r.id == widget.roomId,
      orElse: () => throw Exception('Stanza non trovata'),
    );

    return OverlayAlertWrapper(
      child: AppScaffold(
        title: _getTranslation('add_device_to_room'),
        useDarkBackground: true,
        body: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getTranslation('room')}: ${room.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                _getTranslation('available_devices'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: devicesAsync.when(
                  data: (devices) {
                    if (devices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other,
                              color: Colors.white.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getTranslation('no_devices_available'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: _getTranslation('register_new_device'),
                              style: AppButtonStyle.secondary,
                              onPressed: () {
                                context.push('/bluetooth-scan');
                              },
                            )
                          ],
                        ),
                      );
                    }

                    // Filtra i dispositivi non già presenti nella stanza
                    final availableDevices = devices.where((device) {
                      return !room.thermostats.any((d) => d.id == device.id);
                    }).toList();

                    if (availableDevices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other,
                              color: Colors.white.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getTranslation('no_devices_available'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: _getTranslation('register_new_device'),
                              style: AppButtonStyle.secondary,
                              onPressed: () {
                                context.push('/bluetooth-scan');
                              },
                            )
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: availableDevices.length,
                      itemBuilder: (context, index) {
                        final device = availableDevices[index];
                        final isSelected = _selectedDeviceIds.contains(device.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: isSelected
                              ? const Color(0xFF04555C)
                              : const Color(0xFF2A3A3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDeviceIds.remove(device.id);
                                } else {
                                  _selectedDeviceIds.add(device.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: Colors.white,
                                size: 28,
                              ),
                              title: Text(
                                device.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                device.online
                                    ? _getTranslation('online')
                                    : _getTranslation('offline'),
                                style: TextStyle(
                                  color: device.online
                                      ? Colors.green
                                      : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    device.online
                                        ? Icons.wifi
                                        : Icons.wifi_off,
                                    color: device.online
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${device.ambientTemperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Errore: ${error.toString()}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: _getTranslation('back'),
                          onPressed: () => context.pop(),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _getTranslation('add'),
                  style: AppButtonStyle.reversed,
                  isLoading: _isLoading,
                  onPressed: _selectedDeviceIds.isEmpty
                      ? null
                      : () => _addDevicesToRoom(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDevicesToRoom() async {
    if (_selectedDeviceIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool allSuccess = true;
      int successCount = 0;

      // Aggiungi ogni dispositivo selezionato alla stanza
      for (final deviceId in _selectedDeviceIds) {
        final success = await ref.read(roomsProvider.notifier)
            .addDeviceToRoom(widget.roomId, deviceId);

        if (success) {
          successCount++;
        } else {
          allSuccess = false;
        }
      }

      if (mounted) {
        if (allSuccess) {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation('device_added_to_room'),
            type: OverlayAlertType.success,
          );
          context.pop();
        } else if (successCount > 0) {
          ref.read(overlayAlertProvider.notifier).show(
            message: 'Aggiunti $successCount dispositivi su ${_selectedDeviceIds.length}',
            type: OverlayAlertType.info,
          );
          context.pop();
        } else {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation('error_adding_device'),
            type: OverlayAlertType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}