import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/providers/locale_provider.dart';
import 'package:smart_warmth_2025/core/providers/user_provider.dart';
import 'package:smart_warmth_2025/core/utils/validators.dart';
import 'package:smart_warmth_2025/shared/widgets/app_button.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/app_text_field.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';
import 'package:smart_warmth_2025/shared/widgets/toast.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _showLanguageSelector = false;
  bool _isAuthenticationInProgress = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Inserisci credenziali predefinite solo in debug mode
    assert(() {
      _emailController.text = "gtorre73@gmail.com";
      _passwordController.text = "P30pl3@3673";
      return true;
    }());

    // Verifica lo stato di autenticazione
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkAuth();
    // });
  }

  // Verifica se l'utente è già autenticato
  Future<void> _checkAuth() async {
    final authState = ref.read(authStateProvider);
    if (authState == AuthState.authenticated) {
      debugPrint('LOGIN: Utente già autenticato, navigazione alla home');

      // Recupero i dati dell'utente
      final userNotifier = ref.read(userStateProvider.notifier);
      await userNotifier.fetchUser();

      if (mounted) {
        context.go('/home');
      }
    }
  }

  // Modifica in login_screen.dart

  void _login() async {
    // Nascondi il selettore lingua se aperto
    if (_showLanguageSelector) {
      setState(() {
        _showLanguageSelector = false;
      });
    }

    if (_formKey.currentState!.validate() && !_isAuthenticationInProgress) {
      setState(() {
        _isAuthenticationInProgress = true;
        _isLoading = true;
      });

      try {
        final result = await ref.read(authStateProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

        // Controllo se il widget è ancora montato
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _isAuthenticationInProgress = false;
        });

        // Verifica esplicita del successo del login
        if (result.success) {
          // Utilizza un ritardo minimo per garantire che lo stato sia aggiornato
          Future.microtask(() {
            if (mounted) {
              context.go('/home');
            }
          });
        } else {
          // Mostra un messaggio di errore
          ref.read(overlayAlertProvider.notifier).show(
            message: result.error ?? _getTranslation(TranslationKeys.errorLogin),
            type: OverlayAlertType.error,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAuthenticationInProgress = false;
          });

          ref.read(overlayAlertProvider.notifier).show(
            message: e.toString(),
            type: OverlayAlertType.error,
          );
        }
      }
    }
  }

  void _login_old() async {
    // Nascondi il selettore lingua se aperto
    if (_showLanguageSelector) {
      setState(() {
        _showLanguageSelector = false;
      });
    }


    if (_formKey.currentState!.validate() && !_isAuthenticationInProgress) {
      setState(() {
        _isAuthenticationInProgress = true;
      });
      setState(() {
        _isLoading = true;
      });
      try {
        final result = await ref.read(authStateProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
        setState(() {
          _isLoading = false;
        });
        // Dopo il login, otteniamo lo stato attuale
        final authState = ref.read(authStateProvider);

        // Se l'autenticazione è avvenuta con successo e il widget è ancora montato
        if (authState == AuthState.authenticated && mounted) {
          // Naviga alla home
          context.go('/home');
        }
        if (!result.success && mounted) {
          // Mostra un messaggio di errore
          ref.read(overlayAlertProvider.notifier).show(
            message: result.error ?? _getTranslation(TranslationKeys.errorLogin),
            type: OverlayAlertType.error,
          );
        }
      } catch (e) {
        // Gestione errori specifica in caso di necessità
        print("Errore di login: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isAuthenticationInProgress = false;
          });
        }
      }
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState == AuthState.loading || _isAuthenticationInProgress;
    return AppScaffold(
        title: _getTranslation(TranslationKeys.login),
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {
              setState(() {
                _showLanguageSelector = !_showLanguageSelector;
              });
            },
          ),
        ],
        body:
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: _getTranslation(TranslationKeys.email),
                          hintText: _getTranslation(TranslationKeys.enterEmail),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validator.validateEmail(context, value),
                          //onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _passwordController,
                          label: _getTranslation(TranslationKeys.password),
                          hintText: _getTranslation(TranslationKeys.enterPassword),
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validator.validatePassword(context,value),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          //onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          text: _getTranslation(TranslationKeys.login),
                          isLoading: _isLoading,
                          style: AppButtonStyle.primary,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {
                                if (!isLoading) {
                                  context.push('/forgot-password');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_getTranslation(TranslationKeys.forgotPassword)),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!isLoading) {
                                  context.push('/register');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_getTranslation(TranslationKeys.register)),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!isLoading) {
                                  context.push('/contact');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_getTranslation(TranslationKeys.contactUs)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Selettore lingua
                if (_showLanguageSelector)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, right: 16),
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            _languageOption('🇬🇧 English', 'en'),
                            _languageOption('🇫🇷 Français', 'fr'),
                            _languageOption('🇮🇹 Italiano', 'it'),
                            _languageOption('🇪🇸 Español', 'es'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color:
          isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: isSelected ? 0 : 1.0,
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