import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// lib/shared/widgets/overlay_alert.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OverlayAlertType {
  success,
  error,
  warning,
  info,
}

class OverlayAlertData {
  final String message;
  final OverlayAlertType type;
  final DateTime createdAt;
  final Duration duration;

  OverlayAlertData({
    required this.message,
    required this.type,
    required this.createdAt,
    this.duration = const Duration(seconds: 3),
  });
}

final overlayAlertProvider = StateNotifierProvider<OverlayAlertNotifier, OverlayAlertData?>(
      (ref) => OverlayAlertNotifier(),
);

class OverlayAlertNotifier extends StateNotifier<OverlayAlertData?> {
  OverlayAlertNotifier() : super(null);

  void show({
    required String message,
    OverlayAlertType type = OverlayAlertType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    state = OverlayAlertData(
      message: message,
      type: type,
      createdAt: DateTime.now(),
      duration: duration,
    );

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (state?.createdAt.millisecondsSinceEpoch ==
          DateTime.now().millisecondsSinceEpoch - duration.inMilliseconds) {
        state = null;
      }
    });
  }

  void dismiss() {
    state = null;
  }
}

class OverlayAlert extends ConsumerWidget {
  const OverlayAlert({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(overlayAlertProvider);

    if (alert == null) {
      return const SizedBox.shrink();
    }

    final Color backgroundColor;
    final IconData icon;

    switch (alert.type) {
      case OverlayAlertType.success:
        backgroundColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case OverlayAlertType.error:
        backgroundColor = Colors.red.shade800;
        icon = Icons.error;
        break;
      case OverlayAlertType.warning:
        backgroundColor = Colors.orange.shade800;
        icon = Icons.warning;
        break;
      case OverlayAlertType.info:
      default:
        backgroundColor = Colors.blue.shade800;
        icon = Icons.info;
        break;
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => ref.read(overlayAlertProvider.notifier).dismiss(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverlayAlertWrapper extends ConsumerWidget {
  final Widget child;

  const OverlayAlertWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        const OverlayAlert(),
      ],
    );
  }
}