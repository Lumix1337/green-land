import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final bool isOffline;
  final bool isAllGood;
  final bool hasAlert;
  final String? alertMessage;
  final String statusText;
  final String lastUpdateText;
  final String offlineTitle;
  final String offlineDesc;
  final VoidCallback? onDismissAlert;

  const StatusBanner({
    super.key,
    required this.isOffline,
    required this.isAllGood,
    required this.hasAlert,
    this.alertMessage,
    required this.statusText,
    required this.lastUpdateText,
    required this.offlineTitle,
    required this.offlineDesc,
    this.onDismissAlert,
  });

  @override
  Widget build(BuildContext context) {
    // 1. M8: OFFLINE BANNER (Failure handling)
    if (isOffline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.statusWarning, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offlineTitle,
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offlineDesc,
                    style: const TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. M5: CRITICAL ALERT BANNER (Overheat / Threshold breach)
    if (hasAlert && alertMessage != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.statusDanger.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.statusDanger, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alertMessage!,
                    style: const TextStyle(
                      color: AppTheme.statusDanger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Нажмите «Управление», чтобы охладить теплицу',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onDismissAlert != null)
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.statusDanger, size: 18),
                onPressed: onDismissAlert,
              ),
          ],
        ),
      );
    }

    // 3. M2: NORMAL HEALTH SUMMARY (5-second quick check)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isAllGood ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAllGood 
              ? AppTheme.primaryLight.withOpacity(0.3) 
              : AppTheme.statusWarning.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isAllGood ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isAllGood ? AppTheme.primaryDark : AppTheme.statusWarning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  color: isAllGood ? AppTheme.primaryDark : const Color(0xFFE65100),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            lastUpdateText,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
