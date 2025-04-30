// lib/features/device/widgets/mode_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class ModeItem {
  final DeviceMode mode;
  final IconData icon;
  final Color color;

  const ModeItem({
    required this.mode,
    required this.icon,
    required this.color,
  });

  String getTranslationKey() {
    switch (mode) {
      case DeviceMode.standby:
        return 'standby';
      case DeviceMode.comfort:
        return 'comfort';
      case DeviceMode.economy:
        return 'economy';
      case DeviceMode.antIce:
        return 'antifreeze';
      case DeviceMode.boost:
        return 'boost';
      case DeviceMode.schedule:
        return 'schedule';
      case DeviceMode.holiday:
        return 'holiday';
      case DeviceMode.filPilot:
        return 'fil_pilot';
      default:
        return 'standby';
    }
  }
}

class ModeSelectorWidget extends ConsumerStatefulWidget {
  final String deviceId;

  const ModeSelectorWidget({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<ModeSelectorWidget> createState() => _ModeSelectorWidgetState();
}

class _ModeSelectorWidgetState extends ConsumerState<ModeSelectorWidget> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);
    final modes = _getModes(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).translate('operating_mode'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: modes.length,
            itemBuilder: (context, index) {
              final mode = modes[index];
              final isSelected = device.mode == mode.mode;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildModeItem(context, mode, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeItem(BuildContext context, ModeItem mode, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _isUpdating ? null : () => _setMode(mode.mode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isSelected ? mode.color : mode.color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: mode.color.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Icon(
              mode.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          AppLocalizations.of(context).translate(mode.getTranslationKey()),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  List<ModeItem> _getModes(BuildContext context) {
    return [
      ModeItem(
        mode: DeviceMode.comfort,
        icon: Icons.wb_sunny,
        color: Colors.orange,
      ),
      ModeItem(
        mode: DeviceMode.economy,
        icon: Icons.nightlight_round,
        color: Colors.blue,
      ),
      ModeItem(
        mode: DeviceMode.standby,
        icon: Icons.power_settings_new,
        color: Colors.grey,
      ),
      ModeItem(
        mode: DeviceMode.antIce,
        icon: Icons.ac_unit,
        color: Colors.lightBlue,
      ),
      ModeItem(
        mode: DeviceMode.boost,
        icon: Icons.speed,
        color: Colors.red,
      ),
      ModeItem(
        mode: DeviceMode.schedule,
        icon: Icons.schedule,
        color: Colors.purple,
      ),
      ModeItem(
        mode: DeviceMode.holiday,
        icon: Icons.beach_access,
        color: Colors.teal,
      ),
    ];
  }

  Future<void> _setMode(DeviceMode mode) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await ref.read(devicesProvider.notifier).setDeviceMode(
        widget.deviceId,
        mode,
      );

      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('mode_updated'),
        type: OverlayAlertType.success,
      );
    } catch (e) {
      ref.read(overlayAlertProvider.notifier).show(
        message: AppLocalizations.of(context).translate('mode_update_failed'),
        type: OverlayAlertType.error,
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
}