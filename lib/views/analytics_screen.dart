import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 7; // 1 for 24h, 7 for 7 days

  // Mock historical points for soil moisture (7 days)
  final List<double> _soil7Days = [52.0, 48.0, 42.0, 24.5, 68.0, 54.0, 45.0];
  final List<String> _days7 = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  // Mock historical points for air temperature (7 days)
  final List<double> _temp7Days = [22.4, 25.1, 28.6, 32.2, 23.5, 24.0, 24.2];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.tr('analytics_title')),
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
                            color: _selectedPeriod == 1 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.tr('period_24h'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedPeriod == 1 ? Colors.white : AppTheme.textSecondary,
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
                            color: _selectedPeriod == 7 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.tr('period_7d'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedPeriod == 7 ? Colors.white : AppTheme.textSecondary,
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

              const SizedBox(height: 20),

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
                    const Icon(Icons.water_drop_outlined, color: AppTheme.statusWarning, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Сценарий 4 (ТЗ): Анализ полива',
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

              // CHART 1: SOIL MOISTURE (M6)
              _buildChartCard(
                title: l10n.tr('chart_soil_title'),
                unit: '%',
                icon: Icons.grass_rounded,
                color: AppTheme.primary,
                values: _selectedPeriod == 7 ? _soil7Days : [45.0, 44.2, 43.1, 42.0, 58.0, 54.0],
                labels: _selectedPeriod == 7 ? _days7 : ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'],
                threshold: 30.0,
                thresholdLabel: 'Порог засухи (30%)',
              ),

              const SizedBox(height: 18),

              // CHART 2: AIR TEMPERATURE (M6)
              _buildChartCard(
                title: l10n.tr('chart_temp_title'),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFE65100),
                values: _selectedPeriod == 7 ? _temp7Days : [18.2, 17.5, 21.0, 26.5, 25.0, 22.1],
                labels: _selectedPeriod == 7 ? _days7 : ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'],
                threshold: 28.0,
                thresholdLabel: 'Порог перегрева (28°C)',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Макс: ${maxVal.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom responsive bar/histogram rendering
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(values.length, (index) {
                final val = values[index];
                final isAlert = val < threshold && title.contains('влажности');
                final heightFactor = ((val - (minVal * 0.7)) / (maxVal * 1.1)).clamp(0.15, 1.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isAlert ? AppTheme.statusDanger : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        color: isAlert ? AppTheme.statusDanger : color.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 12, height: 3, color: AppTheme.statusDanger),
              const SizedBox(width: 6),
              Text(
                thresholdLabel,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
