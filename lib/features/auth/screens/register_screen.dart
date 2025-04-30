import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/utils/validators.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Modifica in register_screen.dart

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate(TranslationKeys.acceptTerms),
          type: OverlayAlertType.error,
        );
      }
      return;
    }

    final displayName = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final authNotifier = ref.read(authStateProvider.notifier);
    final result = await authNotifier.register(displayName, email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      // Mostra un messaggio di successo
      ref.read(overlayAlertProvider.notifier).show(
        message: "Registrazione completata con successo!",
        type: OverlayAlertType.success,
      );

      // Naviga alla home dopo un breve ritardo
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go('/home');
        }
      });
    } else {
      // Mostra un messaggio di errore
      ref.read(overlayAlertProvider.notifier).show(
        message: result.error ?? AppLocalizations.of(context).translate(TranslationKeys.errorGeneric),
        type: OverlayAlertType.error,
      );
    }
  }

  Future<void> _register_old() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        // Mostra errore per l'accettazione dei termini
        ref.read(overlayAlertProvider.notifier).show(
          message: AppLocalizations.of(context).translate(TranslationKeys.acceptTerms),
          type: OverlayAlertType.error,
        );
      }
      return;
    }

    final displayName = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final authNotifier = ref.read(authStateProvider.notifier);
    final result = await authNotifier.register(displayName, email, password);

    setState(() {
      _isLoading = false;
    });

    if (!result.success && mounted) {
      // Mostra un messaggio di errore
      ref.read(overlayAlertProvider.notifier).show(
        message: result.error ?? AppLocalizations.of(context).translate(TranslationKeys.errorGeneric),
        type: OverlayAlertType.error,
      );
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState == AuthState.loading;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - statusBarHeight;

    return AppScaffold(
      title: _getTranslation(TranslationKeys.register),
      useDarkBackground: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rimuoviamo il SizedBox con altezza fissa che stava creando spazio vuoto
                    AppTextField(
                      controller: _usernameController,
                      label: _getTranslation(TranslationKeys.username),
                      hintText: _getTranslation(TranslationKeys.enterUsername),
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validator.validateUsername(context, value),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      label: _getTranslation(TranslationKeys.email),
                      hintText: _getTranslation(TranslationKeys.enterEmail),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validator.validateEmail(context, value),
                      //onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      label: _getTranslation(TranslationKeys.password),
                      hintText: _getTranslation(TranslationKeys.enterPassword),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validator.validatePassword(context, value),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.white;
                              }
                              return Colors.grey;
                            },
                          ),
                          checkColor: const Color(0xFF1A4A4A),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Mostra i termini e condizioni (potresti implementare un dialogo o una nuova pagina)
                            },
                            child: Text(
                              _getTranslation(TranslationKeys.termsAndConditions),
                              style: const TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child:
                      AppButton(
                        text: _getTranslation(TranslationKeys.register),
                        isLoading: _isLoading,
                        style: AppButtonStyle.primary,
                        onPressed: _register,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}