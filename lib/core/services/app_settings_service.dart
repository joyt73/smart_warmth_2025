import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AppSettingsService {
  static const platform = MethodChannel('com.tuazienda.smart_warmth_2025/app_settings');

  static Future<void> openPermissionSettings(String permissionType) async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('openAppPermissionSettings', {'permissionType': permissionType});
      } else {
        // Su iOS, apri le impostazioni generali dell'app
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Errore nell\'apertura delle impostazioni: $e');
      // Fallback al metodo standard
      await openAppSettings();
    }
  }
}