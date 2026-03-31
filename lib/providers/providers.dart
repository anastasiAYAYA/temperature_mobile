import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/mock_service.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/alarm_model.dart';

// ── Переключатель режима ───────────────────────────────────────────────
// true  = локальные тестовые данные (MockService)
// false = реальный бэкенд (ApiService)
// Когда бэкенд будет готов — просто меняем на false
const bool useMock = true;

// ── Единственный экземпляр API сервиса ────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final mockServiceProvider = Provider<MockService>((ref) => MockService());

// ── Состояние авторизации ──────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading:  isLoading  ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user:       user       ?? this.user,
      error:      error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService  _api;
  final MockService _mock;

  AuthNotifier(this._api, this._mock) : super(const AuthState());

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (useMock) {
        // Локальные данные
        final token = await _mock.login(username, password);
        if (token == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Неверный логин или пароль',
          );
          return;
        }
        final user = await _mock.getMe(token);
        state = state.copyWith(
          isLoading: false, isLoggedIn: true, user: user,
        );
      } else {
        // Реальный бэкенд
        final token = await _api.login(username, password);
        _api.setToken(token);
        final user = await _api.getMe();
        state = state.copyWith(
          isLoading: false, isLoggedIn: true, user: user,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    _api.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    ref.read(mockServiceProvider),
  );
});

// ── Локации (главный экран) ────────────────────────────────────────────
final locationsProvider = FutureProvider<List<Location>>((ref) async {
  if (useMock) {
    return ref.read(mockServiceProvider).getLocations();
  }
  return ref.read(apiServiceProvider).getLocations();
});

// ── Тревоги ────────────────────────────────────────────────────────────
final alarmsProvider = FutureProvider<List<Alarm>>((ref) async {
  if (useMock) {
    return ref.read(mockServiceProvider).getAlarms();
  }
  return ref.read(apiServiceProvider).getAlarms();
});

// ── Статистика тревог (для шапки) ─────────────────────────────────────
final alarmStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  if (useMock) {
    return ref.read(mockServiceProvider).getAlarmStats();
  }
  return ref.read(apiServiceProvider).getAlarmStats();
});

// ── Пользователи ──────────────────────────────────────────────────────
final usersProvider = FutureProvider<List<User>>((ref) async {
  if (useMock) {
    return ref.read(mockServiceProvider).getUsers();
  }
  return ref.read(apiServiceProvider).getUsers() as Future<List<User>>;
});

// ── Параметры для запроса графика ─────────────────────────────────────
// Храним какой датчик выбран и за какой период
class ChartParams {
  final int sensorId;
  final int hours;
  const ChartParams({required this.sensorId, required this.hours});
}

final chartParamsProvider = StateProvider<ChartParams>((ref) {
  return const ChartParams(sensorId: 101, hours: 24);
});

final sensorHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final params = ref.watch(chartParamsProvider);
  if (useMock) {
    return ref
        .read(mockServiceProvider)
        .getSensorHistory(params.sensorId, params.hours);
  }
  // Здесь будет реальный API запрос
  return [];
});