import 'package:flutter/material.dart';
import '../models/actuator_model.dart';
import '../models/telemetry_model.dart';

class DigitalTwinEmbed extends StatelessWidget {
  final TelemetryModel telemetry;
  final ActuatorModel actuators;
  final bool isOffline;
  final String nativeHint;
  final String languageCode;

  const DigitalTwinEmbed({
    super.key,
    required this.telemetry,
    required this.actuators,
    required this.isOffline,
    required this.nativeHint,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    Color tintColor = Colors.transparent;
    if (telemetry.isOverheated()) {
      tintColor = Colors.red.withOpacity(0.22);
    } else if (actuators.lighting) {
      tintColor = const Color(0xFF9C27B0).withOpacity(0.20);
    } else if (actuators.heater) {
      tintColor = Colors.deepOrange.withOpacity(0.16);
    } else if (actuators.irrigation) {
      tintColor = Colors.lightBlue.withOpacity(0.14);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/models/greenhouse_preview.png',
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => Container(
              color: const Color(0xFF132A17),
              alignment: Alignment.center,
              child: const Icon(
                Icons.view_in_ar_rounded,
                size: 64,
                color: Color(0xFF81C784),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: tintColor,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (actuators.lighting)
                  _buildStatusChip(Icons.lightbulb_rounded, 'LED ON', const Color(0xFF8E24AA)),
                if (actuators.ventilation)
                  _buildStatusChip(Icons.air_rounded, 'Vents Open', const Color(0xFF00897B)),
                if (actuators.irrigation)
                  _buildStatusChip(Icons.water_drop_rounded, 'Drip ON', const Color(0xFF0288D1)),
                if (actuators.heater)
                  _buildStatusChip(Icons.local_fire_department_rounded, 'Heater ON', const Color(0xFFE65100)),
                if (telemetry.isOverheated())
                  _buildStatusChip(Icons.warning_amber_rounded, '${telemetry.airTemp.toStringAsFixed(1)}°C', const Color(0xFFC62828)),
                if (isOffline)
                  _buildStatusChip(Icons.cloud_off_rounded, 'Offline M8', const Color(0xFF455A64)),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xCC0D2812),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nativeHint,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
