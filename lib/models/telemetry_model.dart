import '../l10n/app_localizations.dart';

class TelemetryModel {
  final String? id;
  final String? greenhouseId;
  final double airTemp;        // °C
  final double airHumidity;    // %
  final double soilMoisture;   // %
  final double lightLevel;     // Lux
  final DateTime timestamp;

  const TelemetryModel({
    this.id,
    this.greenhouseId,
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

  double get lightLevelKLux => lightLevel / 1000.0;

  bool isOverheated([double threshold = 28.0]) => airTemp > threshold;
  bool isDrought([double threshold = 30.0]) => soilMoisture < threshold;

  TelemetryModel copyWith({
    String? id,
    String? greenhouseId,
    double? airTemp,
    double? airHumidity,
    double? soilMoisture,
    double? lightLevel,
    DateTime? timestamp,
  }) {
    return TelemetryModel(
      id: id ?? this.id,
      greenhouseId: greenhouseId ?? this.greenhouseId,
      airTemp: airTemp ?? this.airTemp,
      airHumidity: airHumidity ?? this.airHumidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      lightLevel: lightLevel ?? this.lightLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String getTimeAgo([AppLanguage language = AppLanguage.ru]) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 10) {
      switch (language) {
        case AppLanguage.kz: return 'жаңа ғана';
        case AppLanguage.en: return 'just now';
        case AppLanguage.ru: return 'только что';
      }
    }
    if (diff.inSeconds < 60) {
      switch (language) {
        case AppLanguage.kz: return '${diff.inSeconds} сек. бұрын';
        case AppLanguage.en: return '${diff.inSeconds}s ago';
        case AppLanguage.ru: return '${diff.inSeconds} сек. назад';
      }
    }
    if (diff.inMinutes < 60) {
      switch (language) {
        case AppLanguage.kz: return '${diff.inMinutes} мин. бұрын';
        case AppLanguage.en: return '${diff.inMinutes}m ago';
        case AppLanguage.ru: return '${diff.inMinutes} мин. назад';
      }
    }
    switch (language) {
      case AppLanguage.kz: return '${diff.inHours} сағ. бұрын';
      case AppLanguage.en: return '${diff.inHours}h ago';
      case AppLanguage.ru: return '${diff.inHours} ч. назад';
    }
  }

  String get timeAgo => getTimeAgo(AppLanguage.ru);

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] != null) {
      parsedTimestamp = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedTimestamp = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return TelemetryModel(
      id: json['id']?.toString(),
      greenhouseId: json['greenhouse_id']?.toString(),
      airTemp: (json['air_temp'] as num?)?.toDouble() ?? 24.0,
      airHumidity: (json['air_humidity'] as num?)?.toDouble() ?? 60.0,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 45.0,
      lightLevel: (json['light_level'] as num?)?.toDouble() ?? 10000.0,
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (greenhouseId != null) 'greenhouse_id': greenhouseId,
      'air_temp': airTemp,
      'air_humidity': airHumidity,
      'soil_moisture': soilMoisture,
      'light_level': lightLevel,
      'timestamp': timestamp.toIso8601String(),
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
