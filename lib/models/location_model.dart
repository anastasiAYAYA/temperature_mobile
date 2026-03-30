import 'sensor_model.dart';

class Location {
  final int id;
  final String name;
  final String? address;
  final List<Sensor> sensors;

  const Location({
    required this.id,
    required this.name,
    this.address,
    this.sensors = const [],
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id:      json['id'],
      name:    json['name'],
      address: json['address'],
      sensors: json['sensors'] != null
        ? (json['sensors'] as List)
            .map((s) => Sensor.fromJson(s))
            .toList()
        : [],
    );
  }

  // Считаем сколько датчиков в каждом статусе
  int get alarmCount   => sensors.where((s) => s.isAlarm).length;
  int get warningCount => sensors.where((s) => s.isWarning).length;
  int get offlineCount => sensors.where((s) => !s.isOnline).length;
  int get normalCount  => sensors.where((s) => s.isNormal).length;
}