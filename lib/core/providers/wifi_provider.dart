import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';  // versione ^12.0.0
import 'package:wifi_scan/wifi_scan.dart';  // versione ^0.4.1+2
import 'package:wifi_iot/wifi_iot.dart';    // versione ^0.3.19+2

class WifiState {
  final String savedSSID;
  final String savedPassword;
  final bool isConnected;
  final String? currentSSID;
  final List<String> availableNetworks;
  final String? errorMessage;
  final bool isScanning;
  final bool isConnecting;

  WifiState({
    this.savedSSID = '',
    this.savedPassword = '',
    this.isConnected = false,
    this.currentSSID,
    this.availableNetworks = const [],
    this.errorMessage,
    this.isScanning = false,
    this.isConnecting = false,
  });

  WifiState copyWith({
    String? savedSSID,
    String? savedPassword,
    bool? isConnected,
    String? currentSSID,
    List<String>? availableNetworks,
    String? errorMessage,
    bool? isScanning,
    bool? isConnecting,
  }) {
    return WifiState(
      savedSSID: savedSSID ?? this.savedSSID,
      savedPassword: savedPassword ?? this.savedPassword,
      isConnected: isConnected ?? this.isConnected,
      currentSSID: currentSSID ?? this.currentSSID,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      errorMessage: errorMessage,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
    );
  }
}

class WifiNotifier extends StateNotifier<WifiState> {
  Timer? _connectionCheckTimer;

