// lib/shared/widgets/settings_item.dart

import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData? iconData;
  final Color iconColor;
  final bool isToggle;
  final bool isEnabled;
  final bool isLink;
  final Function(bool)? onToggle;
  final VoidCallback? onTap;

  const SettingsItem({
    Key? key,
    required this.title,
    required this.description,
    this.iconData,
    this.iconColor = Colors.blue,
    this.isToggle = false,
    this.isEnabled = false,
    this.isLink = false,
    this.onToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF424242),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLink ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Testo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Switch o icona freccia
              if (isToggle)
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: Colors.green,
                )
              else if (isLink)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}