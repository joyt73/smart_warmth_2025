// lib/features/room/screens/room_detail_screen.dart
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

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final devices = ref.watch(devicesProvider);

    final room = rooms.firstWhere((r) => r.id == roomId);
    final roomDevices = devices.where((d) => room.deviceIds.contains(d.id)).toList();

    return AppScaffold(
      title: room.name,
      useDarkBackground: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/room/$roomId/edit'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'power_on') {
              _setAllDevicesPower(ref, roomDevices, true, context);
            } else if (value == 'power_off') {
              _setAllDevicesPower(ref, roomDevices, false, context);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, ref, room);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'power_on',
              child: Row(
                children: [
                  Icon(Icons.power_settings_new, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).translate('power_on')),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'power_off',
              child: Row(
                children: [
                  Icon(Icons.power_settings_new, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).translate('power_off')),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).translate('delete_room')),
                ],
              ),
            ),
          ],
        ),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('devices'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (roomDevices.isEmpty) ...[
                Text(
                  AppLocalizations.of(context).translate('no_devices_in_room'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: roomDevices.length,
                    itemBuilder: (context, index) {
                      final device = roomDevices[index];
                      return _buildDeviceCard(context, device);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/room/$roomId/add-device'),
                      icon: const Icon(Icons.add),
                      label: Text(
                        AppLocalizations.of(context).translate('add_device'),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceModel device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/device/${device.id}'),
        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 16),
                  _buildModeIndicator(context, device),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (device.mode == DeviceMode.comfort || device.mode == DeviceMode.economy)
                    Text(
                      device.mode == DeviceMode.comfort
                          ? '${AppLocalizations.of(context).translate('comfort')}: ${device.comfortTemperature.toStringAsFixed(1)}°'
                          : '${AppLocalizations.of(context).translate('economy')}: ${device.economyTemperature.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  else if (device.mode == DeviceMode.schedule)
                    Text(
                      '${AppLocalizations.of(context).translate('program')}: P${device.currentSchedule + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  else
                    const SizedBox(),

                  ElevatedButton(
                    onPressed: () => context.push('/device/${device.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).translate('open')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeIndicator(BuildContext context, DeviceModel device) {
    IconData icon;
    Color color;
    String modeKey;

    switch (device.mode) {
      case DeviceMode.standby:
        icon = Icons.power_settings_new;
        color = Colors.grey;
        modeKey = 'standby_mode';
        break;
      case DeviceMode.comfort:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        modeKey = 'comfort_mode';
        break;
      case DeviceMode.economy:
        icon = Icons.nightlight_round;
        color = Colors.blue;
        modeKey = 'economy_mode';
        break;
      case DeviceMode.antIce:
        icon = Icons.ac_unit;
        color = Colors.lightBlue;
        modeKey = 'antifreeze_mode';
        break;
      case DeviceMode.boost:
        icon = Icons.local_fire_department;
        color = Colors.red;
        modeKey = 'boost_mode';
        break;
      case DeviceMode.schedule:
        icon = Icons.schedule;
        color = Colors.purple;
        modeKey = 'schedule_mode';
        break;
      case DeviceMode.holiday:
        icon = Icons.beach_access;
        color = Colors.teal;
        modeKey = 'holiday_mode';
        break;
      case DeviceMode.filPilot:
        icon = Icons.settings_remote;
        color = Colors.amber;
        modeKey = 'pilot_mode';
        break;
    }

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context).translate(modeKey),
          style: TextStyle(
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _setAllDevicesPower(WidgetRef ref, List<DeviceModel> devices, bool powerOn, BuildContext context) {
    if (devices.isEmpty) {
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('no_devices_to_control'),
        type: OverlayAlertType.warning,
      );
      return;
    }

    final deviceNotifier = ref.read(devicesProvider.notifier);

    for (final device in devices) {
      final targetMode = powerOn ? DeviceMode.comfort : DeviceMode.standby;
      deviceNotifier.setDeviceMode(device.id, targetMode);
    }

    ref.read(overlayAlertProvider.notifier).show(
      message: powerOn
          ? AppLocalizations.of(context).translate('devices_powered_on')
          : AppLocalizations.of(context).translate('devices_powered_off'),
      type: OverlayAlertType.success,
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, room) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('delete_room')),
          content: Text(
            AppLocalizations.of(context).translate('delete_room_confirmation').replaceAll('{name}', room.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteRoom(ref, room.id, context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(AppLocalizations.of(context).translate('delete')),
            ),
          ],
        );
      },
    );
  }

  void _deleteRoom(WidgetRef ref, String roomId, BuildContext context) async {
    try {
      await ref.read(roomsProvider.notifier).removeRoom(roomId);

      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('room_deleted'),
        type: OverlayAlertType.success,
      );

      context.go('/home');
    } catch (e) {
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('error_deleting_room'),
        type: OverlayAlertType.error,
      );
    }
  }
}