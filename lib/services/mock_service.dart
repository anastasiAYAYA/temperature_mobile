import '../models/user_model.dart';
import '../models/sensor_model.dart';
import '../models/location_model.dart';
import '../models/alarm_model.dart';

// Этот файл полностью имитирует бэкенд.
// Когда сервер будет поднят — просто заменим на api_service.dart
// и всё приложение заработает с реальными данными без других изменений.

class MockService {

Future<String?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (username == 'superadmin' && password == 'super123') {
      return 'mock_token_superadmin';
    }
    if (username == 'admin' && password == 'admin') {
      return 'mock_token_admin';
    }
    if (username == 'employee' && password == '1234') {
      return 'mock_token_employee';
    }
    return null;
  }

  Future<User> getMe(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (token.contains('superadmin')) {
      return User(
        id: 1, username: 'superadmin',
        email: 'super@temperature.kz',
        role: 'superadmin',
        phone: '+7 777 000 0001',
        lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
        allowedLocationIds: [1, 2, 3, 4],
      );
    }
    if (token.contains('admin')) {
      return User(
        id: 2, username: 'admin',
        email: 'admin@temperature.kz',
        role: 'admin',
        phone: '+7 777 000 0002',
        lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
        allowedLocationIds: [1, 2, 3, 4],
      );
    }
    return User(
      id: 3, username: 'employee',
      email: 'employee@temperature.kz',
      role: 'employee',
      phone: '+7 777 000 0003',
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
      allowedLocationIds: [1, 2], // только склады
    );
  }

  Future<List<User>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      User(id: 1, username: 'superadmin',
          email: 'super@temperature.kz', role: 'superadmin',
          phone: '+7 777 000 0001',
          lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
          allowedLocationIds: [1, 2, 3, 4]),
      User(id: 2, username: 'admin',
          email: 'admin@temperature.kz', role: 'admin',
          phone: '+7 777 000 0002',
          lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
          allowedLocationIds: [1, 2, 3, 4]),
      User(id: 3, username: 'employee',
          email: 'employee@temperature.kz', role: 'employee',
          phone: '+7 777 000 0003',
          lastLogin: DateTime.now().subtract(const Duration(days: 1)),
          allowedLocationIds: [1, 2]),
      User(id: 4, username: 'ivanov',
          email: 'ivanov@temperature.kz', role: 'employee',
          phone: '+7 701 123 4567',
          lastLogin: DateTime.now().subtract(const Duration(days: 2)),
          allowedLocationIds: [3]),
    ];
  }
  // ── Локации с датчиками ───────────────────────────────────────────────

  Future<List<Location>> getLocations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Location(
        id: 1, name: 'Склад №1', address: 'ул. Абая 10',
        sensors: [
          Sensor(
            id: 101, name: 'Зона A — Морозильник',
            internalId: 'UNI_001_1', status: 'normal',
            temperature: -18.2, humidity: 65, batteryLevel: 85,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
            locationId: 1,
            tempAlarmHigh: -10, tempAlarmLow: -25,
            tempWarningHigh: -12, tempWarningLow: -23,
          ),
          Sensor(
            id: 102, name: 'Зона B — Морозильник',
            internalId: 'UNI_001_2', status: 'normal',
            temperature: -17.8, humidity: 68, batteryLevel: 72,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
            locationId: 1,
            tempAlarmHigh: -10, tempAlarmLow: -25,
            tempWarningHigh: -12, tempWarningLow: -23,
          ),
          Sensor(
            id: 103, name: 'Зона C — Охлаждаемый',
            internalId: 'UNI_001_3', status: 'warning',
            temperature: -14.1, humidity: 70, batteryLevel: 91,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 3)),
            locationId: 1,
            tempAlarmHigh: -10, tempAlarmLow: -25,
            tempWarningHigh: -15, tempWarningLow: -23,
          ),
        ],
      ),
      Location(
        id: 2, name: 'Склад №2', address: 'ул. Достык 5',
        sensors: [
          Sensor(
            id: 201, name: 'Холодильник 1',
            internalId: 'UNI_002_1', status: 'normal',
            temperature: 3.5, humidity: 80,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
            locationId: 2,
            tempAlarmHigh: 8, tempAlarmLow: 0,
            tempWarningHigh: 6, tempWarningLow: 1,
          ),
          Sensor(
            id: 202, name: 'Холодильник 2',
            internalId: 'UNI_002_2', status: 'alarm',
            temperature: 8.5, humidity: 75,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
            locationId: 2,
            tempAlarmHigh: 8, tempAlarmLow: 0,
            tempWarningHigh: 6, tempWarningLow: 1,
          ),
        ],
      ),
      Location(
        id: 3, name: 'Аптека Центральная', address: 'пр. Назарбаева 20',
        sensors: [
          Sensor(
            id: 301, name: 'Витрина',
            internalId: 'BT06_11412984', status: 'normal',
            temperature: 5.1, humidity: 55, batteryLevel: 60,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
            locationId: 3,
            tempAlarmHigh: 8, tempAlarmLow: 2,
          ),
          Sensor(
            id: 302, name: 'Склад медикаментов',
            internalId: 'BT06_11412985', status: 'normal',
            temperature: 18.3, humidity: 45, batteryLevel: 45,
            lastSeen: DateTime.now(),
            locationId: 3,
            tempAlarmHigh: 25, tempAlarmLow: 15,
          ),
        ],
      ),
      Location(
        id: 4, name: 'Ресторан Astana', address: 'ул. Сейфуллина 8',
        sensors: [
          Sensor(
            id: 401, name: 'Кухонный холодильник',
            internalId: 'UNI_004_1', status: 'offline',
            temperature: null, humidity: null, batteryLevel: 10,
            lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
            locationId: 4,
          ),
        ],
      ),
    ];
  }

  // ── Датчики ───────────────────────────────────────────────────────────

  Future<List<Sensor>> getSensors() async {
    final locations = await getLocations();
    return locations.expand((l) => l.sensors).toList();
  }

  // ── Тревоги ───────────────────────────────────────────────────────────

  Future<List<Alarm>> getAlarms() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      Alarm(
        id: 1, sensorId: 202,
        sensorName: 'Холодильник 2', objectName: 'Склад №2',
        type: 'temp_high', level: 'alarm',
        value: 8.5, threshold: 8.0,
        triggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'active',
      ),
      Alarm(
        id: 2, sensorId: 103,
        sensorName: 'Зона C', objectName: 'Склад №1',
        type: 'temp_high', level: 'warning',
        value: -14.1, threshold: -15.0,
        triggeredAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: 'active',
      ),
      Alarm(
        id: 3, sensorId: 401,
        sensorName: 'Кухонный холодильник', objectName: 'Ресторан Astana',
        type: 'offline', level: 'alarm',
        value: null, threshold: null,
        triggeredAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'acknowledged',
        comment: 'Выехал техник, проверяем питание',
      ),
    ];
  }

  Future<Map<String, int>> getAlarmStats() async {
    final alarms = await getAlarms();
    return {
      'active':       alarms.where((a) => a.isActive).length,
      'acknowledged': alarms.where((a) => a.isAcknowledged).length,
      'critical':     alarms.where((a) => a.level == 'alarm').length,
    };
  }

  Future<bool> acknowledgeAlarm(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> resolveAlarm(int id, String comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // ── История показаний для графиков ────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSensorHistory(
      int sensorId, int hours) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final random = <Map<String, dynamic>>[];

    // Базовые значения для разных датчиков
    final baseTemp = switch (sensorId) {
      101 || 102 => -18.0,
      103        => -14.0,
      201        => 3.5,
      202        => 8.0,
      301        => 5.0,
      302        => 18.0,
      _          => 20.0,
    };
    final baseHum = switch (sensorId) {
      101 || 102 || 103 => 65.0,
      201 || 202        => 78.0,
      _                 => 50.0,
    };

    // Генерируем точки каждые 10 минут
    final points = hours * 6;
    for (int i = points; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i * 10));
      // Небольшое случайное колебание
      final tempVariation = (i % 7 - 3) * 0.3;
      final humVariation  = (i % 5 - 2) * 0.5;
      random.add({
        'timestamp': time.toIso8601String(),
        'temperature': baseTemp + tempVariation,
        'humidity': baseHum + humVariation,
      });
    }
    return random;
  }
  Future<bool> createUser(String username, String email,
      String password, String role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> updateUserRole(int id, String role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}