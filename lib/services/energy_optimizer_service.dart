import '../models/actuator_model.dart';
import '../models/energy_savings_model.dart';
import '../models/settings_model.dart';

/// Signature Feature Service: Calculates financial savings in Kazakhstani Tenge (₸)
/// for Erlan's 800 m2 commercial tomato greenhouse based on differentiated day/night
/// electricity tariffs and weather-aware actuator scheduling.
class EnergyOptimizerService {
  static const double defaultAreaSqMeters = 800.0;
  static const double heaterPowerKw = 18.0;
  static const double lightingPowerKw = 14.0;
  static const double irrigationPowerKw = 2.2;
  static const double ventilationPowerKw = 1.5;

  /// Returns true if the given hour (0-23) is within the preferential night tariff window (23:00 - 07:00).
  bool isNightTariffHour(int hour) {
    final normalized = hour % 24;
    return normalized >= 23 || normalized < 7;
  }

  /// Computes instantaneous electrical load in kilowatts (kW) for currently active actuators.
  double computeInstantPowerKw(ActuatorModel actuators) {
    double power = 0.0;
    if (actuators.heater) power += heaterPowerKw;
    if (actuators.lighting) power += lightingPowerKw;
    if (actuators.irrigation) power += irrigationPowerKw;
    if (actuators.ventilation) power += ventilationPowerKw;
    return double.parse(power.toStringAsFixed(2));
  }

  /// Calculates full daily and monthly KZT energy savings breakdown.
  EnergySavingsModel calculateSavings({
    required SettingsModel settings,
    double areaSqMeters = defaultAreaSqMeters,
    bool sunnyWeatherForecast = true,
    int? currentHour,
  }) {
    final hour = currentHour ?? DateTime.now().hour;
    final isNight = isNightTariffHour(hour);
    final areaScale = areaSqMeters / defaultAreaSqMeters;

    // Baseline unoptimized daily consumption (156.0 kWh/day for 800 m2; 75% day / 25% night)
    final dailyBaselineKwh = 156.0 * areaScale;
    final dailyBaselineCost = dailyBaselineKwh *
        (0.75 * settings.dayTariffKzt + 0.25 * settings.nightTariffKzt);

    // Weather-aware cutoff + night tariff arbitrage (72% shifted to 11.20 ₸/kWh night rate)
    final savedKwhPerDay = (sunnyWeatherForecast ? 21.1 : 12.5) * areaScale;
    final dailyOptimizedKwh = (dailyBaselineKwh - savedKwhPerDay).clamp(40.0 * areaScale, dailyBaselineKwh);
    const nightShiftRatio = 0.72;
    const optDayShare = 1.0 - nightShiftRatio;

    final dailyOptimizedCost = dailyOptimizedKwh *
        (optDayShare * settings.dayTariffKzt + nightShiftRatio * settings.nightTariffKzt);

    final dailySavedTenge = (dailyBaselineCost - dailyOptimizedCost).clamp(0.0, double.infinity);
    final rawMonthlySaved = dailySavedTenge * 30.0;
    final monthlySavedTenge = (rawMonthlySaved / 100.0).round() * 100.0;
    final monthlySavedKwh = savedKwhPerDay * 30.0;
    final savingsPercentage = dailyBaselineCost > 0
        ? (dailySavedTenge / dailyBaselineCost) * 100.0
        : 0.0;

    return EnergySavingsModel(
      dailyBaselineKwh: double.parse(dailyBaselineKwh.toStringAsFixed(2)),
      dailyOptimizedKwh: double.parse(dailyOptimizedKwh.toStringAsFixed(2)),
      dailyBaselineCostTenge: double.parse(dailyBaselineCost.toStringAsFixed(2)),
      dailyOptimizedCostTenge: double.parse(dailyOptimizedCost.toStringAsFixed(2)),
      dailySavedTenge: double.parse(dailySavedTenge.toStringAsFixed(2)),
      monthlySavedTenge: monthlySavedTenge,
      monthlySavedKwh: double.parse(monthlySavedKwh.toStringAsFixed(1)),
      savingsPercentage: double.parse(savingsPercentage.toStringAsFixed(1)),
      nightShiftRatio: nightShiftRatio,
      isNightTariffActive: isNight,
    );
  }
}
