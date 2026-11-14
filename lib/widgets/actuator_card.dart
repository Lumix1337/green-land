import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActuatorCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final String activeText;
  final String inactiveText;
  final ValueChanged<bool> onToggle;

  const ActuatorCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(isActive ? activeText : inactiveText,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: title,
              child: Switch(
                value: isActive,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppTheme.dividerColor,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                onChanged: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