  WifiNotifier() : super(WifiState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSavedNetwork();
    await _checkCurrentConnection();

    // Configuriamo un timer per verificare periodicamente la connessione
    _connectionCheckTimer = Timer.periodic(
        const Duration(seconds: 10),
            (_) => _checkCurrentConnection()
    );
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedNetwork() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSSID = prefs.getString('wifi_ssid') ?? '';
      final savedPassword = prefs.getString('wifi_password') ?? '';
      state = state.copyWith(
        savedSSID: savedSSID,
        savedPassword: savedPassword,
      );
    } catch (e) {
      _setError('Errore nel caricamento delle impostazioni WiFi: $e');
    }
  }

  Future<void> _checkCurrentConnection() async {
    try {
      if (Platform.isAndroid) {
        // Utilizziamo getSSID e isConnected
        final ssid = await WiFiForIoTPlugin.getSSID();
        final isConnected = await WiFiForIoTPlugin.isConnected();

        state = state.copyWith(
          currentSSID: ssid,
          isConnected: isConnected && ssid != null && ssid.isNotEmpty,
          errorMessage: null,
        );
      } else if (Platform.isIOS) {
        // Su iOS non possiamo ottenere direttamente l'SSID corrente
        final isConnected = await WiFiForIoTPlugin.isConnected();
        state = state.copyWith(
          isConnected: isConnected,
          errorMessage: null,
        );
      }
    } catch (e) {
      debugPrint('Errore nella verifica della connessione WiFi: $e');
      // Non impostiamo un errore di UI qui poiché è una verifica periodica
    }
  }

  // Metodo helper per impostare messaggi di errore
  void _setError(String message) {
    debugPrint(message);
    state = state.copyWith(errorMessage: message);
  }

  // Metodo helper per cancellare messaggi di errore
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<bool> _requestPermissions() async {
    // In permission_handler 12.0.0, il modo di richiedere i permessi è cambiato
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

  Future<List<String>> scanNetworks() async {
    // Impostiamo lo stato di scansione
    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      List<String> networks = [];

      // Verifichiamo i permessi
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        _setError('Permessi necessari non concessi');
        state = state.copyWith(isScanning: false, availableNetworks: []);
        return [];
      }

      if (Platform.isAndroid) {
        // Verifichiamo che il WiFi sia attivo
        final isEnabled = await WiFiForIoTPlugin.isEnabled();
        if (!isEnabled) {
          try {
            // Tentiamo di attivare il WiFi (potrebbe non funzionare su tutti i dispositivi)
            await WiFiForIoTPlugin.setEnabled(true);
            // Attendiamo che il WiFi si attivi
            await Future.delayed(const Duration(seconds: 2));
          } catch (e) {
            _setError('Impossibile attivare il WiFi. Attivalo manualmente');
            state = state.copyWith(isScanning: false);
            return [];
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
            _setError('Errore durante la scansione WiFi: $e');
          }
        } else if (canScan == CanStartScan.notSupported) {
          _setError('Scansione WiFi non supportata su questo dispositivo');
        } else {
          _setError('Impossibile avviare la scansione WiFi: ${canScan.toString()}');
        }
      } else if (Platform.isIOS) {
        // Su iOS, mostriamo un messaggio specifico
        _setError('Su iOS non è possibile scansionare le reti WiFi. Usa le impostazioni di sistema');

        // Tentiamo comunque di verificare la connessione corrente
        final isConnected = await WiFiForIoTPlugin.isConnected();
        if (isConnected) {
          // Su iOS potremmo non riuscire a ottenere il SSID corrente
          try {
            final currentSSID = await WiFiForIoTPlugin.getSSID();
            if (currentSSID != null && currentSSID.isNotEmpty) {
              networks = [currentSSID];
              state = state.copyWith(currentSSID: currentSSID);
            }
          } catch (e) {
            debugPrint('Impossibile ottenere SSID su iOS: $e');
          }
        }
      }

      // Rimuoviamo i duplicati e ordiniamo alfabeticamente
      networks = networks.toSet().toList()..sort();

      state = state.copyWith(
        availableNetworks: networks,
        isScanning: false,
      );

      return networks;
    } catch (e) {
      _setError('Errore nella scansione delle reti WiFi: $e');
      state = state.copyWith(
        isScanning: false,
        availableNetworks: [],
      );
      return [];
    }
  }

  Future<bool> saveNetwork(String ssid, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wifi_ssid', ssid);
      await prefs.setString('wifi_password', password);
      state = state.copyWith(
        savedSSID: ssid,
        savedPassword: password,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      _setError('Errore nel salvataggio delle credenziali WiFi: $e');
      return false;
    }
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

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
            _setError('Impossibile attivare il WiFi. Attivalo manualmente');
            state = state.copyWith(isConnecting: false);
            return false;
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
          // Salviamo le credenziali se la connessione ha avuto successo
          await saveNetwork(ssid, password);

          // Attendiamo un po' per permettere alla connessione di stabilizzarsi
          await Future.delayed(const Duration(seconds: 2));

          // Verifichiamo la connessione effettiva
          await _checkCurrentConnection();
          state = state.copyWith(isConnecting: false);
          return state.isConnected && state.currentSSID == ssid;
        } else {
          _setError('Impossibile connettersi alla rete $ssid');
          state = state.copyWith(isConnecting: false);
          return false;
        }
      } else if (Platform.isIOS) {
        // Su iOS non possiamo connetterci direttamente a una rete
        // Salviamo comunque le credenziali
        await saveNetwork(ssid, password);

        // Mostriamo un messaggio all'utente
        _setError('Su iOS, utilizzare le impostazioni di sistema per connettersi alla rete WiFi');
        state = state.copyWith(isConnecting: false);
        return false;
      }

      state = state.copyWith(isConnecting: false);
      return false;
    } catch (e) {
      _setError('Errore nella connessione alla rete WiFi: $e');
      state = state.copyWith(isConnecting: false);
      return false;
    }
  }

  Future<bool> checkSavedNetworkConnection() async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      final savedSSID = state.savedSSID;
      if (savedSSID.isEmpty) {
        state = state.copyWith(isConnecting: false);
        return false;
      }

      await _checkCurrentConnection();
      if (state.isConnected && state.currentSSID == savedSSID) {
        state = state.copyWith(isConnecting: false);
        return true;
      }

      // Se non siamo connessi alla rete salvata, tentiamo di connetterci
      if (Platform.isAndroid) {
        final result = await connectToNetwork(savedSSID, state.savedPassword);
        return result;
      } else {
        _setError('Su iOS non è possibile connettersi automaticamente alla rete $savedSSID');
        state = state.copyWith(isConnecting: false);
        return false;
      }
    } catch (e) {
      _setError('Errore nella verifica della connessione alla rete salvata: $e');
      state = state.copyWith(isConnecting: false);
      return false;
    }
  }

  // Metodo di utilità per abilitare il WiFi
  Future<bool> enableWifi() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.setEnabled(true);
      } else {
        _setError('Su iOS non è possibile attivare il WiFi programmaticamente');
        return false;
      }
    } catch (e) {
      _setError('Impossibile attivare il WiFi: $e');
      return false;
    }
  }

  // Metodo per disconnettersi dalla rete corrente
  Future<bool> disconnect() async {
    try {
      if (Platform.isAndroid) {
        return await WiFiForIoTPlugin.disconnect();
      } else {
        _setError('Su iOS non è possibile disconnettersi programmaticamente');
        return false;
      }
    } catch (e) {
      _setError('Impossibile disconnettersi: $e');
      return false;
    }
  }

  // Metodo per trovare reti specifiche (ad es. reti Smart Warmth)
  Future<List<String>> findDeviceNetworks() async {
    final networks = await scanNetworks();
    // Filtriamo per le reti che iniziano con "rad" (come nell'app originale)
    //return networks.where((ssid) => ssid.toLowerCase().startsWith('rad')).toList();
    return networks.where((ssid) => ssid.toLowerCase().startsWith('')).toList();
  }

  // Metodo per inviare credenziali WiFi home al dispositivo connesso
  Future<bool> sendHomeCredentialsToDevice(String homeSSID, String homePassword, {int port = 48899}) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      // Verifichiamo di essere connessi a una rete del dispositivo
      await _checkCurrentConnection();
      final currentSSID = state.currentSSID;

      if (currentSSID == null || !currentSSID.toLowerCase().startsWith('rad')) {
        _setError('Non sei connesso a una rete Smart Warmth');
        state = state.copyWith(isConnecting: false);
        return false;
      }

      // Qui implementeresti la logica per inviare le credenziali al dispositivo
      // Ad esempio, utilizzando Socket o UDP per inviare al dispositivo

      debugPrint('Invio credenziali WiFi home al dispositivo su rete $currentSSID');
      await Future.delayed(const Duration(seconds: 2)); // Simuliamo l'invio

      // Salviamo anche le credenziali localmente
      await saveNetwork(homeSSID, homePassword);

      state = state.copyWith(isConnecting: false);
      return true;
    } catch (e) {
      _setError('Errore nell\'invio delle credenziali al dispositivo: $e');
      state = state.copyWith(isConnecting: false);
      return false;
    }
  }
}

final wifiProvider = StateNotifierProvider<WifiNotifier, WifiState>((ref) {
  return WifiNotifier();
});