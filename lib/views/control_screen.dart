import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/greenhouse_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/actuator_card.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GreenhouseProvider>();
    final l10n = provider.l10n;
    final actuators = provider.actuators;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.tr('control_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // COMMAND LATENCY INDICATOR (Requirement: < 5s)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l10n.tr(provider.isOffline
                            ? 'offline_banner_title'
                            : 'equipment_online'),
                        style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        '${l10n.tr('latency_indicator')}: ${provider.commandLatencySeconds.toStringAsFixed(1)} s',
                        style: const TextStyle(
                            color: AppTheme.primaryDark, fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ACTUATOR 1: IRRIGATION (Капельный полив)
              ActuatorCard(
                title: l10n.tr('actuator_irrigation'),
                description: l10n.tr('actuator_irrigation_desc'),
                icon: Icons.water_rounded,
                isActive: actuators.irrigation,
                activeText: l10n.tr('state_active'),
                inactiveText: l10n.tr('state_inactive'),
                onToggle: (val) => provider.toggleActuator('irrigation', val),
              ),

              const SizedBox(height: 14),

              // ACTUATOR 2: VENTILATION (Фрамуги / Окна)
              ActuatorCard(
                title: l10n.tr('actuator_ventilation'),
                description: l10n.tr('actuator_ventilation_desc'),
                icon: Icons.air_rounded,
                isActive: actuators.ventilation,
                activeText: l10n.tr('state_active'),
                inactiveText: l10n.tr('state_inactive'),
                onToggle: (val) => provider.toggleActuator('ventilation', val),
              ),

              const SizedBox(height: 14),

              // ACTUATOR 3: HEATING (Отопление / Тепловентилятор)
              ActuatorCard(
                title: l10n.tr('actuator_heater'),
                description: l10n.tr('actuator_heater_desc'),
                icon: Icons.whatshot_rounded,
                isActive: actuators.heater,
                activeText: l10n.tr('state_active'),
                inactiveText: l10n.tr('state_inactive'),
                onToggle: (val) => provider.toggleActuator('heater', val),
              ),

              const SizedBox(height: 14),

              // ACTUATOR 4: LIGHTING (Фитоосвещение)
              ActuatorCard(
                title: l10n.tr('actuator_lighting'),
                description: l10n.tr('actuator_lighting_desc'),
                icon: Icons.lightbulb_rounded,
                isActive: actuators.lighting,
                activeText: l10n.tr('state_active'),
                inactiveText: l10n.tr('state_inactive'),
                onToggle: (val) => provider.toggleActuator('lighting', val),
              ),

              const SizedBox(height: 24),

              // EMERGENCY ALL-STOP BUTTON
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: const Color(0xFFFFEBEE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  provider.toggleActuator('irrigation', false);
                  provider.toggleActuator('ventilation', false);
                  provider.toggleActuator('heater', false);
                  provider.toggleActuator('lighting', false);
                },
                child: Text(
                  l10n.tr('btn_turn_all_off'),
                  style: const TextStyle(
                    color: AppTheme.statusDanger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
