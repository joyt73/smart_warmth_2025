import 'package:flutter/material.dart';
import 'package:smart_warmth_2025/core/i18n/app_localizations.dart';

class PasswordRecoveryConfirmation extends StatelessWidget {
  final String email;

  const PasswordRecoveryConfirmation({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String translatedTitle = AppLocalizations.of(context).translate('password_recovery');
    final String translatedMessage = AppLocalizations.of(context).translate('email_sent');
    final String translatedSpamMessage = AppLocalizations.of(context).translate('check_spam');
    final String translatedButtonText = AppLocalizations.of(context).translate('reset_password');
    final String translatedRecoverySent = AppLocalizations.of(context).translate('password_recovery_sent');
    final String translatedCheckSpam = AppLocalizations.of(context).translate('check_spam_folder');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            translatedMessage,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Campo email
        Text(
          AppLocalizations.of(context).translate('email'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            email,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Pulsante di recupero
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null, // Disabilitato
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: Text(
              translatedButtonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Messaggio di recupero password
        Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translatedRecoverySent,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translatedCheckSpam,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}