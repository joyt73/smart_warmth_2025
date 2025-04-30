// lib/features/device/widgets/temperature_graph_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/features/device/models/temperature_data.dart';
import 'package:smart_warmth_2025/features/device/providers/temperature_data_provider.dart';

class TemperatureGraphWidget extends ConsumerStatefulWidget {
  final String deviceId;

  const TemperatureGraphWidget({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<TemperatureGraphWidget> createState() => _TemperatureGraphWidgetState();
}

class _TemperatureGraphWidgetState extends ConsumerState<TemperatureGraphWidget> {
  int _timeRange = 0; // 0: oggi, 1: ieri, 7: ultima settimana
  Set<String> _selectedTypes = {'AMBIENT', 'COMFORT', 'ECONOMY'};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(temperatureDataProvider(
          TemperatureDataParams(deviceId: widget.deviceId, daysAgo: _timeRange)
      ).notifier).loadData();
    } catch (e) {
      // Gestione errori
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final temperatureDataState = ref.watch(temperatureDataProvider(
        TemperatureDataParams(deviceId: widget.deviceId, daysAgo: _timeRange)
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildLegend(context),
        const SizedBox(height: 16),
        Expanded(
          child: temperatureDataState.when(
            data: (data) => _buildChart(context, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(
                  child: Text(
                    '${AppLocalizations.of(context).translate(
                        'error_loading_data')}: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).translate('temperature_trends'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onSelected: (value) {
            setState(() {
              _timeRange = value;
            });
            _loadData();
          },
          itemBuilder: (context) =>
          [
            PopupMenuItem(
              value: 0,
              child: Text(AppLocalizations.of(context).translate('today')),
            ),
            PopupMenuItem(
              value: 1,
              child: Text(AppLocalizations.of(context).translate('yesterday')),
            ),
            PopupMenuItem(
              value: 7,
              child: Text(AppLocalizations.of(context).translate('last_week')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _buildLegendItem(
          context,
          'AMBIENT',
          Colors.purple.shade300,
          AppLocalizations.of(context).translate('ambient'),
        ),
        _buildLegendItem(
          context,
          'COMFORT',
          Colors.green.shade300,
          AppLocalizations.of(context).translate('comfort'),
        ),
        _buildLegendItem(
          context,
          'ECONOMY',
          Colors.blue.shade300,
          AppLocalizations.of(context).translate('economy'),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String type, Color color,
      String label) {
    final isSelected = _selectedTypes.contains(type);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedTypes.length > 1) {
              _selectedTypes.remove(type);
            }
          } else {
            _selectedTypes.add(type);
          }
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<TemperatureData> allData) {
    // Filtra per i tipi selezionati
    final filteredData = allData
        .where((data) => _selectedTypes.contains(data.type))
        .toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_data_available'),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    // Raggruppa per tipo
    final Map<String, List<TemperatureData>> groupedData = {};
    for (var item in filteredData) {
      if (!groupedData.containsKey(item.type)) {
        groupedData[item.type] = [];
      }
      groupedData[item.type]!.add(item);
    }

    // Ordina per timestamp
    groupedData.forEach((key, value) {
      value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    // Determina il min e max per l'asse Y
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var data in filteredData) {
      if (data.value < minY) minY = data.value;
      if (data.value > maxY) maxY = data.value;
    }

    // Aggiungi un po' di margine
    minY = (minY - 1).clamp(0, 30);
    maxY = (maxY + 1).clamp(0, 32);

    // Trasforma i dati in liste di FlSpot per il grafico
    final Map<String, List<FlSpot>> spots = {};

    groupedData.forEach((type, dataList) {
      spots[type] = [];

      for (int i = 0; i < dataList.length; i++) {
        spots[type]!.add(FlSpot(i.toDouble(), dataList[i].value));
      }
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateXAxisInterval(filteredData.length),
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < filteredData.length) {
                  final data = filteredData[index];
                  final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                      data.timestamp * 1000);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°',
                  style: const TextStyle(
                    color: Colors.grey,
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
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: (filteredData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            //tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final String type = _findTypeFromSpot(spot, groupedData, spots);
                final color = _getColorForType(type);

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}°',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: _buildLineBarsData(groupedData, spots),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(
      Map<String, List<TemperatureData>> groupedData,
      Map<String, List<FlSpot>> spots,) {
    final List<LineChartBarData> result = [];

    groupedData.forEach((type, dataList) {
      result.add(
        LineChartBarData(
          spots: spots[type] ?? [],
          isCurved: true,
          color: _getColorForType(type),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _getColorForType(type).withOpacity(0.2),
          ),
        ),
      );
    });

    return result;
  }

  String _findTypeFromSpot(LineBarSpot spot,
      Map<String, List<TemperatureData>> groupedData,
      Map<String, List<FlSpot>> spots,) {
    for (var entry in spots.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        if (entry.value[i].x == spot.x && entry.value[i].y == spot.y) {
          return entry.key;
        }
      }
    }
    return '';
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'AMBIENT':
        return Colors.purple.shade300;
      case 'COMFORT':
        return Colors.green.shade300;
      case 'ECONOMY':
        return Colors.blue.shade300;
      default:
        return Colors.grey;
    }
  }

  double _calculateXAxisInterval(int dataLength) {
    if (dataLength <= 10) {
      return 1;
    } else if (dataLength <= 20) {
      return 2;
    } else if (dataLength <= 60) {
      return 5;
    } else {
      return (dataLength / 10).floor().toDouble();
    }
  }
}