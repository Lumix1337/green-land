import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final bool isOffline;
  final bool isAllGood;
  final bool hasAlert;
  final String? alertMessage;
  final String? alertActionText;
  final VoidCallback? onOpenControls;
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
    this.alertActionText,
    this.onOpenControls,
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
            const Icon(Icons.cloud_off_rounded,
                color: AppTheme.statusWarning, size: 28),
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
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppTheme.statusDanger,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onOpenControls,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alertMessage!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        if (alertActionText != null &&
                            onOpenControls != null) ...[
                          const SizedBox(height: 6),
                          Text('$alertActionText →',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (onDismissAlert != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onDismissAlert,
                ),
            ],
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText,
              style: TextStyle(
                  color: isAllGood
                      ? AppTheme.primaryDark
                      : const Color(0xFFA65100),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(lastUpdateText,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
