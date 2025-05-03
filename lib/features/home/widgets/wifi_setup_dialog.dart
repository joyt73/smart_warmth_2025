import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';

class WifiSetupDialog extends ConsumerWidget {
  const WifiSetupDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String _getTranslation(String key) {
      return AppLocalizations.of(context).translate(key);
    }

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: const Color(0xFF333232),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslation(TranslationKeys.noNetworkConfiguration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getTranslation(TranslationKeys.networkConfigurationNeeded),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            AppButton(
              text: _getTranslation(TranslationKeys.goToConfig),
              style: AppButtonStyle.reversed,
              leadingIcon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/settings/wifi');
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  _getTranslation(TranslationKeys.ignoreWifiConfig),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}