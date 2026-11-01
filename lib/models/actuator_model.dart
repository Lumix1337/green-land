class ActuatorModel {
  final bool irrigation;
  final bool ventilation;
  final bool heater;
  final bool lighting;
  final DateTime updatedAt;

  const ActuatorModel({
    required this.irrigation,
    required this.ventilation,
    required this.heater,
    required this.lighting,
    required this.updatedAt,
  });

  ActuatorModel copyWith({
    bool? irrigation,
    bool? ventilation,
    bool? heater,
    bool? lighting,
    DateTime? updatedAt,
  }) {
    return ActuatorModel(
      irrigation: irrigation ?? this.irrigation,
      ventilation: ventilation ?? this.ventilation,
      heater: heater ?? this.heater,
      lighting: lighting ?? this.lighting,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    return ActuatorModel(
      irrigation: json['irrigation'] ?? false,
      ventilation: json['ventilation'] ?? false,
      heater: json['heater'] ?? false,
      lighting: json['lighting'] ?? false,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    );
  }
}
