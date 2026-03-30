import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/sensor_model.dart';
import '../models/location_model.dart';
import '../models/alarm_model.dart';
import '../models/user_model.dart';

// Dio — это библиотека для HTTP запросов.
// Думайте о ней как о "почтальоне" который отправляет запросы
// на сервер и приносит ответы обратно.

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Перехватчик — добавляет токен к каждому запросу автоматически
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Если сервер вернул 401 — токен устарел, нужно войти снова
          if (error.response?.statusCode == 401) {
            _token = null;
          }
          return handler.next(error);
        },
      ),
    );
  }

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  // ── Авторизация ────────────────────────────────────────────────────

  // POST /auth/login
  // Бэкенд принимает form-data (не JSON!) — это важно
  Future<String> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      return response.data['access_token'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /users/me
  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/users/');
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Локации ────────────────────────────────────────────────────────

  // GET /locations/
  Future<List<Location>> getLocations() async {
    try {
      final response = await _dio.get('/locations/');
      return (response.data as List)
          .map((json) => Location.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /locations/{id} — локация с датчиками внутри
  Future<Location> getLocation(int id) async {
    try {
      final response = await _dio.get('/locations/$id');
      return Location.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST /locations/
  Future<Location> createLocation(String name, String? address) async {
    try {
      final response = await _dio.post('/locations/', data: {
        'name': name,
        'address': address,
      });
      return Location.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Датчики ────────────────────────────────────────────────────────

  // GET /sensors/
  Future<List<Sensor>> getSensors() async {
    try {
      final response = await _dio.get('/sensors/');
      return (response.data as List)
          .map((json) => Sensor.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT /sensors/{id} — обновление порогов тревог
  Future<Sensor> updateSensor(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/sensors/$id', data: data);
      return Sensor.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Тревоги ────────────────────────────────────────────────────────

  // GET /alarms/
  Future<List<Alarm>> getAlarms() async {
    try {
      final response = await _dio.get('/alarms/');
      return (response.data as List)
          .map((json) => Alarm.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /alarms/stats
  Future<Map<String, int>> getAlarmStats() async {
    try {
      final response = await _dio.get('/alarms/stats');
      return Map<String, int>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST /alarms/{id}/acknowledge
  Future<void> acknowledgeAlarm(int id) async {
    try {
      await _dio.post('/alarms/$id/acknowledge');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST /alarms/{id}/resolve
  Future<void> resolveAlarm(int id, String comment) async {
    try {
      await _dio.post('/alarms/$id/resolve', data: {'comment': comment});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Отчёты ─────────────────────────────────────────────────────────

  // GET /reports/pdf/{id}
  Future<List<int>> downloadPdf(
      int sensorId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _dio.get(
        '/reports/pdf/$sensorId',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Обработка ошибок ───────────────────────────────────────────────

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Нет подключения к серверу';
    }
    if (e.response?.statusCode == 401) {
      return 'Неверный логин или пароль';
    }
    if (e.response?.statusCode == 403) {
      return 'Недостаточно прав';
    }
    if (e.response?.statusCode == 404) {
      return 'Данные не найдены';
    }
    return 'Ошибка сервера: ${e.response?.statusCode ?? 'нет связи'}';
  }
}