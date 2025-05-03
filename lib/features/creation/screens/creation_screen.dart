// lib/features/creation/screens/creation_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';

class CreationScreen extends StatelessWidget {
  const CreationScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    return AppScaffold(
      title: translations.translate(TranslationKeys.creation),
      useDarkBackground: true,
      body: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 104),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCreationButton(
              context: context,
              icon: Icons.bluetooth,
              text: translations.translate(TranslationKeys.bluetooth),
              onPressed: () => context.push('/bluetooth-scan'),
            ),
            const SizedBox(height: 16),
            _buildCreationButton(
              context: context,
              icon: Icons.wifi,
              text: translations.translate(TranslationKeys.wifi),
              onPressed: () => context.push('/settings/wifi'),
            ),
            const SizedBox(height: 16),
            _buildCreationButton(
              context: context,
              icon: Icons.home,
              text: translations.translate(TranslationKeys.newRoom),
              onPressed: () => context.push('/add-room'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF04555C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}