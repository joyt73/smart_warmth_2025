import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/providers/locale_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showLanguageSelector = false;
  bool _isLoading = false;

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore durante il logout: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mostra un dialogo di conferma
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF333232),
          title: Text(
            _getTranslation(TranslationKeys.deleteAccount),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            _getTranslation(TranslationKeys.deleteAccountConfirmation),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                _getTranslation(TranslationKeys.cancel),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                _getTranslation(TranslationKeys.delete),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final authState = ref.watch(authStateProvider);
      final userId = authState.user!.id;
      // Procedi con l'eliminazione dell'account
      if(userId != null) {
        await ref.read(authStateProvider.notifier).deleteAccount(userId);

        if (mounted) {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.accountDeleted),
            type: OverlayAlertType.success,
          );
          context.go('/login');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ref.read(overlayAlertProvider.notifier).show(
            message: 'Errore durante l\'eliminazione dell\'account.',
            type: OverlayAlertType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore durante l\'eliminazione dell\'account: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _getTranslation(TranslationKeys.settings),
      showBackButton: true,
      useDarkBackground: true,
      body: OverlayAlertWrapper(
        child: Stack(
          children: [
            Padding(
                padding: EdgeInsets.only(top: 80),
                child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildSettingsRow(
                    icon: Icons.wifi,
                    title: _getTranslation(TranslationKeys.setupWifi),
                    onTap: () => context.push('/settings/wifi'),
                  ),
                  _buildSettingsRow(
                    icon: Icons.perm_device_information,
                    title: _getTranslation(TranslationKeys.permissions),
                    onTap: () => context.push('/settings/permissions'),
                  ),
                  _buildSettingsRow(
                    icon: Icons.language,
                    title: _getTranslation(TranslationKeys.changeLanguage),
                    onTap: () {
                      setState(() {
                        _showLanguageSelector = true;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  AppButton(
                    text: _getTranslation(TranslationKeys.logout),
                    style: AppButtonStyle.reversed,
                    isLoading: _isLoading,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: _getTranslation(TranslationKeys.deleteAccount),
                    style: AppButtonStyle.flat,
                    backgroundColor: Colors.red.shade700,
                    isLoading: _isLoading,
                    onPressed: _deleteAccount,
                  ),
                ],
              )
            ),
            // Selettore lingua
            if (_showLanguageSelector)
              _buildLanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showLanguageSelector = false;
          });
        },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF333232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _getTranslation(TranslationKeys.changeLanguage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  _languageOption('🇬🇧 English', 'en'),
                  _languageOption('🇫🇷 Français', 'fr'),
                  _languageOption('🇮🇹 Italiano', 'it'),
                  _languageOption('🇪🇸 Español', 'es'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageOption(String label, String locale) {
    final currentLocale = ref.watch(localeProvider).languageCode;
    final isSelected = currentLocale == locale;

    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        setState(() {
          _showLanguageSelector = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF95A3A4).withOpacity(0.3) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF95A3A4) : Colors.white24,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}