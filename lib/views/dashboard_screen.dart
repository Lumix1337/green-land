import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_banner.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenControls;

  const DashboardScreen({super.key, this.onOpenControls});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;
    final telemetry = provider.telemetry;
    final settings = provider.settings;

    // Evaluate health statuses for 4 parameters using configured M7 thresholds
    // 1. Air Temperature
    final tempStatus = telemetry.airTemp > settings.maxAirTemp + 2.0
        ? MetricStatus.danger
        : (telemetry.airTemp < settings.minAirTemp ||
                telemetry.airTemp > settings.maxAirTemp)
            ? MetricStatus.warning
            : MetricStatus.normal;
    final tempStatusText = tempStatus == MetricStatus.normal
        ? l10n.tr('chip_normal')
        : (tempStatus == MetricStatus.danger
            ? l10n.tr('chip_overheat')
            : l10n.tr('chip_warning'));

    // 2. Air Humidity (Optimal: 40 - 85%)
    final humidityStatus =
        (telemetry.airHumidity < 40.0 || telemetry.airHumidity > 85.0)
            ? MetricStatus.warning
            : MetricStatus.normal;
    final humidityStatusText = humidityStatus == MetricStatus.normal
        ? l10n.tr('chip_normal')
        : l10n.tr('chip_warning');

    // 3. Soil Moisture
    final soilStatus = telemetry.soilMoisture < settings.minSoilMoisture
        ? MetricStatus.danger
        : telemetry.soilMoisture < settings.minSoilMoisture + 5.0
            ? MetricStatus.warning
            : MetricStatus.normal;
    final soilStatusText = soilStatus == MetricStatus.normal
        ? l10n.tr('chip_normal')
        : (soilStatus == MetricStatus.danger
            ? l10n.tr('chip_drought')
            : l10n.tr('chip_dry'));

    final isAllOptimal = tempStatus == MetricStatus.normal &&
        humidityStatus == MetricStatus.normal &&
        soilStatus == MetricStatus.normal;

    // 4. Light Level (Optimal: 5000 - 20000 Lux in daytime)
    final lightStatus = MetricStatus.normal;
    final lightStatusText = l10n.tr('chip_optimum');

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('app_name'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              l10n.tr('greenhouse_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // M8 Stress test quick simulation button for demo
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'toggle_offline') {
                provider.toggleOfflineStressTest(!provider.isOffline);
              } else if (value == 'trigger_overheat') {
                provider.triggerOverheatAlert();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'trigger_overheat',
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppTheme.statusDanger, size: 20),
                    const SizedBox(width: 10),
                    Text(l10n.tr('scenario2_overheat')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_offline',
                child: Row(
                  children: [
                    Icon(
                      provider.isOffline
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: provider.isOffline
                          ? AppTheme.primary
                          : AppTheme.statusWarning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(provider.isOffline
                        ? l10n.tr('restore_connection')
                        : l10n.tr('stress_test_action')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            // Trigger manual update
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STATUS & OFFLINE BANNER (M2 5-second assessment + M8 failure handling)
                StatusBanner(
                  isOffline: provider.isOffline,
                  isAllGood: isAllOptimal,
                  hasAlert: provider.hasActiveAlert,
                  alertMessage: tempStatus == MetricStatus.danger
                      ? '${l10n.tr('chip_overheat')} · ${telemetry.airTemp.toStringAsFixed(1)} °C'
                      : provider.alertMessage,
                  alertActionText: l10n.tr('open_controls'),
                  onOpenControls: onOpenControls,
                  statusText: isAllOptimal
                      ? l10n.tr('status_all_good')
                      : l10n.tr('status_warning'),
                  lastUpdateText:
                      '${l10n.tr('last_update')}: ${telemetry.getTimeAgo(provider.language)}',
                  offlineTitle: l10n.tr('offline_banner_title'),
                  offlineDesc: l10n.tr('offline_banner_desc'),
                  onDismissAlert: () => provider.dismissAlert(),
                ),

                // 4 CORE TELEMETRY METRIC CARDS (M2)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 550 ? 4 : 2;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 126 +
                          (MediaQuery.textScalerOf(context).scale(25) - 25)
                              .clamp(0.0, 150.0),
                      children: [
                        // Card 1: Air Temperature
                        MetricCard(
                          title: l10n.tr('param_air_temp'),
                          value: telemetry.airTemp.toStringAsFixed(1),
                          unit: '°C',
                          icon: Icons.thermostat_rounded,
                          status: tempStatus,
                          statusText: tempStatusText,
                          progress: (telemetry.airTemp - 10) / 30.0,
                        ),

                        // Card 2: Air Humidity
                        MetricCard(
                          title: l10n.tr('param_air_humidity'),
                          value: telemetry.airHumidity.toStringAsFixed(0),
                          unit: '%',
                          icon: Icons.water_drop_outlined,
                          status: humidityStatus,
                          statusText: humidityStatusText,
                          progress: telemetry.airHumidity / 100.0,
                        ),

                        // Card 3: Soil Moisture
                        MetricCard(
                          title: l10n.tr('param_soil_moisture'),
                          value: telemetry.soilMoisture.toStringAsFixed(1),
                          unit: '%',
                          icon: Icons.grass_rounded,
                          status: soilStatus,
                          statusText: soilStatusText,
                          progress: telemetry.soilMoisture / 100.0,
                        ),

                        // Card 4: Light Level
                        MetricCard(
                          title: l10n.tr('param_light_level'),
                          value:
                              (telemetry.lightLevel / 1000).toStringAsFixed(1),
                          unit: 'kLux',
                          icon: Icons.wb_sunny_rounded,
                          status: lightStatus,
                          statusText: lightStatusText,
                          progress: telemetry.lightLevel / 25000.0,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Quick Mode Status Indicator (M4)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.settings.autoMode
                                  ? l10n.tr('mode_auto')
                                  : l10n.tr('mode_manual'),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.autoRuleSummary(
                                settings.minSoilMoisture,
                                settings.maxAirTemp,
                              ),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.autoMode,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) => provider.toggleAutoMode(val),
                      ),
                    ],
                  ),
                ),
                if (!provider.isOffline && !provider.hasActiveAlert) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: provider.triggerOverheatAlert,
                    child: Text(l10n.tr('scenario2_overheat')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
