import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MetricStatus { normal, warning, danger }

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final MetricStatus status;
  final String statusText;
  final double progress; // 0.0 to 1.0

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.statusText,
    required this.progress,
  });

  Color get statusColor {
    switch (status) {
      case MetricStatus.normal:
        return AppTheme.statusSuccess;
      case MetricStatus.warning:
        return AppTheme.statusWarning;
      case MetricStatus.danger:
        return AppTheme.statusDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.dividerColor,
            color: statusColor,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
