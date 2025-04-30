import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class Toast {
  static OverlayEntry? _currentToast;

  /// Mostra un toast semplice che si posiziona nella parte inferiore dello schermo
  static void show(
      BuildContext context, {
        required String message,
        ToastType type = ToastType.info,
        Duration duration = const Duration(seconds: 2),
        double? bottomOffset,
      }) {
    _dismissCurrentToast();

    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomOffset ?? (mediaQuery.padding.bottom + 16),
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: _getBackgroundColor(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                _getIcon(type),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay?.insert(_currentToast!);

    Future.delayed(duration, () {
      _dismissCurrentToast();
    });
  }

  static void _dismissCurrentToast() {
    if (_currentToast != null) {
      _currentToast!.remove();
      _currentToast = null;
    }
  }

  static Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green.shade800;
      case ToastType.error:
        return Colors.red.shade800;
      case ToastType.warning:
        return Colors.amber.shade800;
      case ToastType.info:
      default:
        return Colors.blue.shade800;
    }
  }

  static Widget _getIcon(ToastType type) {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (type) {
      case ToastType.success:
        iconData = Icons.check_circle;
        break;
      case ToastType.error:
        iconData = Icons.error;
        break;
      case ToastType.warning:
        iconData = Icons.warning;
        break;
      case ToastType.info:
      default:
        iconData = Icons.info;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 24,
    );
  }
}