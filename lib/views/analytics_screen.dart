import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fl_telemetry_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 1; // 1 for 24h, 7 for 7 days
  bool _useLineChart = true; // FlChart LineChart vs Bar view

  // Mock historical points for soil moisture (7 days)
  final List<double> _soil7Days = [52.0, 22.0, 42.0, 68.0, 54.0, 45.0, 46.0];

  // Mock historical points for air temperature (7 days)
  final List<double> _temp7Days = [22.4, 25.1, 28.6, 32.2, 23.5, 24.0, 24.2];

  // 24 hour points
  final List<double> _soil24h = [46.0, 45.2, 44.1, 41.5, 58.0, 54.2, 51.0];
  final List<double> _temp24h = [17.5, 16.8, 20.4, 26.8, 25.2, 21.0, 19.3];
  final List<String> _hours24 = [
    '00:00',
    '04:00',
    '08:00',
    '12:00',
    '16:00',
    '20:00',
    '24:00'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;

    final soilValues = _selectedPeriod == 7 ? _soil7Days : _soil24h;
    final tempValues = _selectedPeriod == 7 ? _temp7Days : _temp24h;
    final labels =
        _selectedPeriod == 7 ? l10n.tr('weekdays_short').split(' ') : _hours24;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.tr('analytics_title')),
        actions: [
          IconButton(
            tooltip:
                _useLineChart ? l10n.tr('show_bars') : l10n.tr('show_lines'),
            icon: Icon(
              _useLineChart
                  ? Icons.bar_chart_rounded
                  : Icons.show_chart_rounded,
              color: AppTheme.primaryDark,
            ),
            onPressed: () {
              setState(() {
                _useLineChart = !_useLineChart;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PERIOD SELECTOR (24 hours vs 7 days)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 1
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.tr('period_24h'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedPeriod == 1
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = 7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 7
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.tr('period_7d'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedPeriod == 7
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedPeriod == 7) ...[
                const SizedBox(height: 12),

                // KEY SCENARIO 4: WATER DEFICIT LOG CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop_outlined,
                          color: AppTheme.statusWarning, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tr('low_soil_moisture'),
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.tr('water_deficit_event'),
                              style: const TextStyle(
                                color: Color(0xFF5D4037),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // CHART 1: SOIL MOISTURE (fl_chart M6)
              const SizedBox(height: 12),
              _buildBarChartCard(
                title: l10n.tr('chart_soil_title'),
                unit: '%',
                icon: Icons.grass_rounded,
                color: AppTheme.primaryLight,
                values: soilValues,
                labels: labels,
                threshold: 30.0,
                thresholdLabel: '${l10n.tr('drought_threshold')} (30%)',
              ),

              const SizedBox(height: 18),

              // CHART 2: AIR TEMPERATURE (fl_chart M6)
              _useLineChart
                  ? FlTelemetryChart(
                      title: l10n.tr('chart_temp_title'),
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      color: AppTheme.primary,
                      values: tempValues,
                      labels: labels,
                      threshold: 28.0,
                      thresholdLabel: '${l10n.tr('heat_threshold')} (28°C)',
                    )
                  : _buildBarChartCard(
                      title: l10n.tr('chart_temp_title'),
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      color: AppTheme.primary,
                      values: tempValues,
                      labels: labels,
                      threshold: 28.0,
                      thresholdLabel: '${l10n.tr('heat_threshold')} (28°C)',
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartCard({
    required String title,
    required String unit,
    required IconData icon,
    required Color color,
    required List<double> values,
    required List<String> labels,
    required double threshold,
    required String thresholdLabel,
  }) {
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);

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
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(values.length, (index) {
                final val = values[index];
                final isAlert = val < threshold && unit == '%';
                final heightFactor =
                    ((val - (minVal * 0.7)) / (maxVal * 1.1)).clamp(0.15, 1.0);

                return Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isAlert
                            ? AppTheme.statusDanger
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        color: isAlert
                            ? AppTheme.statusDanger
                            : color.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ));
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 12, height: 3, color: AppTheme.statusDanger),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(
                thresholdLabel,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
