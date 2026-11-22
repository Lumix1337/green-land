import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/digital_twin_embed.dart';

class Simulation3DScreen extends StatelessWidget {
  const Simulation3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;
    final telemetry = provider.telemetry;
    final actuators = provider.actuators;
    final savings = provider.energySavings;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.tr('sim3d_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${savings.monthlySavedTenge.toStringAsFixed(0)} ₸/mo',
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.tr('sim3d_subtitle'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Live 4-Sensor Telemetry Strip
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricTile(
                      label: '°C',
                      value: telemetry.airTemp.toStringAsFixed(1),
                      alert: telemetry.isOverheated(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniMetricTile(
                      label: '% Air',
                      value: telemetry.airHumidity.toStringAsFixed(0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniMetricTile(
                      label: '% Soil',
                      value: telemetry.soilMoisture.toStringAsFixed(0),
                      alert: telemetry.isDrought(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniMetricTile(
                      label: 'kLux',
                      value: telemetry.lightLevelKLux.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Interactive 3D Digital Twin Viewport (WebGL iframe on Web, live preview on mobile)
              SizedBox(
                height: 320,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: DigitalTwinEmbed(
                    telemetry: telemetry,
                    actuators: actuators,
                    isOffline: provider.isOffline,
                    nativeHint: l10n.tr('sim3d_native_hint'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick 3D Actuator Controls
              Text(
                l10n.tr('sim3d_quick_controls'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActuatorChip(
                    icon: Icons.water_drop_rounded,
                    label: l10n.tr('actuator_irrigation'),
                    active: actuators.irrigation,
                    onSelected: (val) =>
                        provider.toggleActuator('irrigation', val),
                  ),
                  _ActuatorChip(
                    icon: Icons.air_rounded,
                    label: l10n.tr('actuator_ventilation'),
                    active: actuators.ventilation,
                    onSelected: (val) =>
                        provider.toggleActuator('ventilation', val),
                  ),
                  _ActuatorChip(
                    icon: Icons.local_fire_department_rounded,
                    label: l10n.tr('actuator_heater'),
                    active: actuators.heater,
                    onSelected: (val) =>
                        provider.toggleActuator('heater', val),
                  ),
                  _ActuatorChip(
                    icon: Icons.lightbulb_rounded,
                    label: l10n.tr('actuator_lighting'),
                    active: actuators.lighting,
                    onSelected: (val) =>
                        provider.toggleActuator('lighting', val),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stress-Test Actions
              Text(
                l10n.tr('sim3d_stress_title'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.triggerOverheatAlert,
                      icon: const Icon(Icons.whatshot_rounded,
                          size: 18, color: AppTheme.statusDanger),
                      label: Text(
                        l10n.tr('sim3d_overheat_btn'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.dismissAlert();
                        provider.toggleActuator('ventilation', false);
                        provider.toggleActuator('heater', false);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        l10n.tr('sim3d_reset'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool alert;

  const _MiniMetricTile({
    required this.label,
    required this.value,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert
              ? AppTheme.statusDanger.withOpacity(0.5)
              : const Color(0xFFE0EAE1),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: alert ? AppTheme.statusDanger : AppTheme.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActuatorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final ValueChanged<bool> onSelected;

  const _ActuatorChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: active ? Colors.white : AppTheme.primaryDark,
      ),
      label: Text(label),
      selected: active,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: onSelected,
    );
  }
}
