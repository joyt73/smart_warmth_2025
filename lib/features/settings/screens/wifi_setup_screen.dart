import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/wifi_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class WifiSetupScreen extends ConsumerStatefulWidget {
  const WifiSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends ConsumerState<WifiSetupScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _isScanning = false;
  List<String> _foundNetworks = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadSavedNetwork();
      _scanWifiNetworks();
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedNetwork() async {
    final wifiState = ref.read(wifiProvider);
    if (wifiState.savedSSID.isNotEmpty) {
      setState(() {
        _ssidController.text = wifiState.savedSSID;
        _passwordController.text = wifiState.savedPassword;
      });
    }
  }

  Future<void> _scanWifiNetworks() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _foundNetworks = [];
    });

    try {
      final networks = await ref.read(wifiProvider.notifier).scanNetworks();
      if (mounted) {
        setState(() {
          _foundNetworks = networks;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nella scansione WiFi: ${e.toString()}',
              type: OverlayAlertType.error,
            );
      }
    }
  }

  Future<void> _saveNetwork() async {
    if (_ssidController.text.isEmpty) {
      ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.ssidRequired),
            type: OverlayAlertType.warning,
          );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(wifiProvider.notifier).saveNetwork(
            _ssidController.text,
            _passwordController.text,
          );

      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: _getTranslation(TranslationKeys.wifiSaved),
              type: OverlayAlertType.success,
            );
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nel salvataggio della rete: ${e.toString()}',
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

  Future<void> _connectToNetwork() async {
    if (_ssidController.text.isEmpty) {
      ref.read(overlayAlertProvider.notifier).show(
            message: _getTranslation(TranslationKeys.ssidRequired),
            type: OverlayAlertType.warning,
          );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(wifiProvider.notifier).connectToNetwork(
            _ssidController.text,
            _passwordController.text,
          );

      if (mounted) {
        if (result) {
          ref.read(overlayAlertProvider.notifier).show(
                message: _getTranslation(TranslationKeys.wifiConnected),
                type: OverlayAlertType.success,
              );
        } else {
          ref.read(overlayAlertProvider.notifier).show(
                message: _getTranslation(TranslationKeys.wifiConnectFailed),
                type: OverlayAlertType.error,
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(overlayAlertProvider.notifier).show(
              message: 'Errore nella connessione alla rete: ${e.toString()}',
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
    return AppScaffold(
      title: _getTranslation(TranslationKeys.setupWifi),
      showBackButton: true,
      useDarkBackground: true,
      body: OverlayAlertWrapper(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslation(TranslationKeys.networkName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isScanning
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : _foundNetworks.isEmpty
                                  ? Text(
                                      _getTranslation(
                                          TranslationKeys.noNetworksFound),
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF95A3A4),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _foundNetworks.contains(
                                                  _ssidController.text)
                                              ? _ssidController.text
                                              : null,
                                          hint: Text(
                                            _getTranslation(
                                                TranslationKeys.selectNetwork),
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                          isExpanded: true,
                                          icon:
                                              const Icon(Icons.arrow_drop_down),
                                          iconSize: 24,
                                          elevation: 16,
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                _ssidController.text = newValue;
                                              });
                                            }
                                          },
                                          items: _foundNetworks
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: _getTranslation(
                                      TranslationKeys.scanNetworks),
                                  height: 40,
                                  style: AppButtonStyle.secondary,
                                  isLoading: _isScanning,
                                  onPressed: _scanWifiNetworks,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _getTranslation(TranslationKeys.manualNetworkName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _ssidController,
                            hintText:
                                _getTranslation(TranslationKeys.enterSSID),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getTranslation(TranslationKeys.password),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _passwordController,
                            hintText:
                                _getTranslation(TranslationKeys.enterPassword),
                            obscureText: !_showPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: _getTranslation(TranslationKeys.connectToNetwork),
                style: AppButtonStyle.reversed,
                isLoading: _isLoading,
                onPressed: _connectToNetwork,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: _getTranslation(TranslationKeys.saveNetwork),
                style: AppButtonStyle.primary,
                isLoading: _isLoading,
                onPressed: _saveNetwork,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
