class HistoricalTelemetryPoint {
  final DateTime timestamp;
  final double airTemp;
  final double soilMoisture;
  final double airHumidity;
  final double lightLevel;

  const HistoricalTelemetryPoint({
    required this.timestamp,
    required this.airTemp,
    required this.soilMoisture,
    required this.airHumidity,
    required this.lightLevel,
  });

  factory HistoricalTelemetryPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalTelemetryPoint(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at'] as String) 
              : DateTime.now()),
      airTemp: (json['air_temp'] as num?)?.toDouble() ?? 22.0,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 45.0,
      airHumidity: (json['air_humidity'] as num?)?.toDouble() ?? 60.0,
      lightLevel: (json['light_level'] as num?)?.toDouble() ?? 10000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'air_temp': airTemp,
      'soil_moisture': soilMoisture,
      'air_humidity': airHumidity,
      'light_level': lightLevel,
    };
  }

  /// Generate mock 7-day realistic data points (Scenario 4)
  static List<HistoricalTelemetryPoint> generate7DaysMock() {
    final now = DateTime.now();
    return [
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 6)),
        airTemp: 22.4,
        soilMoisture: 52.0,
        airHumidity: 65.0,
        lightLevel: 14000.0,
      ),
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 5)),
        airTemp: 25.1,
        soilMoisture: 48.0,
        airHumidity: 60.0,
        lightLevel: 16500.0,
      ),
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 4)),
        airTemp: 28.6,
        soilMoisture: 42.0,
        airHumidity: 55.0,
        lightLevel: 18000.0,
      ),
      // Scenario 4: Critical water deficit point on day 3 (soil moisture drops to 24.5%)
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 3)),
        airTemp: 32.2,
        soilMoisture: 24.5,
        airHumidity: 48.0,
        lightLevel: 21000.0,
      ),
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 2)),
        airTemp: 23.5,
        soilMoisture: 68.0,
        airHumidity: 70.0,
        lightLevel: 13000.0,
      ),
      HistoricalTelemetryPoint(
        timestamp: now.subtract(const Duration(days: 1)),
        airTemp: 24.0,
        soilMoisture: 54.0,
        airHumidity: 62.0,
        lightLevel: 15000.0,
      ),
      HistoricalTelemetryPoint(
        timestamp: now,
        airTemp: 24.2,
        soilMoisture: 45.0,
        airHumidity: 58.0,
        lightLevel: 14200.0,
      ),
    ];
  }

  /// Generate mock 24-hour realistic hourly data points
  static List<HistoricalTelemetryPoint> generate24HoursMock() {
    final now = DateTime.now();
    final points = <HistoricalTelemetryPoint>[];
    final hours = [0, 4, 8, 12, 16, 20, 24];
    final temps = [17.5, 16.8, 20.4, 26.8, 25.2, 21.0, 19.3];
    final soils = [46.0, 45.2, 44.1, 41.5, 58.0, 54.2, 51.0];
    final hums = [72.0, 75.0, 68.0, 52.0, 55.0, 62.0, 68.0];

    for (int i = 0; i < hours.length; i++) {
      points.add(HistoricalTelemetryPoint(
        timestamp: now.subtract(Duration(hours: 24 - hours[i])),
        airTemp: temps[i],
        soilMoisture: soils[i],
        airHumidity: hums[i],
        lightLevel: (hours[i] >= 8 && hours[i] <= 18) ? 16000.0 : 500.0,
      ));
    }
    return points;
  }
}
