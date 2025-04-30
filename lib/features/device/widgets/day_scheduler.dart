// lib/features/device/widgets/day_scheduler.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';

class DayScheduler extends ConsumerWidget {
  final String deviceId;
  final int dayIndex;
  final Function(int hour, bool isComfort) onHourToggled;

  const DayScheduler({
    Key? key,
    required this.deviceId,
    required this.dayIndex,
    required this.onHourToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Qui implementerai la griglia per la programmazione giornaliera
    // Per ora usiamo dati fittizi
    final List<bool> hourlySchedule = List.generate(24, (index) => index >= 6 && index < 22);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orari',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 24,
              itemBuilder: (context, index) {
                final isComfort = hourlySchedule[index];

                return GestureDetector(
                  onTap: () => onHourToggled(index, !isComfort),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isComfort ? Colors.orange.shade300 : Colors.blue.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$index:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}