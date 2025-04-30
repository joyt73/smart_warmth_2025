// lib/features/device/screens/temperature_chart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TemperatureChartScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const TemperatureChartScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  ConsumerState<TemperatureChartScreen> createState() => _TemperatureChartScreenState();
}

class _TemperatureChartScreenState extends ConsumerState<TemperatureChartScreen> {
  int _selectedDayOffset = 0; // 0 = oggi, -1 = ieri, -7 = ultima settimana
  bool _showComfort = true;
  bool _showAmbient = true;
  bool _showEconomy = true;

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final device = devices.firstWhere((d) => d.id == widget.deviceId);

    // Dati di esempio per il grafico
    final temperatureData = _generateTemperatureData(_selectedDayOffset);

    return AppScaffold(
      title: AppLocalizations.of(context).translate('temperature_chart'),
      useDarkBackground: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildChart(temperatureData),
              const SizedBox(height: 24),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDateButton('today', 0),
        _buildDateButton('yesterday', -1),
        _buildDateButton('last_week', -7),
      ],
    );
  }

  Widget _buildDateButton(String labelKey, int offset) {
    final isSelected = _selectedDayOffset == offset;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedDayOffset = offset;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(AppLocalizations.of(context).translate(labelKey)),
    );
  }

  Widget _buildChart(Map<String, List<FlSpot>> temperatureData) {
    final now = DateTime.now();

    return Expanded(
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  return Text(
                    '$hour:00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            if (_showAmbient)
              LineChartBarData(
                spots: temperatureData['ambient'] ?? [],
                isCurved: true,
                color: Colors.purple,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.purple.withOpacity(0.2),
                ),
              ),
            if (_showComfort)
              LineChartBarData(
                spots: temperatureData['comfort'] ?? [],
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
            if (_showEconomy)
              LineChartBarData(
                spots: temperatureData['economy'] ?? [],
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
          ],
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: 30,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).translate('legend'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('comfort', Colors.orange, _showComfort, (value) {
              setState(() {
                _showComfort = value;
              });
            }),
            _buildLegendItem('ambient', Colors.purple, _showAmbient, (value) {
              setState(() {
                _showAmbient = value;
              });
            }),
            _buildLegendItem('economy', Colors.blue, _showEconomy, (value) {
              setState(() {
                _showEconomy = value;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String labelKey, Color color, bool isActive, Function(bool) onChanged) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context).translate(labelKey),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          activeTrackColor: Colors.teal.withOpacity(0.4),
        ),
      ],
    );
  }

  Map<String, List<FlSpot>> _generateTemperatureData(int dayOffset) {
    // In un'app reale, questi dati verrebbero recuperati da un'API
    // Per ora, generiamo dati casuali
    final random = DateTime.now().millisecondsSinceEpoch;
    final ambient = <FlSpot>[];
    final comfort = <FlSpot>[];
    final economy = <FlSpot>[];

    for (int i = 0; i < 24; i++) {
      // Simuliamo variazioni basate sul giorno
      final dayFactor = (dayOffset * -0.5).clamp(-3.0, 3.0);

      // Crea una curva realistica durante il giorno
      double hourFactor = 0;
      if (i >= 6 && i <= 22) {
        // Durante il giorno, la temperatura aumenta
        hourFactor = (i - 6) / 16.0 * 5; // Massimo 5 gradi di variazione
        if (i >= 14) {
          // Nel pomeriggio comincia a scendere
          hourFactor = 5 - ((i - 14) / 8.0 * 5);
        }
      }

      final baseTemp = 20.0 + dayFactor;
      final ambientTemp = baseTemp + hourFactor + ((random % 10) / 10.0);
      final comfortTemp = baseTemp + 2 + ((random % 5) / 10.0);
      final economyTemp = baseTemp - 2 - ((random % 5) / 10.0);

      ambient.add(FlSpot(i.toDouble(), ambientTemp));
      comfort.add(FlSpot(i.toDouble(), comfortTemp));
      economy.add(FlSpot(i.toDouble(), economyTemp));
    }

    return {
      'ambient': ambient,
      'comfort': comfort,
      'economy': economy,
    };
  }
}