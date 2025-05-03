/*import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Test',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const WifiTestPage(),
    );
  }
}

class WifiTestPage extends StatefulWidget {
  const WifiTestPage({Key? key}) : super(key: key);

  @override
  State<WifiTestPage> createState() => _WifiTestPageState();
}

class _WifiTestPageState extends State<WifiTestPage> {
  List<String> _networks = [];
  String? _currentSSID;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorMessage;

  // Controller per i campi di testo
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Controlla la connessione WiFi attuale
  Future<void> _checkCurrentConnection() async {
    try {
      if (Platform.isAndroid) {
        final ssid = await WiFiForIoTPlugin.getSSID();
        final isConnected = await WiFiForIoTPlugin.isConnected();

        setState(() {
          _currentSSID = ssid;
          _isConnected = isConnected && ssid != null && ssid.isNotEmpty;
          _errorMessage = null;
        });
      } else if (Platform.isIOS) {
        // Su iOS non possiamo ottenere direttamente l'SSID corrente
        final isConnected = await WiFiForIoTPlugin.isConnected();
        setState(() {
          _isConnected = isConnected;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Errore nella verifica della connessione WiFi: $e');
    }
  }

  // Richiedi i permessi necessari
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      List<Permission> requiredPermissions = [];

      // Permessi di localizzazione (necessari per la scansione WiFi)
      requiredPermissions.add(Permission.location);

      // Permessi per Android 13+ (API 33)
      if (await Permission.nearbyWifiDevices.isPermanentlyDenied == false) {
        requiredPermissions.add(Permission.nearbyWifiDevices);
      }

      // Richiediamo tutti i permessi necessari
      Map<Permission, PermissionStatus> statuses = await requiredPermissions.request();

      // Verifichiamo che tutti i permessi necessari siano stati concessi
      bool allGranted = true;
      for (var entry in statuses.entries) {
        if (!entry.value.isGranted) {
          allGranted = false;
          debugPrint('Permesso non concesso: ${entry.key}');
        }
      }

      return allGranted;
    }

    // Su iOS non ci sono permessi da richiedere per il WiFi
    return true;
  }

  // Scansiona le reti WiFi disponibili
  Future<void> _scanNetworks() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _networks = [];
    });

    try {
      List<String> networks = [];

      // Verifichiamo i permessi
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        setState(() {
          _errorMessage = 'Permessi necessari non concessi';
          _isScanning = false;
        });
        return;
      }

      if (Platform.isAndroid) {
        // Verifichiamo che il WiFi sia attivo
        final isEnabled = await WiFiForIoTPlugin.isEnabled();
        if (!isEnabled) {
          try {
            // Tentiamo di attivare il WiFi
            await WiFiForIoTPlugin.setEnabled(true);
            // Attendiamo che il WiFi si attivi
            await Future.delayed(const Duration(seconds: 2));
          } catch (e) {
            setState(() {
              _errorMessage = 'Impossibile attivare il WiFi. Attivalo manualmente';
              _isScanning = false;
            });
            return;
          }
        }

        // Utilizziamo WiFiScan su Android per ottenere la lista delle reti
        final canScan = await WiFiScan.instance.canStartScan();
        if (canScan == CanStartScan.yes) {
          try {
            await WiFiScan.instance.startScan();
            // Attendiamo un po' per permettere la scansione
            await Future.delayed(const Duration(seconds: 3));
            final accessPoints = await WiFiScan.instance.getScannedResults();
            networks = accessPoints
                .map((ap) => ap.ssid)
                .where((ssid) => ssid.isNotEmpty)
                .toList();
          } catch (e) {
            setState(() {
              _errorMessage = 'Errore durante la scansione WiFi: $e';
            });
          }
        } else if (canScan == CanStartScan.notSupported) {
          setState(() {
            _errorMessage = 'Scansione WiFi non supportata su questo dispositivo';
          });
        } else {
          setState(() {
            _errorMessage = 'Impossibile avviare la scansione WiFi: ${canScan.toString()}';
          });
        }
      } else if (Platform.isIOS) {
        // Su iOS, mostriamo un messaggio specifico
        setState(() {
          _errorMessage = 'Su iOS non è possibile scansionare le reti WiFi. Usa le impostazioni di sistema';
        });

        // Tentiamo comunque di verificare la connessione corrente
        final isConnected = await WiFiForIoTPlugin.isConnected();
        if (isConnected) {
          try {
            final currentSSID = await WiFiForIoTPlugin.getSSID();
            if (currentSSID != null && currentSSID.isNotEmpty) {
              networks = [currentSSID];
              setState(() {
                _currentSSID = currentSSID;
              });
            }
          } catch (e) {
            debugPrint('Impossibile ottenere SSID su iOS: $e');
          }
        }
      }

      // Rimuoviamo i duplicati e ordiniamo alfabeticamente
      networks = networks.toSet().toList()..sort();

      setState(() {
        _networks = networks;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nella scansione delle reti WiFi: $e';
        _isScanning = false;
      });
    }
  }

  // Connetti a una rete WiFi
  Future<void> _connectToNetwork(String ssid, String password) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      if (Platform.isAndroid) {
        // Verifichiamo che il WiFi sia attivo
        final isEnabled = await WiFiForIoTPlugin.isEnabled();
        if (!isEnabled) {
          try {
            await WiFiForIoTPlugin.setEnabled(true);
            // Attendiamo che il WiFi si attivi
            await Future.delayed(const Duration(seconds: 2));
          } catch (e) {
            setState(() {
              _errorMessage = 'Impossibile attivare il WiFi. Attivalo manualmente';
              _isConnecting = false;
            });
            return;
          }
        }

        // Prima disconnettiamo da eventuali reti
        try {
          await WiFiForIoTPlugin.disconnect();
          // Breve attesa per permettere la disconnessione
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Errore nella disconnessione: $e');
          // Continuiamo comunque
        }

        // Tentiamo di connetterci
        NetworkSecurity security = NetworkSecurity.WPA;

        // Determiniamo il tipo di sicurezza in base alla password
        if (password.isEmpty) {
          security = NetworkSecurity.NONE;
        } else if (password.length == 10 || password.length == 26) {
          // Potrebbe essere una chiave WEP
          security = NetworkSecurity.WEP;
        }

        final result = await WiFiForIoTPlugin.connect(
          ssid,
          password: password,
          security: security,
          withInternet: true,
        );

        if (result) {
          // Attendiamo un po' per permettere alla connessione di stabilizzarsi
          await Future.delayed(const Duration(seconds: 2));

          // Verifichiamo la connessione effettiva
          await _checkCurrentConnection();

          setState(() {
            _isConnecting = false;
            _errorMessage = 'Connesso a $ssid';
          });

          // Puliamo i campi
          _ssidController.clear();
          _passwordController.clear();
        } else {
          setState(() {
            _errorMessage = 'Impossibile connettersi alla rete $ssid';
            _isConnecting = false;
          });
        }
      } else if (Platform.isIOS) {
        // Su iOS non possiamo connetterci direttamente a una rete
        setState(() {
          _errorMessage = 'Su iOS, utilizzare le impostazioni di sistema per connettersi alla rete WiFi';
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nella connessione alla rete WiFi: $e';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkCurrentConnection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connessione corrente
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stato connessione',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isConnected
                                ? 'Connesso a: $_currentSSID'
                                : 'Non connesso',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scansione reti
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reti disponibili',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Scansiona'),
                          onPressed: _isScanning ? null : _scanNetworks,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isScanning)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_networks.isEmpty)
                      const Text('Nessuna rete trovata. Premi "Scansiona" per cercare reti WiFi.')
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _networks.length,
                          itemBuilder: (context, index) {
                            final network = _networks[index];
                            final isConnected = network == _currentSSID;

                            return ListTile(
                              leading: Icon(
                                Icons.wifi,
                                color: isConnected ? Colors.green : Colors.white,
                              ),
                              title: Text(network),
                              subtitle: isConnected ? const Text('Connesso') : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () {
                                  _ssidController.text = network;
                                  // Facciamo scorrere la pagina verso il basso
                                  Scrollable.ensureVisible(
                                    _connectFormKey.currentContext!,
                                    duration: const Duration(milliseconds: 300),
                                  );
                                },
                                tooltip: 'Connetti a questa rete',
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Form di connessione
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _connectFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connetti a una rete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ssidController,
                        decoration: const InputDecoration(
                          labelText: 'SSID',
                          hintText: 'Nome della rete WiFi',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isConnecting,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Password della rete WiFi',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        enabled: !_isConnecting,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isConnecting
                              ? null
                              : () {
                            if (_ssidController.text.isNotEmpty) {
                              _connectToNetwork(
                                _ssidController.text,
                                _passwordController.text,
                              );
                            }
                          },
                          child: _isConnecting
                              ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Connessione in corso...'),
                            ],
                          )
                              : const Text('Connetti'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Messaggi di errore o successo
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errorMessage!.contains('Connesso')
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _errorMessage!.contains('Connesso')
                          ? Icons.check_circle
                          : Icons.error,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Chiave globale per il form di connessione
  final GlobalKey _connectFormKey = GlobalKey();
}*/


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_warmth_2025/config/router.dart';
import 'package:smart_warmth_2025/config/themes.dart';
import 'package:smart_warmth_2025/core/graphql/client.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';
import 'package:smart_warmth_2025/core/providers/locale_provider.dart';
import 'package:smart_warmth_2025/core/providers/room_provider.dart';
import 'package:smart_warmth_2025/core/providers/utility_provider.dart';
import 'package:smart_warmth_2025/features/device/providers/device_provider.dart';
import 'package:smart_warmth_2025/core/services/locale_service.dart';
import 'package:smart_warmth_2025/shared/widgets/overlay_alert.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inizializza il client GraphQL
  await GraphQLClientService.instance.init();

  // Imposta l'orientamento dell'app (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Prefetch data
    ref.read(roomsProvider.notifier).refreshRooms();
    ref.read(devicesProvider.notifier).loadDevices();

    return MaterialApp.router(
      title: 'Smart Warmth',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: LocaleService.supportedLocales.values,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Qui includiamo il nostro OverlayAlert che sarà visibile in tutta l'app
            const OverlayAlert(),
          ],
        );
      },
    );
  }
}
