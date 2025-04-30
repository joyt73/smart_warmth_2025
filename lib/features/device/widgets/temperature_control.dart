// lib/features/device/widgets/temperature_control.dart

import 'package:flutter/material.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text.dart';

class TemperatureControl extends StatelessWidget {
  final double temperature;
  final bool showControls;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool boostMode;
  final int? boostRemainingTime;

  const TemperatureControl({
    Key? key,
    required this.temperature,
    this.showControls = false,
    this.onIncrement,
    this.onDecrement,
    this.boostMode = false,
    this.boostRemainingTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showControls)
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 48),
            onPressed: onIncrement,
            color: Colors.white,
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temperature.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                '°',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        if (boostMode && boostRemainingTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppText(
              text: 'Tempo rimanente: $boostRemainingTime min',
              preset: TextPreset.body,
            ),
          ),

        if (showControls)
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 48),
            onPressed: onDecrement,
            color: Colors.white,
          ),
      ],
    );
  }
}