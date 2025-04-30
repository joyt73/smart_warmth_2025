import 'package:flutter/material.dart';

enum AlertType {
  success,
  error,
  info,
  warning,
}

class AlertMessage extends StatelessWidget {
  final String message;
  final String? subMessage;
  final AlertType type;
  final bool showIcon;
  final EdgeInsets? padding;
  final double borderRadius;

  const AlertMessage({
    Key? key,
    required this.message,
    this.subMessage,
    this.type = AlertType.info,
    this.showIcon = false,
    this.padding,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showIcon) ...[
                  _buildIcon(),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: TextStyle(
                  color: _getSubTextColor(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor = _getTextColor();

    switch (type) {
      case AlertType.success:
        iconData = Icons.check_circle;
        break;
      case AlertType.error:
        iconData = Icons.error;
        break;
      case AlertType.warning:
        iconData = Icons.warning;
        break;
      case AlertType.info:
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

  Color _getBackgroundColor() {
    switch (type) {
      case AlertType.success:
        return Colors.green.withOpacity(0.2);
      case AlertType.error:
        return Colors.red.withOpacity(0.1);
      case AlertType.warning:
        return Colors.amber.withOpacity(0.2);
      case AlertType.info:
      default:
        return Colors.blue.withOpacity(0.2);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case AlertType.success:
        return Colors.white;
      case AlertType.error:
        return Colors.red;
      case AlertType.warning:
        return Colors.amber.shade800;
      case AlertType.info:
      default:
        return Colors.white;
    }
  }

  Color _getSubTextColor() {
    switch (type) {
      case AlertType.success:
        return Colors.white70;
      case AlertType.error:
        return Colors.red.shade300;
      case AlertType.warning:
        return Colors.amber.shade700;
      case AlertType.info:
      default:
        return Colors.white70;
    }
  }
}