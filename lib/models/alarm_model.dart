class Alarm {
  final int id;
  final int sensorId;
  final String sensorName;
  final String objectName;
  final String type;   // "temp_high", "temp_low", "offline" и т.д.
  final String level;  // "warning", "alarm"
  final double? value;
  final double? threshold;
  final DateTime triggeredAt;
  final String status; // "active", "acknowledged", "resolved"
  final String? comment;
  final String? resolvedBy;

  const Alarm({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.objectName,
    required this.type,
    required this.level,
    required this.triggeredAt,
    required this.status,
    this.value,
    this.threshold,
    this.comment,
    this.resolvedBy,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id:          json['id'],
      sensorId:    json['sensor_id'],
      sensorName:  json['sensor_name'] ?? 'Датчик #${json['sensor_id']}',
      objectName:  json['object_name'] ?? '',
      type:        json['type'] ?? '',
      level:       json['level'] ?? 'alarm',
      value:       (json['value'] as num?)?.toDouble(),
      threshold:   (json['threshold'] as num?)?.toDouble(),
      triggeredAt: DateTime.parse(json['triggered_at']),
      status:      json['status'] ?? 'active',
      comment:     json['comment'],
      resolvedBy:  json['resolved_by'],
    );
  }

  bool get isActive       => status == 'active';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isResolved     => status == 'resolved';

  // Читаемое название типа тревоги
  String get typeLabel {
    switch (type) {
      case 'temp_high':    return 'Превышение температуры';
      case 'temp_low':     return 'Снижение температуры';
      case 'hum_high':     return 'Превышение влажности';
      case 'hum_low':      return 'Снижение влажности';
      case 'offline':      return 'Потеря связи';
      case 'no_power':     return 'Отключение питания';
      default:             return type;
    }
  }
}