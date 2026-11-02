class ActuatorModel {
  final String? id;
  final String? greenhouseId;
  final bool irrigation;
  final bool ventilation;
  final bool heater;
  final bool lighting;
  final DateTime updatedAt;
  final int lastLatencyMs;

  const ActuatorModel({
    this.id,
    this.greenhouseId,
    required this.irrigation,
    required this.ventilation,
    required this.heater,
    required this.lighting,
    required this.updatedAt,
    this.lastLatencyMs = 800,
  });

  bool get isAnyActive => irrigation || ventilation || heater || lighting;
  int get activeCount => (irrigation ? 1 : 0) + (ventilation ? 1 : 0) + (heater ? 1 : 0) + (lighting ? 1 : 0);

  ActuatorModel copyWith({
    String? id,
    String? greenhouseId,
    bool? irrigation,
    bool? ventilation,
    bool? heater,
    bool? lighting,
    DateTime? updatedAt,
    int? lastLatencyMs,
  }) {
    return ActuatorModel(
      id: id ?? this.id,
      greenhouseId: greenhouseId ?? this.greenhouseId,
      irrigation: irrigation ?? this.irrigation,
      ventilation: ventilation ?? this.ventilation,
      heater: heater ?? this.heater,
      lighting: lighting ?? this.lighting,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
    );
  }

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    return ActuatorModel(
      id: json['id']?.toString(),
      greenhouseId: json['greenhouse_id']?.toString(),
      irrigation: json['irrigation'] as bool? ?? false,
      ventilation: json['ventilation'] as bool? ?? false,
      heater: json['heater'] as bool? ?? false,
      lighting: json['lighting'] as bool? ?? false,
      updatedAt: json['updated_at'] != null 
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      lastLatencyMs: (json['last_latency_ms'] as num?)?.toInt() ?? 800,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (greenhouseId != null) 'greenhouse_id': greenhouseId,
      'irrigation': irrigation,
      'ventilation': ventilation,
      'heater': heater,
      'lighting': lighting,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ActuatorModel initial() {
    return ActuatorModel(
      irrigation: false,
      ventilation: false,
      heater: false,
      lighting: false,
      updatedAt: DateTime.now(),
      lastLatencyMs: 800,
    );
  }

  static ActuatorModel allOff({String? greenhouseId}) {
    return ActuatorModel(
      greenhouseId: greenhouseId,
      irrigation: false,
      ventilation: false,
      heater: false,
      lighting: false,
      updatedAt: DateTime.now(),
      lastLatencyMs: 650,
    );
  }
}
