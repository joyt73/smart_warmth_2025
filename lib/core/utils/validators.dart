// lib/utils/validator.dart
import 'package:flutter/material.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';

class Validator {
  // Validazione email
  static String? validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.translate('email_required');
    }

    // Validazione del formato email con RegExp
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return l10n.translate('valid_email_required');
    }

    return null;
  }

  // Validazione password
  static String? validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.translate('password_required');
    }

    if (value.length < 6) {
      return l10n.translate('password_too_short');
    }

    return null;
  }

  // Validazione nome utente
  static String? validateUsername(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.translate('username_required');
    }

    return null;
  }

  // Validazione nome stanza
  static String? validateRoomName(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.translate('room_name_required');
    }

    return null;
  }

  // Validazione nome dispositivo
  static String? validateDeviceName(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return 'Il nome del dispositivo è obbligatorio';
    }

    return null;
  }

  // Validazione seriale dispositivo
  static String? validateDeviceSerial(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return 'Il seriale del dispositivo è obbligatorio';
    }

    // Verifica che il seriale sia nel formato numerico
    final serialRegex = RegExp(r'^\d+$');
    if (!serialRegex.hasMatch(value)) {
      return 'Il seriale deve essere un numero';
    }

    return null;
  }

  // Validazione per le temperature
  static String? validateTemperature(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return 'La temperatura è obbligatoria';
    }

    // Verifica che sia un numero valido
    try {
      final temp = double.parse(value);
      if (temp < 7.0 || temp > 30.0) {
        return 'La temperatura deve essere tra 7°C e 30°C';
      }
    } catch (e) {
      return 'Inserisci un valore numerico valido';
    }

    return null;
  }
}