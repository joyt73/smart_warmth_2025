import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/core/providers/locale_provider.dart';
import 'package:smart_warmth_2025/core/providers/user_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
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

  Future<void> _login() async {
    // Validazione del form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Nascondo la tastiera
    FocusScope.of(context).unfocus();

    try {
      debugPrint('LOGIN: Tentativo di login con email: ${_emailController.text}');

      // Ottengo l'AuthStateNotifier dal provider
      final authNotifier = ref.read(authStateProvider.notifier);

      // Effettuo il login
      debugPrint('LOGIN: Esecuzione login');
      final result = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

/*      // Se il widget non è più montato, esco dalla funzione
      if (!mounted) {
        debugPrint('LOGIN: Widget non più montato, esco dalla funzione');
        return;
      }*/


      // Verifico il risultato
      if (result.success) {
        debugPrint('LOGIN: Login riuscito');

        // // Recupero i dati dell'utente
        // debugPrint('LOGIN: Recupero dati utente');
        // final userNotifier = ref.read(userStateProvider.notifier);
        // await userNotifier.fetchUser();
        //
        // // Verifico se l'utente è stato caricato correttamente
        // final userState = ref.read(userStateProvider);
        // if (userState.user != null) {
        //   debugPrint('LOGIN: Dati utente caricati, navigazione alla home');
        //   debugPrint('LOGIN: Dati utente caricati, ${userState.user!.displayName}');

          // Navigazione alla home
        //  if (mounted) {
            //debugPrint('LOGIN: Navigazione alla home');
        Future.microtask(() {
          debugPrint('LOGIN: Navigazione alla home');
          if (mounted) {
            context.go('/home');
          } else {
            debugPrint('LOGIN: Widget non montato durante navigazione');
          }
        });

        //  }
        // } else {
        //   debugPrint('LOGIN: Errore nel caricamento dei dati utente: ${userState.error}');
        //   ref.read(overlayAlertProvider.notifier).show(
        //     message: userState.error ?? 'Errore nel caricamento dei dati utente',
        //     type: OverlayAlertType.error,
        //   );
        // }
      } else {
        debugPrint('LOGIN: Errore di login: ${result.error}');

        // Mostro l'errore
        ref.read(overlayAlertProvider.notifier).show(
          message: result.error ?? AppLocalizations.of(context).translate('error_login'),
          type: OverlayAlertType.error,
        );
      }
    } catch (e) {
      debugPrint('LOGIN: Eccezione durante il login: $e');

      // Se il widget non è più montato, esco dalla funzione
      if (!mounted) return;


      // Mostro l'errore
      ref.read(overlayAlertProvider.notifier).show(
        message: e.toString(),
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
    final isLoading = authState == AuthState.loading || _isAuthenticationInProgress;
    return AppScaffold(
        title: _getTranslation('login'),
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
                        Text(
                          _getTranslation('email'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: _getTranslation('enter_email'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _getTranslation('email_required');
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return _getTranslation('valid_email_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getTranslation('password'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: _getTranslation('enter_password'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _getTranslation('password_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              _getTranslation('login'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                              child: Text(_getTranslation('forgot_password')),
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
                              child: Text(_getTranslation('register')),
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
                              child: Text(_getTranslation('contact_us')),
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
                                _getTranslation('change_language'),
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