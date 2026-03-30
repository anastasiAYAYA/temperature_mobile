class Sensor {
  final int id;
  final String name;
  final String internalId;
  final double? temperature;
  final double? humidity;
  final int? batteryLevel;
  final String status; // "normal", "warning", "alarm", "offline"
  final DateTime? lastSeen;
  final int? locationId;

  // Пороги тревог
  final double? tempAlarmHigh;
  final double? tempAlarmLow;
  final double? tempWarningHigh;
  final double? tempWarningLow;
  final double? humAlarmHigh;
  final double? humAlarmLow;

  const Sensor({
    required this.id,
    required this.name,
    required this.internalId,
    required this.status,
    this.temperature,
    this.humidity,
    this.batteryLevel,
    this.lastSeen,
    this.locationId,
    this.tempAlarmHigh,
    this.tempAlarmLow,
    this.tempWarningHigh,
    this.tempWarningLow,
    this.humAlarmHigh,
    this.humAlarmLow,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id:           json['id'],
      name:         json['name'],
      internalId:   json['internal_id'] ?? '',
      status:       json['status'] ?? 'offline',
      temperature:  (json['temperature'] as num?)?.toDouble(),
      humidity:     (json['humidity'] as num?)?.toDouble(),
      batteryLevel: json['battery_level'],
      lastSeen:     json['last_seen'] != null
                      ? DateTime.parse(json['last_seen'])
                      : null,
      locationId:   json['location_id'],
      tempAlarmHigh:   (json['temp_alarm_high'] as num?)?.toDouble(),
      tempAlarmLow:    (json['temp_alarm_low'] as num?)?.toDouble(),
      tempWarningHigh: (json['temp_warning_high'] as num?)?.toDouble(),
      tempWarningLow:  (json['temp_warning_low'] as num?)?.toDouble(),
      humAlarmHigh:    (json['hum_alarm_high'] as num?)?.toDouble(),
      humAlarmLow:     (json['hum_alarm_low'] as num?)?.toDouble(),
    );
  }

  // Цвет статуса для UI
  bool get isOnline  => status != 'offline';
  bool get isAlarm   => status == 'alarm';
  bool get isWarning => status == 'warning';
  bool get isNormal  => status == 'normal';
}