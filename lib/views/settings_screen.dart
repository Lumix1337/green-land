import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/savings_card.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;
    final settings = provider.settings;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.tr('settings_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SIGNATURE FEATURE: ENERGY & TARIFFS OPTIMIZER (Resource Savings Track)
              SavingsCard(
                monthlySavedTenge: settings.monthlySavedTenge,
                dayTariff: settings.dayTariffKzt,
                nightTariff: settings.nightTariffKzt,
                title: l10n.tr('signature_feature_title'),
                subtitle: l10n.tr('energy_saved_month'),
                dayTariffLabel: l10n.tr('day_tariff_badge'),
                nightTariffLabel: l10n.tr('night_tariff_badge'),
              ),

              const SizedBox(height: 24),

              // PERSONA PROFILE CARD (CP1 requirement)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      child: const Text(
                        'Е',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ерлан (Владелец теплицы)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.userEmail,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '800 м² • Тепличные томаты',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // LANGUAGE SWITCHER (Bonus credit in creative part)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.translate_rounded, color: AppTheme.primary, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Тіл / Язык интерфейса',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SegmentedButton<AppLanguage>(
                      segments: const [
                        ButtonSegment(value: AppLanguage.ru, label: Text('РУС')),
                        ButtonSegment(value: AppLanguage.kz, label: Text('ҚАЗ')),
                      ],
                      selected: {provider.language},
                      onSelectionChanged: (Set<AppLanguage> newSelection) {
                        provider.switchLanguage(newSelection.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // AUTOMATION THRESHOLDS (M7)
              Text(
                l10n.tr('thresholds_header'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              // Threshold Slider 1: Soil Moisture
              Container(
                padding: const EdgeInsets.all(18),
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
                        Flexible(
                          child: Text(
                            l10n.tr('min_soil_threshold'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${settings.minSoilMoisture.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.minSoilMoisture,
                      min: 15.0,
                      max: 60.0,
                      divisions: 9,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        provider.updateThresholds(minSoil: val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Threshold Slider 2: Max Air Temp (Ventilation)
              Container(
                padding: const EdgeInsets.all(18),
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
                        Flexible(
                          child: Text(
                            l10n.tr('max_temp_threshold'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${settings.maxAirTemp.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.maxAirTemp,
                      min: 22.0,
                      max: 38.0,
                      divisions: 16,
                      activeColor: const Color(0xFFE65100),
                      onChanged: (val) {
                        provider.updateThresholds(maxTemp: val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // DEFENSE STRESS TEST SWITCH (M8)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_rounded, color: Color(0xFFF57F17), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tr('test_offline_mode'),
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Для демонстрации стресс-теста комиссии',
                            style: TextStyle(
                              color: Color(0xFF8D6E63),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.isOffline,
                      activeColor: const Color(0xFFE65100),
                      onChanged: (val) => provider.toggleOfflineStressTest(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // LOGOUT BUTTON (M1)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.statusDanger,
                  side: const BorderSide(color: AppTheme.dividerColor),
                ),
                onPressed: () {
                  provider.logout();
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.statusDanger),
                label: const Text('Выйти из системы'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
