import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/utils/validators.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/alert_message.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    // Valida il form esplicitamente

    if (_formKey.currentState!.validate() && !_isProcessing) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await ref.read(authStateProvider.notifier).forgotPassword(
          _emailController.text,
        );

        if (mounted) {
          setState(() {
            _emailSent = true;
            _isProcessing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          // Mostra un messaggio di errore
          ref.read(overlayAlertProvider.notifier).show(
            message: e.toString(),
            type: OverlayAlertType.error,
          );
        }
      }
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState == AuthState.loading || _isProcessing;

    return AppScaffold(
      title: _getTranslation(TranslationKeys.passwordRecovery),
      useDarkBackground: false,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 100,
              ),

              AppTextField(
                controller: _emailController,
                label: _getTranslation(TranslationKeys.email),
                hintText: _getTranslation(TranslationKeys.enterEmail),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validator.validateEmail(context, value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _getTranslation(TranslationKeys.resetPassword),
                  style: AppButtonStyle.reversed,
                  isLoading: isLoading,
                  onPressed: isLoading || _emailSent ? null : _resetPassword,
                ),
              ),
              if (_emailSent)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTranslation(TranslationKeys.emailSent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getTranslation(TranslationKeys.checkSpam),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Utilizziamo AlertMessage per errori
              if (authState == AuthState.unauthenticated && !_emailSent)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: AlertMessage(
                    message: authState.error ??
                        _getTranslation(TranslationKeys.errorGeneric),
                    type: AlertType.error,
                  ),
                ),

              // Pulsante per tornare alla schermata di login
              if (_emailSent)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_getTranslation(TranslationKeys.login)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
