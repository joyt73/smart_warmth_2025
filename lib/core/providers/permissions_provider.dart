import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsState {
  final bool camera;
  final bool location;
  final bool bluetoothScan;
  final bool bluetoothConnect;

  PermissionsState({
    this.camera = false,
    this.location = false,
    this.bluetoothScan = false,
    this.bluetoothConnect = false,
  });

  PermissionsState copyWith({
    bool? camera,
    bool? location,
    bool? bluetoothScan,
    bool? bluetoothConnect,
  }) {
    return PermissionsState(
      camera: camera ?? this.camera,
      location: location ?? this.location,
      bluetoothScan: bluetoothScan ?? this.bluetoothScan,
      bluetoothConnect: bluetoothConnect ?? this.bluetoothConnect,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(PermissionsState());

  Future<void> checkAllPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    bool bluetoothScanStatus = false;
    bool bluetoothConnectStatus = false;

    if (Platform.isAndroid) {
      // Android 12+ richiede permessi bluetooth specifici
      bluetoothScanStatus = await Permission.bluetooth.status.isGranted ||
          await Permission.bluetoothScan.status.isGranted;
      bluetoothConnectStatus = await Permission.bluetooth.status.isGranted ||
          await Permission.bluetoothConnect.status.isGranted;
    } else if (Platform.isIOS) {
      // Su iOS è sufficiente il permesso bluetooth generale
      bluetoothScanStatus = await Permission.bluetooth.status.isGranted;
      bluetoothConnectStatus = await Permission.bluetooth.status.isGranted;
    }

    state = state.copyWith(
      camera: cameraStatus.isGranted,
      location: locationStatus.isGranted,
      bluetoothScan: bluetoothScanStatus,
      bluetoothConnect: bluetoothConnectStatus,
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
        if (Platform.isAndroid) {
          permission = Permission.bluetoothScan;
        } else {
          permission = Permission.bluetooth;
        }
        break;
      case 'bluetoothConnect':
        if (Platform.isAndroid) {
          permission = Permission.bluetoothConnect;
        } else {
          permission = Permission.bluetooth;
        }
        break;
      default:
        throw Exception('Tipo di permesso non supportato: $permissionType');
    }

    final status = await permission.request();
    bool isGranted = status.isGranted;

    // Aggiorniamo lo stato
    if (permissionType == 'camera') {
      state = state.copyWith(camera: isGranted);
    } else if (permissionType == 'location') {
      state = state.copyWith(location: isGranted);
    } else if (permissionType == 'bluetoothScan') {
      state = state.copyWith(bluetoothScan: isGranted);
    } else if (permissionType == 'bluetoothConnect') {
      state = state.copyWith(bluetoothConnect: isGranted);
    }

    return isGranted;
  }

  Future<bool> requestAllPermissions() async {
    final cameraGranted = await requestPermission('camera');
    final locationGranted = await requestPermission('location');
    final bluetoothScanGranted = await requestPermission('bluetoothScan');
    final bluetoothConnectGranted = await requestPermission('bluetoothConnect');

    // Consideriamo il risultato complessivo
    return cameraGranted && locationGranted && bluetoothScanGranted && bluetoothConnectGranted;
  }

  bool areAllPermissionsGranted() {
    return state.camera &&
        state.location &&
        state.bluetoothScan &&
        state.bluetoothConnect;
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});