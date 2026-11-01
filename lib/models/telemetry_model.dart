class TelemetryModel {
  final double airTemp;        // °C
  final double airHumidity;    // %
  final double soilMoisture;   // %
  final double lightLevel;     // Lux
  final DateTime timestamp;

  const TelemetryModel({
    required this.airTemp,
    required this.airHumidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.timestamp,
  });

  bool get isSoilMoistureLow => soilMoisture < 30.0;
  bool get isAirTempHigh => airTemp > 30.0;
  bool get isAirTempLow => airTemp < 16.0;
  bool get isOptimal => !isSoilMoistureLow && !isAirTempHigh && !isAirTempLow;

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 10) return 'только что';
    if (diff.inSeconds < 60) return '${diff.inSeconds} сек. назад';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    return '${diff.inHours} ч. назад';
  }

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      airTemp: (json['air_temp'] as num).toDouble(),
      airHumidity: (json['air_humidity'] as num).toDouble(),
      soilMoisture: (json['soil_moisture'] as num).toDouble(),
      lightLevel: (json['light_level'] as num).toDouble(),
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'air_temp': airTemp,
      'air_humidity': airHumidity,
      'soil_moisture': soilMoisture,
      'light_level': lightLevel,
      'created_at': timestamp.toIso8601String(),
    };
  }

  static TelemetryModel initial() {
    return TelemetryModel(
      airTemp: 24.2,
      airHumidity: 62.0,
      soilMoisture: 45.5,
      lightLevel: 12400.0,
      timestamp: DateTime.now(),
    );
  }
}
