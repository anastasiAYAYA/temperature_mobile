class AppConstants {
  // Адрес вашего локального бэкенда
  // Когда запускаете бэкенд локально — он будет на этом адресе
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String wsUrl = 'ws://localhost:8000/ws';

  // Ключ для хранения токена на устройстве
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}