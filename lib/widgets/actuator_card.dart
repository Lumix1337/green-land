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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.dividerColor,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? AppTheme.primary.withOpacity(0.08) 
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppTheme.primary.withOpacity(0.15) 
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primaryDark : AppTheme.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? AppTheme.statusSuccess.withOpacity(0.12) 
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? activeText : inactiveText,
                        style: TextStyle(
                          color: isActive ? AppTheme.statusSuccess : Colors.grey[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isActive,
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.accentMint.withOpacity(0.4),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppTheme.dividerColor,
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}
