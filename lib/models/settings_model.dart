class SettingsModel {
  final bool autoMode;
  final double minSoilMoisture;
  final double maxAirTemp;
  final double minAirTemp;
  final double dayTariffKzt;
  final double nightTariffKzt;
  final double monthlySavedTenge;

  const SettingsModel({
    required this.autoMode,
    required this.minSoilMoisture,
    required this.maxAirTemp,
    required this.minAirTemp,
    required this.dayTariffKzt,
    required this.nightTariffKzt,
    required this.monthlySavedTenge,
  });

  SettingsModel copyWith({
    bool? autoMode,
    double? minSoilMoisture,
    double? maxAirTemp,
    double? minAirTemp,
    double? dayTariffKzt,
    double? nightTariffKzt,
    double? monthlySavedTenge,
  }) {
    return SettingsModel(
      autoMode: autoMode ?? this.autoMode,
      minSoilMoisture: minSoilMoisture ?? this.minSoilMoisture,
      maxAirTemp: maxAirTemp ?? this.maxAirTemp,
      minAirTemp: minAirTemp ?? this.minAirTemp,
      dayTariffKzt: dayTariffKzt ?? this.dayTariffKzt,
      nightTariffKzt: nightTariffKzt ?? this.nightTariffKzt,
      monthlySavedTenge: monthlySavedTenge ?? this.monthlySavedTenge,
    );
  }

  static SettingsModel initial() {
    return const SettingsModel(
      autoMode: true,
      minSoilMoisture: 30.0,
      maxAirTemp: 28.0,
      minAirTemp: 18.0,
      dayTariffKzt: 28.50,
      nightTariffKzt: 11.20,
      monthlySavedTenge: 48200.0,
    );
  }
}
