// lib/features/device/screens/temperature_graph_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/widgets/temperature_graph_widget.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';

class TemperatureGraphScreen extends ConsumerWidget {
  final String deviceId;

  const TemperatureGraphScreen({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: AppLocalizations.of(context).translate('temperature_graph'),
      useDarkBackground: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TemperatureGraphWidget(deviceId: deviceId),
        ),
      ),
    );
  }
}