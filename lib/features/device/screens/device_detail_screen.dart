// lib/features/device/screens/device_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/device_model.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  double _temperature = 20.0;
  final double _minTemperature = 7.0;
  final double _maxTemperature = 30.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTemperature();
    });
  }

  void _initTemperature() {
    final devices = ref.read(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);

    setState(() {
      if (device.mode == DeviceMode.comfort) {
        _temperature = device.comfortTemperature;
      } else if (device.mode == DeviceMode.economy) {
        _temperature = device.economyTemperature;
      } else {
        _temperature = device.ambientTemperature;
      }
    });
  }

  void _updateTemperature(double value) {
    setState(() {
      _temperature = value;
    });
  }

  void _saveTemperature() {
    final deviceNotifier = ref.read(devicesProvider.notifier);
    final devices = ref.read(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);

    final isComfort = device.mode == DeviceMode.comfort;

    deviceNotifier.setTemperature(widget.deviceId, _temperature, isComfort);
  }

  void _changeMode(DeviceMode mode) {
    final deviceNotifier = ref.read(devicesProvider.notifier);
    deviceNotifier.setDeviceMode(widget.deviceId, mode);
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);

    return AppScaffold(
      title: device.name,
      useDarkBackground: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/device/${device.id}/settings'),
        ),
      ],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTemperatureDisplay(device),
              const SizedBox(height: 32),
              _buildTemperatureControls(device),
              const SizedBox(height: 32),
              _buildModeSelector(device),
              if (device.mode == DeviceMode.schedule)
                _buildScheduleControls(device),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureDisplay(DeviceModel device) {
    final isAdjustable = device.mode == DeviceMode.comfort ||
        device.mode == DeviceMode.economy;

    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTemperatureColor(device.ambientTemperature).withOpacity(0.8),
            _getTemperatureColor(_temperature),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${_temperature.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (!isAdjustable)
            Text(
              AppLocalizations.of(context).translate('ambient_temperature'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          const SizedBox(height: 8),
          if (device.online)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  device.type == DeviceType.wifi ? Icons.wifi : Icons.bluetooth,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('online'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('offline'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTemperatureControls(DeviceModel device) {
    final isAdjustable = device.mode == DeviceMode.comfort ||
        device.mode == DeviceMode.economy;

    if (!isAdjustable) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getTemperatureColor(_temperature),
              inactiveTrackColor: Colors.grey[600],
              thumbColor: Colors.white,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              min: _minTemperature,
              max: _maxTemperature,
              value: _temperature,
              divisions: (_maxTemperature - _minTemperature).toInt() * 2,
              onChanged: (value) {
                _updateTemperature(value);
              },
              onChangeEnd: (value) {
                _saveTemperature();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_minTemperature.toInt()}°',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_maxTemperature.toInt()}°',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTemperatureButton(
                Icons.remove,
                    () {
                  if (_temperature > _minTemperature) {
                    _updateTemperature(_temperature - 0.5);
                    _saveTemperature();
                  }
                },
              ),
              const SizedBox(width: 32),
              _buildTemperatureButton(
                Icons.add,
                    () {
                  if (_temperature < _maxTemperature) {
                    _updateTemperature(_temperature + 0.5);
                    _saveTemperature();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        iconSize: 32,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildModeSelector(DeviceModel device) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('mode'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeButton(
                  DeviceMode.comfort,
                  Icons.wb_sunny,
                  'comfort_mode',
                  device.mode == DeviceMode.comfort,
                ),
                _buildModeButton(
                  DeviceMode.economy,
                  Icons.nightlight_round,
                  'economy_mode',
                  device.mode == DeviceMode.economy,
                ),
                _buildModeButton(
                  DeviceMode.schedule,
                  Icons.schedule,
                  'schedule_mode',
                  device.mode == DeviceMode.schedule,
                ),
                _buildModeButton(
                  DeviceMode.boost,
                  Icons.local_fire_department,
                  'boost_mode',
                  device.mode == DeviceMode.boost,
                ),
                _buildModeButton(
                  DeviceMode.antIce,
                  Icons.ac_unit,
                  'antifreeze_mode',
                  device.mode == DeviceMode.antIce,
                ),
                _buildModeButton(
                  DeviceMode.standby,
                  Icons.power_settings_new,
                  'standby_mode',
                  device.mode == DeviceMode.standby,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      DeviceMode mode,
      IconData icon,
      String translationKey,
      bool isActive,
      ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => _changeMode(mode),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? _getModeColor(mode) : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate(translationKey),
            style: TextStyle(
              color: isActive ? _getModeColor(mode) : Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleControls(DeviceModel device) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('programming'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/device/${device.id}/programming'),
            icon: const Icon(Icons.schedule),
            label: Text(
              AppLocalizations.of(context).translate('edit_schedule'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature <= 15) {
      return Colors.blue;
    } else if (temperature <= 22) {
      return Colors.green;
    } else if (temperature <= 26) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getModeColor(DeviceMode mode) {
    switch (mode) {
      case DeviceMode.standby:
        return Colors.grey;
      case DeviceMode.comfort:
        return Colors.orange;
      case DeviceMode.economy:
        return Colors.blue;
      case DeviceMode.antIce:
        return Colors.lightBlue;
      case DeviceMode.boost:
        return Colors.red;
      case DeviceMode.schedule:
        return Colors.purple;
      case DeviceMode.holiday:
        return Colors.teal;
      case DeviceMode.filPilot:
        return Colors.amber;
    }
  }
}