// lib/features/room/screens/add_device_to_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/features/room/providers/room_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class AddDeviceToRoomScreen extends ConsumerWidget {
  final String roomId;

  const AddDeviceToRoomScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final devices = ref.watch(devicesProvider);

    final room = rooms.firstWhere((r) => r.id == roomId);

    // Ottenere dispositivi non assegnati ad alcuna stanza
    final availableDevices = devices.where((device) {
      return device.roomId.isEmpty;
    }).toList();

    return AppScaffold(
      title: AppLocalizations.of(context).translate('add_device_to_room'),
      useDarkBackground: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context).translate('room')}: ${room.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (availableDevices.isEmpty) ...[
                Text(
                  AppLocalizations.of(context).translate('no_devices_available'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/add-device'),
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppLocalizations.of(context).translate('register_new_device'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  AppLocalizations.of(context).translate('available_devices'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = availableDevices[index];
                      return _buildDeviceItem(context, device, ref);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, DeviceModel device, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      device.online ? Icons.wifi : Icons.wifi_off,
                      color: device.online ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      device.type == DeviceType.wifi ? Icons.wifi : Icons.bluetooth,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${device.ambientTemperature.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _addDeviceToRoom(context, ref, device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).translate('add')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addDeviceToRoom(BuildContext context, WidgetRef ref, DeviceModel device) async {
    try {
      // Aggiorna il dispositivo per avere il riferimento alla stanza
      final updatedDevice = device.copyWith(roomId: roomId);
      await ref.read(devicesProvider.notifier).updateDevice(updatedDevice);

      // Aggiunge il dispositivo all'elenco dei dispositivi della stanza
      await ref.read(roomsProvider.notifier).addDeviceToRoom(roomId, device.id);

      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('device_added_to_room'),
        type: OverlayAlertType.success,
      );

      context.pop();
    } catch (e) {
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('error_adding_device'),
        type: OverlayAlertType.error,
      );
    }
  }
}