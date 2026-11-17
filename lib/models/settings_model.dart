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

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      autoMode: json['auto_mode'] as bool? ?? true,
      minSoilMoisture:
          (json['min_soil_moisture'] as num?)?.toDouble() ?? 30.0,
      maxAirTemp: (json['max_air_temp'] as num?)?.toDouble() ?? 28.0,
      minAirTemp: (json['min_air_temp'] as num?)?.toDouble() ?? 18.0,
      dayTariffKzt: (json['day_tariff_kzt'] as num?)?.toDouble() ?? 28.50,
      nightTariffKzt: (json['night_tariff_kzt'] as num?)?.toDouble() ?? 11.20,
      monthlySavedTenge:
          (json['monthly_saved_tenge'] as num?)?.toDouble() ?? 48200.0,
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
