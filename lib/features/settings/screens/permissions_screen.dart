import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/config/themes.dart';
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

      // Aggiungi un debug print per verificare cosa sta succedendo
      final permissions = ref.read(permissionsProvider);
      debugPrint('Camera permission: ${permissions.camera}, permanently denied: ${permissions.cameraPermanentlyDenied}');
      debugPrint('Location permission: ${permissions.location}, permanently denied: ${permissions.locationPermanentlyDenied}');
      debugPrint('Bluetooth scan permission: ${permissions.bluetoothScan}, permanently denied: ${permissions.bluetoothScanPermanentlyDenied}');
      debugPrint('Bluetooth connect permission: ${permissions.bluetoothConnect}, permanently denied: ${permissions.bluetoothConnectPermanentlyDenied}');
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
      // Controlla se il permesso è negato permanentemente
      final permProvider = ref.read(permissionsProvider.notifier);
      final isPermanentlyDenied = permProvider.isPermissionPermanentlyDenied(permissionType);

      if (isPermanentlyDenied) {
        // Se il permesso è negato permanentemente, mostra direttamente la finestra di dialogo per le impostazioni
        _showOpenSettingsDialog(permissionType);
      } else {
        // Altrimenti, richiedi il permesso normalmente
        final granted = await permProvider.requestPermission(permissionType);

        if (mounted) {
          if (granted) {
            ref.read(overlayAlertProvider.notifier).show(
              message: _getTranslation(TranslationKeys.permissionGranted),
              type: OverlayAlertType.success,
            );
          } else {
            // Controlla nuovamente se il permesso è stato negato permanentemente
            await permProvider.checkAllPermissions();
            final isNowPermanentlyDenied = permProvider.isPermissionPermanentlyDenied(permissionType);

            if (isNowPermanentlyDenied) {
              _showOpenSettingsDialog(permissionType);
            } else {
              ref.read(overlayAlertProvider.notifier).show(
                message: _getTranslation(TranslationKeys.permissionDenied),
                type: OverlayAlertType.warning,
              );
            }
          }
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

  void _showOpenSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getTranslation(TranslationKeys.permissionRequired)),
          content: Text(_getPermissionDescription(permissionType)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200, // Sfondo
                foregroundColor: Colors.black, // Colore del testo
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_getTranslation(TranslationKeys.cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(permissionsProvider.notifier).openSettings();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, // Sfondo
                foregroundColor: Colors.white, // Colore del testo
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_getTranslation(TranslationKeys.openSettings)),
            ),
          ],
        );
      },
    );
  }

  String _getPermissionDescription(String permissionType) {
    switch (permissionType) {
      case 'camera':
        return _getTranslation(TranslationKeys.cameraPermissionDescription);
      case 'location':
        return _getTranslation(TranslationKeys.locationPermissionDescription);
      case 'bluetoothScan':
        return _getTranslation(TranslationKeys.bluetoothScanPermissionDescription);
      case 'bluetoothConnect':
        return _getTranslation(TranslationKeys.bluetoothConnectPermissionDescription);
      default:
        return _getTranslation(TranslationKeys.permissionRequiredDescription);
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allGranted = await ref.read(permissionsProvider.notifier).requestAllPermissions();

      if (mounted) {
        if (allGranted) {
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.allPermissionsGranted),
            type: OverlayAlertType.success,
          );
        } else {
          // Se qualche permesso non è stato concesso, mostra un messaggio e offri di aprire le impostazioni
          ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.somePermissionsDenied),
            type: OverlayAlertType.warning,
          );

          // Attendi un momento affinché l'utente legga il messaggio, poi chiedi se aprire le impostazioni
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _showOpenSettingsDialog('all');
            }
          });
        }
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
    final allPermissinOk = (permissions.camera && permissions.location
        && permissions.bluetoothScan && permissions.bluetoothConnect);
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
             if(!allPermissinOk)
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGranted ? null : onTap, // Rendi interattivo solo se non concesso
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Rendi visivamente più evidente che l'elemento è toccabile
            border: isGranted ? null : Border.all(color: Colors.white.withOpacity(0.2)),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    if (!isGranted) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getTranslation(TranslationKeys.tapToEnable),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
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
      ),
    );
  }
}