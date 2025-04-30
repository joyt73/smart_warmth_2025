// lib/shared/widgets/app_button.dart
import 'package:flutter/material.dart';

enum AppButtonStyle {
  primary,
  secondary,
  flat,
  reversed,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final double width;
  final double height;
  final Widget? leadingIcon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56.0,
    this.leadingIcon,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determiniamo i colori in base allo stile
    Color bgColor;
    Color txtColor;

    switch (style) {
      case AppButtonStyle.primary:
        bgColor = backgroundColor ?? const Color(0xFF95A3A4);
        txtColor = textColor ?? Colors.white;
        break;
      case AppButtonStyle.secondary:
        bgColor = backgroundColor ?? Colors.transparent;
        txtColor = textColor ?? Colors.white;
        break;
      case AppButtonStyle.flat:
        bgColor = backgroundColor ?? Colors.transparent;
        txtColor = textColor ?? Colors.white;
        break;
      case AppButtonStyle.reversed:
        bgColor = backgroundColor ?? const Color(0xFF04555C);
        txtColor = textColor ?? Colors.white;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: style != AppButtonStyle.primary && style != AppButtonStyle.reversed
                ? BoxDecoration(
              border: Border.all(
                color: const Color(0xFF95A3A4),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            )
                : null,
            child: isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(txtColor),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: txtColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}