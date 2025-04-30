// lib/features/device/widgets/mode_selector.dart

import 'package:flutter/material.dart';
import 'package:smart_warmth_2025/core/bluetooth/ble_manager.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';

class ModeSelector extends StatelessWidget {
  final DeviceMode currentMode;
  final Function(DeviceMode) onModeChanged;

  const ModeSelector({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildModeButton(
            context,
            DeviceMode.standby,
            'standby_mode',
            Icons.power_settings_new,
            const Color(0xFFFE5F55),
          ),
          _buildModeButton(
            context,
            DeviceMode.boost,
            'boost_mode',
            Icons.flash_on,
            const Color(0xFFE03616),
          ),
          _buildModeButton(
            context,
            DeviceMode.schedule,
            'schedule_mode',
            Icons.schedule,
            const Color(0xFFBBADFF),
          ),
          _buildModeButton(
            context,
            DeviceMode.economy,
            'economy_mode',
            Icons.nightlight_round,
            const Color(0xFF357DED),
          ),
          _buildModeButton(
            context,
            DeviceMode.comfort,
            'comfort_mode',
            Icons.wb_sunny,
            const Color(0xFFEF946C),
          ),
          _buildModeButton(
            context,
            DeviceMode.antIce,
            'antifreeze_mode',
            Icons.ac_unit,
            const Color(0xFFCDD1DE),
          ),
          _buildModeButton(
            context,
            DeviceMode.filPilot,
            'filpilot_mode',
            Icons.home,
            const Color(0xFF4C5F6B),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context,
      DeviceMode mode,
      String translationKey,
      IconData icon,
      Color color,
      ) {
    final isActive = currentMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onModeChanged(mode),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? color : color.withOpacity(0.5),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
                    : null,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate(translationKey),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}