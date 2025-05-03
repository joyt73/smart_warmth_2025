import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_warmth_2025/core/services/app_settings_service.dart';

class PermissionsState {
  final bool camera;
  final bool location;
  final bool bluetoothScan;
  final bool bluetoothConnect;

  // Aggiungiamo le proprietà per tracciare se i permessi sono stati negati permanentemente
  final bool cameraPermanentlyDenied;
  final bool locationPermanentlyDenied;
  final bool bluetoothScanPermanentlyDenied;
  final bool bluetoothConnectPermanentlyDenied;

  PermissionsState({
    this.camera = false,
    this.location = false,
    this.bluetoothScan = false,
    this.bluetoothConnect = false,
    this.cameraPermanentlyDenied = false,
    this.locationPermanentlyDenied = false,
    this.bluetoothScanPermanentlyDenied = false,
    this.bluetoothConnectPermanentlyDenied = false,
  });

  PermissionsState copyWith({
    bool? camera,
    bool? location,
    bool? bluetoothScan,
    bool? bluetoothConnect,
    bool? cameraPermanentlyDenied,
    bool? locationPermanentlyDenied,
    bool? bluetoothScanPermanentlyDenied,
    bool? bluetoothConnectPermanentlyDenied,
  }) {
    return PermissionsState(
      camera: camera ?? this.camera,
      location: location ?? this.location,
      bluetoothScan: bluetoothScan ?? this.bluetoothScan,
      bluetoothConnect: bluetoothConnect ?? this.bluetoothConnect,
      cameraPermanentlyDenied: cameraPermanentlyDenied ?? this.cameraPermanentlyDenied,
      locationPermanentlyDenied: locationPermanentlyDenied ?? this.locationPermanentlyDenied,
      bluetoothScanPermanentlyDenied: bluetoothScanPermanentlyDenied ?? this.bluetoothScanPermanentlyDenied,
      bluetoothConnectPermanentlyDenied: bluetoothConnectPermanentlyDenied ?? this.bluetoothConnectPermanentlyDenied,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(PermissionsState());

  Future<void> checkAllPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

    state = state.copyWith(
      camera: cameraStatus.isGranted,
      location: locationStatus.isGranted,
      bluetoothScan: bluetoothScanStatus.isGranted,
      bluetoothConnect: bluetoothConnectStatus.isGranted,
      cameraPermanentlyDenied: cameraStatus.isPermanentlyDenied,
      locationPermanentlyDenied: locationStatus.isPermanentlyDenied,
      bluetoothScanPermanentlyDenied: bluetoothScanStatus.isPermanentlyDenied,
      bluetoothConnectPermanentlyDenied: bluetoothConnectStatus.isPermanentlyDenied,
    );
  }

  Future<bool> requestPermission(String permissionType) async {
    Permission permission;

    switch (permissionType) {
      case 'camera':
        permission = Permission.camera;
        break;
      case 'location':
        permission = Permission.location;
        break;
      case 'bluetoothScan':
        permission = Permission.bluetoothScan;
        break;
      case 'bluetoothConnect':
        permission = Permission.bluetoothConnect;
        break;
      default:
        throw Exception('Tipo di permesso non valido');
    }

    // Controlla se il permesso è già stato negato permanentemente
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      return false; // Non è possibile richiedere il permesso, deve essere fatto dalle impostazioni
    }

    // Richiedi il permesso se non è stato negato permanentemente
    final result = await permission.request();

    // Aggiorna lo stato
    await checkAllPermissions();

    return result.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    // Controlla lo stato di tutti i permessi prima di richiederli
    await checkAllPermissions();

    // Prepara una lista di permessi da richiedere (escludi quelli negati permanentemente)
    List<Future<PermissionStatus>> permissionRequests = [];

    if (!state.cameraPermanentlyDenied) {
      permissionRequests.add(Permission.camera.request());
    }

    if (!state.locationPermanentlyDenied) {
      permissionRequests.add(Permission.location.request());
    }

    if (!state.bluetoothScanPermanentlyDenied) {
      permissionRequests.add(Permission.bluetoothScan.request());
    }

    if (!state.bluetoothConnectPermanentlyDenied) {
      permissionRequests.add(Permission.bluetoothConnect.request());
    }

    // Richiedi tutti i permessi non negati permanentemente
    if (permissionRequests.isNotEmpty) {
      final results = await Future.wait(permissionRequests);

      // Aggiorna lo stato dopo aver richiesto i permessi
      await checkAllPermissions();

      // Restituisci true solo se tutti i permessi sono stati concessi
      return state.camera && state.location && state.bluetoothScan && state.bluetoothConnect;
    } else {
      return false;
    }
  }

  Future<void> openAppPermissionSettings(String permissionType) async {
    await AppSettingsService.openPermissionSettings(permissionType);
    // Dopo che l'utente torna alle impostazioni, aggiorna lo stato dei permessi
    await Future.delayed(const Duration(milliseconds: 500));
    await checkAllPermissions();
  }

  // Metodo per aprire le impostazioni dell'app
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Errore nell\'apertura delle impostazioni: $e');
    }
  }

  // Ottieni lo stato di un permesso specifico
  bool isPermissionGranted(String permissionType) {
    switch (permissionType) {
      case 'camera':
        return state.camera;
      case 'location':
        return state.location;
      case 'bluetoothScan':
        return state.bluetoothScan;
      case 'bluetoothConnect':
        return state.bluetoothConnect;
      default:
        return false;
    }
  }

  // Controlla se un permesso è stato negato permanentemente
  bool isPermissionPermanentlyDenied(String permissionType) {
    switch (permissionType) {
      case 'camera':
        return state.cameraPermanentlyDenied;
      case 'location':
        return state.locationPermanentlyDenied;
      case 'bluetoothScan':
        return state.bluetoothScanPermanentlyDenied;
      case 'bluetoothConnect':
        return state.bluetoothConnectPermanentlyDenied;
      default:
        return false;
    }
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});