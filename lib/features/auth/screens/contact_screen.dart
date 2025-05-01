import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/i18n/translation_keys.dart';
import 'package:smart_warmth_2025/core/providers/auth_provider.dart';
import 'package:smart_warmth_2025/shared/widgets/app_scaffold.dart';
import 'package:smart_warmth_2025/shared/widgets/snack_bar_extension.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _senderController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedProblem;
  bool _showProblemSelector = false;

  // Lista dei problemi disponibili (sarà tradotta tramite _getTranslation)
  final List<String> _problemKeys = [
    'problem_generic',
    'problem_access',
    'problem_registration',
    'problem_device_connection',
    'problem_device_management',
  ];

  @override
  void initState() {
    super.initState();
    print("_precompileData 00: ${AuthState.authenticated}");
    // Ritardiamo l'inizializzazione per assicurarci che il provider sia pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precompileData();
    });
  }

  void _precompileData() {
    try {
      // Otteniamo lo stato dell'autenticazione
      final authState = ref.read(authStateProvider);

      // Controlla se l'utente è autenticato
      final isAuthenticated = authState.state == AuthState.authenticated ||
          authState.state == AuthState.authenticated;

      if (isAuthenticated && authState.user != null) {
        // Precompila i campi con i dati dell'utente
        setState(() {
          _senderController.text = authState.user!.displayName;
          _messageController.text = '''${_getTranslation('your_message')}:

User: ${authState.user!.displayName}
Email: ${authState.user!.email}
Platform:android''';
        });
      } else {
        // Se non autenticato, usa template generico
        setState(() {
          _messageController.text = '''${_getTranslation('your_message')}:

User:
Email:
Platform:android''';
        });
      }
    } catch (e) {
      print("Error in precompileData: $e");
      // Fallback sicuro in caso di errore
      setState(() {
        _messageController.text = '''${_getTranslation('your_message')}:

User:
Email:
Platform:android''';
      });
    }
  }
  @override
  void dispose() {
    _senderController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate() && _selectedProblem != null) {
      // Utilizziamo l'estensione per mostrare lo SnackBar di successo
      context.showSuccessSnackBar(_getTranslation(TranslationKeys.messageSent));

      // Reimpostare il form
      _precompileData(); // Ripristiniamo i dati precompilati
      setState(() {
        _selectedProblem = null;
      });
    } else if (_selectedProblem == null) {
      // Utilizziamo l'estensione per mostrare lo SnackBar di errore
      context.showErrorSnackBar(_getTranslation(TranslationKeys.selectProblem));
    }
  }

  String _getTranslation(String key) {
    return AppLocalizations.of(context).translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - statusBarHeight;

    return AppScaffold(
      title: _getTranslation(TranslationKeys.contactUs),
      useDarkBackground: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Chiude il selettore problemi se si tocca fuori da esso
            if (_showProblemSelector) {
              setState(() {
                _showProblemSelector = false;
              });
            }
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              SingleChildScrollView(
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
                        children: [
                          Text(
                            _getTranslation(TranslationKeys.contactUs),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Selettore problema (come pulsante che apre il menu)
                          Text(
                            _getTranslation(TranslationKeys.selectProblem),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _showProblemSelector = !_showProblemSelector;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedProblem != null
                                        ? _getTranslation(_selectedProblem!)
                                        : _getTranslation(TranslationKeys.selectProblem),
                                    style: TextStyle(
                                      color: _selectedProblem != null
                                          ? Colors.black87
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  Icon(
                                    _showProblemSelector
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey[700],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Campo mittente
                          Text(
                            _getTranslation(TranslationKeys.sender),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senderController,
                            decoration: InputDecoration(
                              hintText: _getTranslation(TranslationKeys.enterUsername),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _getTranslation(TranslationKeys.usernameRequired);
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo messaggio
                          Text(
                            _getTranslation(TranslationKeys.message),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: _getTranslation(TranslationKeys.message),
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
                            maxLines: 8,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _getTranslation(TranslationKeys.message) + ' ' + _getTranslation(TranslationKeys.emailRequired).toLowerCase();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Pulsante invio
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _sendMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _getTranslation(TranslationKeys.sendEmail),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Selettore problemi (visibile solo quando _showProblemSelector è true)
              if (_showProblemSelector)
                Positioned(
                  top: 165, // Posizionato sotto il pulsante di selezione
                  left: 24,
                  right: 24,
                  child: Container(
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
                            _getTranslation(TranslationKeys.selectProblem),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Divider(color: Colors.white24, height: 1),
                        ...List.generate(_problemKeys.length, (index) {
                          return _problemOption(_problemKeys[index]);
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _problemOption(String problemKey) {
    final isSelected = _selectedProblem == problemKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedProblem = problemKey;
          _showProblemSelector = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
                _getTranslation(problemKey),
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