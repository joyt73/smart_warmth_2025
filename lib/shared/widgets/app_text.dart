// lib/shared/widgets/app_text.dart

import 'package:flutter/material.dart';

enum TextPreset {
  heading,
  subheading,
  title,
  body,
  caption,
  button,
}

class AppText extends StatelessWidget {
  final String text;
  final TextPreset preset;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool selectable;

  const AppText({
    Key? key,
    required this.text,
    this.preset = TextPreset.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _getStyleForPreset(preset, context);
    final finalStyle = style.copyWith(color: color ?? style.color);

    if (selectable) {
      return SelectableText(
        text,
        style: finalStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getStyleForPreset(TextPreset preset, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (preset) {
      case TextPreset.heading:
        return textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ) ?? const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

      case TextPreset.subheading:
        return textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

      case TextPreset.title:
        return textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ) ?? const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        );

      case TextPreset.body:
        return textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ) ?? const TextStyle(
          fontSize: 16,
          color: Colors.white,
        );

      case TextPreset.caption:
        return textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        ) ?? const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        );

      case TextPreset.button:
        return textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
    }
  }
}