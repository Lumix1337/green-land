import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class FlTelemetryChart extends StatelessWidget {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final List<double> values;
  final List<String> labels;
  final double threshold;
  final String thresholdLabel;

  const FlTelemetryChart({
    super.key,
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.values,
    required this.labels,
    required this.threshold,
    required this.thresholdLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double yMin = (minVal * 0.8).clamp(0.0, double.infinity);
    final double yMax = maxVal * 1.15;

    final spots =
        List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // FL_CHART LINE CHART COMPONENT (M6)
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: yMin,
                maxY: yMax,
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      (yMax - yMin) / 3 > 0 ? (yMax - yMin) / 3 : 5.0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.dividerColor.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: threshold,
                      color: AppTheme.statusDanger,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 2),
                        style: const TextStyle(
                          color: AppTheme.statusDanger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) =>
                            '${threshold.toStringAsFixed(0)}$unit',
                      ),
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isAlert = spot.y < threshold && unit == '%';
                        return FlDotCirclePainter(
                          radius: isAlert ? 5.5 : 4,
                          color: isAlert ? AppTheme.statusDanger : Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: isAlert ? Colors.white : color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 14, height: 3, color: AppTheme.statusDanger),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(
                thresholdLabel,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
