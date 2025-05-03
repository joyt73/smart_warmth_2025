import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/permissions_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(permissionsProvider.notifier).checkAllPermissions();
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore nel controllo dei permessi: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPermission(String permissionType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await ref.read(permissionsProvider.notifier).requestPermission(permissionType);

      if (mounted) {
        if (granted) {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.permissionGranted),
            type: OverlayAlertType.success,
          );
        } else {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.permissionDenied),
            type: OverlayAlertType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore nella richiesta di permesso: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(permissionsProvider.notifier).requestAllPermissions();
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: _getTranslation(TranslationKeys.permissionsChecked),
          type: OverlayAlertType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
          message: 'Errore nella richiesta dei permessi: ${e.toString()}',
          type: OverlayAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionsProvider);

    return AppScaffold(
      title: _getTranslation(TranslationKeys.permissions),
      showBackButton: true,
      useDarkBackground: true,
      body: OverlayAlertWrapper(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTranslation(TranslationKeys.touchPermissionToResolve),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPermissionItem(
                        icon: Icons.camera_alt,
                        title: _getTranslation(TranslationKeys.camera),
                        isGranted: permissions.camera,
                        onTap: () => _requestPermission('camera'),
                      ),
                      _buildPermissionItem(
                        icon: Icons.location_on,
                        title: _getTranslation(TranslationKeys.location),
                        isGranted: permissions.location,
                        onTap: () => _requestPermission('location'),
                      ),
                      _buildPermissionItem(
                        icon: Icons.bluetooth,
                        title: _getTranslation(TranslationKeys.bluetoothScan),
                        isGranted: permissions.bluetoothScan,
                        onTap: () => _requestPermission('bluetoothScan'),
                      ),
                      _buildPermissionItem(
                        icon: Icons.bluetooth_connected,
                        title: _getTranslation(TranslationKeys.bluetoothConnect),
                        isGranted: permissions.bluetoothConnect,
                        onTap: () => _requestPermission('bluetoothConnect'),
                      ),
                    ],
                  ),
                ),
              ),
              AppButton(
                text: _getTranslation(TranslationKeys.requestAllPermissions),
                style: AppButtonStyle.reversed,
                onPressed: _requestAllPermissions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
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
            Icon(
              isGranted ? Icons.check_circle : Icons.cancel,
              color: isGranted ? Colors.lightGreen : Colors.red,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}