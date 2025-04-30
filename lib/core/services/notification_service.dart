import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/shared/widgets/alert_message.dart';

class NotificationService {
  // Mostra uno SnackBar
  static void showSnackBar(
      BuildContext context, {
        required String message,
        Color backgroundColor = Colors.black87,
        Duration duration = const Duration(seconds: 2),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Mostra un dialog di avviso
  static Future<void> showAlertDialog(
      BuildContext context, {
        required String title,
        required String message,
        String? confirmText,
        VoidCallback? onConfirm,
        String? cancelText,
        VoidCallback? onCancel,
        AlertType type = AlertType.info,
      }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            if (cancelText != null)
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (onCancel != null) {
                    onCancel();
                  }
                },
              ),
            TextButton(
              child: Text(confirmText ?? 'OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // Mostra una notifica permanente nella parte superiore dello schermo
  static Widget showPersistentNotification({
    required String message,
    String? subMessage,
    AlertType type = AlertType.info,
    bool showIcon = true,
    VoidCallback? onDismiss,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          AlertMessage(
            message: message,
            subMessage: subMessage,
            type: type,
            showIcon: showIcon,
          ),
          if (onDismiss != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onDismiss,
              ),
            ),
        ],
      ),
    );
  }
}

// Provider per il servizio di notifiche
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});