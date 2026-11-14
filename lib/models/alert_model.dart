enum AlertSeverity {
  info,
  warning,
  danger,
}

enum AlertType {
  overheat,
  freeze,
  drought,
  criticalDrought,
  offline,
  sensorError,
  custom,
}

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isDismissed;
  final String? actionLabel;
  final String? actionKey;

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isDismissed = false,
    this.actionLabel,
    this.actionKey,
  });

  AlertModel copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isDismissed,
    String? actionLabel,
    String? actionKey,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isDismissed: isDismissed ?? this.isDismissed,
      actionLabel: actionLabel ?? this.actionLabel,
      actionKey: actionKey ?? this.actionKey,
    );
  }

  factory AlertModel.overheat({
    required double currentTemp,
    required double threshold,
    String? actionLabel = 'Включить вентиляцию',
  }) {
    return AlertModel(
      id: 'alert_overheat_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.overheat,
      severity: AlertSeverity.danger,
      title: 'Опасный перегрев!',
      message:
          'Температура поднялась до ${currentTemp.toStringAsFixed(1)}°C (норма до ${threshold.toStringAsFixed(1)}°C). Риск увядания томатов.',
      timestamp: DateTime.now(),
      actionLabel: actionLabel,
      actionKey: 'ventilation',
    );
  }

  factory AlertModel.drought({
    required double currentMoisture,
    required double threshold,
    String? actionLabel = 'Включить автополив',
  }) {
    final isCritical = currentMoisture < 20.0;
    return AlertModel(
      id: 'alert_drought_${DateTime.now().millisecondsSinceEpoch}',
      type: isCritical ? AlertType.criticalDrought : AlertType.drought,
      severity: isCritical ? AlertSeverity.danger : AlertSeverity.warning,
      title: isCritical ? 'Критическая засуха!' : 'Низкая влажность почвы',
      message:
          'Влажность почвы упала до ${currentMoisture.toStringAsFixed(1)}% (критично < ${threshold.toStringAsFixed(1)}%). Требуется полив.',
      timestamp: DateTime.now(),
      actionLabel: actionLabel,
      actionKey: 'irrigation',
    );
  }

  factory AlertModel.offline({
    String? message =
        'Потеряна связь с симулятором теплицы. Показаны кэшированные данные.',
  }) {
    return AlertModel(
      id: 'alert_offline_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.offline,
      severity: AlertSeverity.warning,
      title: 'Теплица офлайн',
      message: message!,
      timestamp: DateTime.now(),
      actionLabel: 'Повторить попытку',
      actionKey: 'reconnect',
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ??
          'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.custom,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      title: json['title'] as String? ?? 'Уведомление',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isDismissed: json['is_dismissed'] as bool? ?? false,
      actionLabel: json['action_label'] as String?,
      actionKey: json['action_key'] as String? ?? json['actionKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_dismissed': isDismissed,
      'action_label': actionLabel,
      'action_key': actionKey,
    };
  }
}
