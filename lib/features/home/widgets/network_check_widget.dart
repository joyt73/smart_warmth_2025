import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/wifi_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';

class NetworkCheckWidget extends ConsumerWidget {
  const NetworkCheckWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiState = ref.watch(wifiProvider);

    String _getTranslation(String key) {
      return AppLocalizations.of(context).translate(key);
    }

    if (wifiState.savedSSID.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade600, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Text(
                  _getTranslation(TranslationKeys.noNetworkConfiguration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getTranslation(TranslationKeys.networkConfigurationNeeded),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: _getTranslation(TranslationKeys.goToConfig),
              style: AppButtonStyle.reversed,
              onPressed: () {
                context.push('/settings/wifi');
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}